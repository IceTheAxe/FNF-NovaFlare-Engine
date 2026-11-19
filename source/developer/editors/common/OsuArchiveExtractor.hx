package developer.editors.common;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Input;
import haxe.zip.Entry;
import haxe.zip.Reader;
import lime._internal.format.Deflate;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;

typedef ExtractResult = {
	var osuContent:String;
	var audioPath:Null<String>;
	var tempDir:String;
}

/**
 * OSZ 压缩包提取器。
 *
 * 解压内核为流式（移植自 FE Mobile BootDataState 的数据包导入内核）：
 *  - 单条目内存恒为 64KB 缓冲，不再整包 File.getBytes + Reader.read() 全量驻留内存
 *    （旧实现的内存峰值 = 整个 zip + 所有解压数据，osz 带音频/视频很容易撞上限）；
 *  - DEFLATE 中小条目整条读入走 lime 原生 inflate（CFFI zlib，快 1-2 个数量级），
 *    超限条目退回纯 Haxe InflateImpl 流式解压（内存仍恒定）；
 *  - 支持数据描述符条目（流式写出的 zip：crc/csize/usize 存在数据之后、长度未知）——
 *    旧实现遇到这类 zip 必挂；
 *  - 只落盘需要的条目（首个 .osu + 首个音频），视频等大文件直接在流上原样跳过、不解压不落盘。
 */
class OsuArchiveExtractor
{
	/** DEFLATE 条目整条读入走原生 inflate 的 compressed 尺寸上限；超限/描述符条目退回流式 InflateImpl。 */
	static inline final NATIVE_INFLATE_MAX:Int = 33554432; // 32MB
	/** 全流程复用的分块缓冲。 */
	static inline final TMP_BUF_SIZE:Int = 65536;

	/**
	 * 从 OSZ 压缩包提取首个 .osu 谱面内容与首个音频文件（解压到临时目录）。
	 */
	public static function extract(oszPath:String):Null<ExtractResult>
	{
		if (!FileSystem.exists(oszPath))
		{
			trace('[OsuArchiveExtractor] 文件不存在: $oszPath');
			return null;
		}

		if (!oszPath.toLowerCase().endsWith('.osz'))
		{
			trace('[OsuArchiveExtractor] 不是 OSZ 压缩包: $oszPath');
			return null;
		}

		var input:FileInput = null;
		var entries:Int = 0;
		var bytesOut:Int = 0;
		var t0:Float = Sys.time();

		try
		{
			// 创建临时目录
			var tempDir = createTempDir();
			trace('[OsuArchiveExtractor] 临时目录: $tempDir');

			input = File.read(oszPath, true);
			var reader = new Reader(input);
			@:privateAccess var zipStream:Input = reader.i;
			var tmpBuf:Bytes = Bytes.alloc(TMP_BUF_SIZE);

			var osuContent:String = null;
			var audioPath:Null<String> = null;

			while (true)
			{
				var entry:Entry = reader.readEntryHeader();
				if (entry == null)
					break;
				entries++;

				var fileName:String = extractFileName(entry.fileName);
				// 防御目录条目与路径跳转（flatten 后只剩文件名，仍可能剩下 . / ..）
				if (fileName.length == 0 || fileName == '.' || fileName == '..')
				{
					skipEntryData(entry, zipStream, tmpBuf);
					continue;
				}

				var lower:String = fileName.toLowerCase();
				if (osuContent == null && lower.endsWith('.osu'))
				{
					// .osu 是小文本，直接驻留内存
					var capture:BytesBuffer = new BytesBuffer();
					bytesOut += consumeEntryData(entry, zipStream, tmpBuf, null, capture);
					osuContent = capture.getBytes().toString();
					trace('[OsuArchiveExtractor] 找到谱面: $fileName');
				}
				else if (audioPath == null && isAudioFile(lower))
				{
					var dst:String = '$tempDir/$fileName';
					var out:FileOutput = File.write(dst, true);
					try
						bytesOut += consumeEntryData(entry, zipStream, tmpBuf, out, null)
					catch (e:Dynamic)
					{
						// 异常路径也要关句柄，防 fd 泄漏
						try
							out.close()
						catch (e2:Dynamic) {}
						throw e;
					}
					out.close();
					audioPath = dst;
					trace('[OsuArchiveExtractor] 找到音频: $fileName');
				}
				else
				{
					// 不需要的条目（视频/其它难度/皮肤等）：直接在流上跳过
					skipEntryData(entry, zipStream, tmpBuf);
				}
			}

			input.close();
			input = null;

			trace('[OsuArchiveExtractor] 完成: $entries 条目, 解压落盘 $bytesOut 字节, 用时 ${Math.round((Sys.time() - t0) * 1000)}ms');

			if (osuContent == null)
			{
				trace('[OsuArchiveExtractor] 错误: 未找到 .osu 谱面文件');
				cleanup(tempDir);
				return null;
			}

			return {
				osuContent: osuContent,
				audioPath: audioPath,
				tempDir: tempDir
			};
		}
		catch (e:Dynamic)
		{
			trace('[OsuArchiveExtractor] 解压失败: $e');
			if (input != null)
				try
					input.close()
				catch (e2:Dynamic) {}
			return null;
		}
	}

	/**
	 * 消费一个条目的数据：写出到 out（可选）与 capture（可选），都不给则调用方应走 skipEntryData。
	 * 全程分块流式：单条目内存恒为缓冲大小；DEFLATE 用原生 inflate 边解压边消费（不整条目驻留）。
	 * @return 实际消费（解压后）的字节数
	 */
	static function consumeEntryData(entry:Entry, zipStream:Input, tmpBuf:Bytes, ?out:FileOutput, ?capture:BytesBuffer):Int
	{
		var total:Int = 0;
		if (entry.crc32 == null)
		{
			// 数据描述符条目（流式写出的 zip）：长度未知，边解压边消费，读完跳过描述符
			if (!entry.compressed)
				throw 'Unsupported zip entry (data descriptor + stored)';
			var z = new haxe.zip.InflateImpl(zipStream, false, false);
			while (true)
			{
				var n = z.readBytes(tmpBuf, 0, tmpBuf.length);
				emit(tmpBuf, n, out, capture);
				total += n;
				if (n < tmpBuf.length)
					break;
			}
			// 描述符：crc + csize + usize（可能带 0x08074b50 标记）
			var crc = zipStream.readInt32();
			if (crc == 0x08074b50)
				zipStream.readInt32();
			zipStream.readInt32();
			zipStream.readInt32();
		}
		else if (!entry.compressed)
		{
			// STORED：分块直读
			var left:Int = entry.dataSize;
			while (left > 0)
			{
				var n:Int = zipStream.readBytes(tmpBuf, 0, left < tmpBuf.length ? left : tmpBuf.length);
				emit(tmpBuf, n, out, capture);
				total += n;
				left -= n;
			}
		}
		else
		{
			// DEFLATE。非描述符条目的 crc/csize/usize 都在 local header 里，deflate 数据后
			// 直接是下一个条目——绝不能多读，否则 header 错位全包报废。
			// 纯 Haxe InflateImpl 实测 ~2.6MB/s（FE Mobile iOS 导入日志：468MB 用 179s，97.7% 时间在解压）——
			// 中小条目整条读入走 lime 原生 raw inflate（CFFI zlib，快 1-2 个数量级）；
			// 超限条目退回流式 InflateImpl（内存恒定，防单条目内存峰值）。
			if (entry.dataSize > 0 && entry.dataSize <= NATIVE_INFLATE_MAX)
			{
				var raw:Bytes = zipStream.read(entry.dataSize);
				var data:Bytes = Deflate.decompress(raw);
				if (data == null)
					throw 'native inflate returned null';
				if (entry.fileSize > 0 && data.length != entry.fileSize)
					trace('[OsuArchiveExtractor] 解压长度异常: ${entry.fileName} 期待 ${entry.fileSize} 实得 ${data.length}');
				emit(data, data.length, out, capture);
				total += data.length;
			}
			else
			{
				var z = new haxe.zip.InflateImpl(zipStream, false, false);
				while (true)
				{
					var n = z.readBytes(tmpBuf, 0, tmpBuf.length);
					emit(tmpBuf, n, out, capture);
					total += n;
					if (n < tmpBuf.length)
						break;
				}
			}
		}
		return total;
	}

	/** 跳过一个条目的数据（仅推进流，不解压不落盘）。 */
	static function skipEntryData(entry:Entry, zipStream:Input, tmpBuf:Bytes):Void
	{
		if (entry.crc32 == null)
		{
			// 描述符条目 csize 未知，只能解压着消费完再跳描述符
			if (!entry.compressed)
				throw 'Unsupported zip entry (data descriptor + stored)';
			var z = new haxe.zip.InflateImpl(zipStream, false, false);
			while (true)
			{
				var n = z.readBytes(tmpBuf, 0, tmpBuf.length);
				if (n < tmpBuf.length)
					break;
			}
			var crc = zipStream.readInt32();
			if (crc == 0x08074b50)
				zipStream.readInt32();
			zipStream.readInt32();
			zipStream.readInt32();
		}
		else
		{
			// 非 descriptor 条目的 dataSize 就是压缩后长度：原样读掉即可，无需解压
			var left:Int = entry.dataSize;
			while (left > 0)
			{
				var n:Int = zipStream.readBytes(tmpBuf, 0, left < tmpBuf.length ? left : tmpBuf.length);
				left -= n;
			}
		}
	}

	static inline function emit(buf:Bytes, n:Int, out:FileOutput, capture:BytesBuffer):Void
	{
		if (out != null)
			out.writeBytes(buf, 0, n);
		if (capture != null)
			capture.addBytes(buf, 0, n);
	}

	/**
	 * 保存音频到歌曲目录
	 * @param sourcePath 音频文件路径
	 * @param songName 歌曲名称
	 */
	public static function saveAudioToSong(sourcePath:String, songName:String, ?chartCategory:String, ?chartSongDir:String):Null<String>
	{
		if (sourcePath == null || !FileSystem.exists(sourcePath))
		{
			trace('[OsuArchiveExtractor] 音频文件不存在');
			return null;
		}

		try
		{
			// NF 没有 FE 的 content 谱面根体系，音频统一落到标准歌曲目录
			var songPath = Paths.formatToSongPath(songName);
			var targetDir = 'songs/$songPath/';

			// 创建目录
			if (!FileSystem.exists(targetDir))
				FileSystem.createDirectory(targetDir);

			// 获取文件扩展名并复制
			var ext = sourcePath.substr(sourcePath.lastIndexOf('.'));
			var targetPath = targetDir + 'inst' + ext;

			File.copy(sourcePath, targetPath);
			trace('[OsuArchiveExtractor] 音频已保存: $targetPath');
			return targetPath;
		}
		catch (e:Dynamic)
		{
			trace('[OsuArchiveExtractor] 保存音频失败: $e');
			return null;
		}
	}

	/**
	 * 清理临时目录
	 */
	public static function cleanup(tempDir:String):Void
	{
		try
		{
			if (FileSystem.exists(tempDir))
			{
				deleteDirectoryRecursive(tempDir);
				trace('[OsuArchiveExtractor] 已清理临时目录');
			}
		}
		catch (e:Dynamic)
		{
			trace('[OsuArchiveExtractor] 清理临时目录失败: $e');
		}
	}

	// ========== 内部辅助函数 ==========

	private static function createTempDir():String
	{
		var timestamp = Date.now().getTime();
		var tempRoot = Sys.getEnv("TEMP") ?? Sys.getEnv("TMP") ?? "/tmp";
		var tempDir = '$tempRoot/osu_extract_$timestamp';
		FileSystem.createDirectory(tempDir);
		return tempDir;
	}

	private static function extractFileName(path:String):String
	{
		// 处理 Windows 和 Unix 路径分隔符
		var parts = path.split('/');
		if (parts.length > 1) return parts[parts.length - 1];
		parts = path.split('\\');
		return (parts.length > 1) ? parts[parts.length - 1] : path;
	}

	private static function isAudioFile(fileName:String):Bool
	{
		var lower = fileName.toLowerCase();
		return lower.endsWith('.mp3') ||
		       lower.endsWith('.ogg') ||
		       lower.endsWith('.wav') ||
		       lower.endsWith('.flac');
	}

	private static function deleteDirectoryRecursive(path:String):Void
	{
		if (!FileSystem.exists(path)) return;

		for (entry in FileSystem.readDirectory(path))
		{
			var fullPath = '$path/$entry';
			if (FileSystem.isDirectory(fullPath))
				deleteDirectoryRecursive(fullPath);
			else
				FileSystem.deleteFile(fullPath);
		}
		FileSystem.deleteDirectory(path);
	}
}
