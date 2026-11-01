package general.backend.relax;
#if RELAX_ALLOWED

import haxe.Json;
import haxe.io.Path;

import sys.FileSystem;
import sys.io.File;

import openfl.display.BitmapData;
import openfl.media.Sound;

import flixel.graphics.FlxGraphic;

import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxAssets.FlxGraphicAsset;

import games.backend.WeekData;

typedef SongInfo = {
	name: String, 							// 歌曲名称
	sound: Array<FlxSoundAsset>, 			// 音频资源
	background: Array<FlxGraphicAsset>, 	// 背景图像
	record: Array<FlxGraphicAsset>, 		// 唱片图像
    lyrics: String,                         // 歌词
	bpm: Float, 							// 每分钟节拍数
	writer: String, 						// 作曲家
	?font: String 							// 歌词字体覆盖（可选，缺省沿用当前字体）
};

typedef SongLists = {
	name: String,
	list: Array<SongInfo>
};

typedef SongLyrics = {
    font: String,
    lyrics: Array<Dynamic>
};

/**
 * 播放器（Relax）的歌单数据源。
 *
 * 歌单放在 PlayList/ 目录下（相对 CWD：桌面 = 引擎根目录，安卓 = 启动时 Sys.setCwd
 * 进去的可写存储目录，即 .<应用名>/PlayList/，与 mods/ 同一套机制）：
 *
 *   PlayList/
 *     我的歌单/
 *       Artist - Song.mp3      ← 直接扔音频文件即可，扫描到后自动回写进 List.json
 *       Artist - Song.png      ← 与音频同名 = 封面（可选，也可放 covers/ 里）
 *       Artist - Song.lrc      ← 与音频同名 = 歌词（可选，标准 LRC；也可放 lyrics/ 里）
 *       List.json              ← 条目清单（可选，扫描会自动维护；手改可精修下面所有字段）
 *
 * List.json 里的条目是唯一事实来源：扫描负责把"新音频"追加进来、把"文件已失连"的
 * 条目清掉，其余内容一律不动。条目字段（除 sound 外全部可选）：
 *   name      显示歌名（缺省取文件名，"Artist - Title" 形式会自动拆出曲师）
 *   sound     音频相对本歌单目录的路径（数组，[0] 为主音轨，可带 Voices 等分轨）
 *   background 封面/背景图（数组；可省扩展名，自动补 .png/.jpg）
 *   record    唱片图（数组，规则同上）
 *   lyrics    歌词文件 .lrc（标准 LRC）或 .json（旧版自造格式）
 *   bpm / writer / font
 */
class GetInit
{
	// 歌单根目录（相对 CWD；与 mods/ 同一套查找机制）
	public static inline final PLAYLIST_ROOT:String = 'PlayList/';

	static var AUDIO_EXTS:Array<String> = ['ogg', 'mp3', 'wav'];
	static var IMAGE_EXTS:Array<String> = ['png', 'jpg', 'jpeg'];
	static var LYRIC_EXTS:Array<String> = ['lrc', 'json'];

	// 一次扫描的缓存：getListNum() 总是重扫（菜单闸门/打开播放器前保证新鲜），
	// 其余读取走缓存，避免 UI 一轮构建里反复扫盘
	static var listFolders:Array<String> = [];
	static var listNames:Array<String> = [];
	static var listEntries:Array<Array<Dynamic>> = []; // 原始 JSON 条目（回写与重建 SongInfo 共用）
	static var scanned:Bool = false;

	// Freeplay 曲目虚拟歌单（排在实体歌单后面，索引 = listFolders.length）
	// 调 refreshFreeplayList() 重建；mods 变动或换周后需要刷新
	static var freeplayList:SongLists = null;

	static public function refreshFreeplayList():Void
	{
		freeplayList = buildFreeplayList();
	}

	static function buildFreeplayList():SongLists
	{
		var out:Array<SongInfo> = [];
		// 主菜单直接打开时 weeks 可能还没加载，这里统一重载一次
		WeekData.reloadWeekFiles(false);
		for (weekName in WeekData.weeksList)
		{
			var leWeek:WeekData = WeekData.weeksLoaded.get(weekName);
			if (leWeek == null || leWeek.songs == null) continue;
			if (leWeek.hideFreeplay) continue;

			WeekData.setDirectoryFromWeek(leWeek); // 让 inst 存在性检查按该 week 的 mod 目录走

			for (song in leWeek.songs)
			{
				if (song == null || song[0] == null) continue;
				var songName:String = song[0];
				var lower:String = Paths.formatToSongPath(songName);
				var instPath:String = 'music/$lower/Inst.${Paths.SOUND_EXT}';
				if (!relaxSoundExists(instPath)) continue;

				var writer:String = '';
				if (song.length > 3 && song[3] != null) writer = song[3];

				out.push({
					name: songName,
					sound: [instPath],
					background: null,
					record: null,
					lyrics: null,
					bpm: 0,
					writer: writer
				});
			}
		}
		Mods.loadTopMod();
		return {name: Language.get('freeplayPlaylist', 'relax'), list: out};
	}

	// 与 Paths.modFolders 的查找顺序一致（当前 mod → 全局 mod → mod 根目录 → assets/shared）
	static function relaxSoundExists(path:String):Bool
	{
		if (FileSystem.exists('assets/shared/' + path)) return true;
		#if MODS_ALLOWED
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0
			&& FileSystem.exists('mods/' + Mods.currentModDirectory + '/' + path)) return true;
		for (mod in Mods.getGlobalMods())
			if (FileSystem.exists('mods/' + mod + '/' + path)) return true;
		if (FileSystem.exists('mods/' + path)) return true;
		#end
		return false;
	}

	static function freeplayCount():Int
	{
		return (freeplayList != null && freeplayList.list != null && freeplayList.list.length > 0) ? 1 : 0;
	}

	// =========================================================
	// 歌单扫描（PlayList/ 根目录 → 各歌单文件夹 → List.json 同步）
	// =========================================================

	static public function getListNum():Int
	{
		scanAll();
		return listFolders.length + freeplayCount();
	}

	static public function getList(ListNum:Int):SongLists
	{
		ensureScan();
		var total:Int = listFolders.length + freeplayCount();
		if (total <= 0)
			return {name: 'No Found!', list: []};

		if (ListNum < 0) ListNum = total - 1;
		if (ListNum > total - 1) ListNum = 0;
		// Freeplay 虚拟歌单固定排在最后
		if (ListNum >= listFolders.length && freeplayCount() > 0)
			return freeplayList;

		return buildSongLists(ListNum);
	}

	static public function getAllListName():Map<Int, String> {
		ensureScan();
		var allName = new Map<Int, String>();
		var listCount:Int = listFolders.length + freeplayCount();

		for (i in 0...listCount)
			allName.set(i, nameOf(i));

		return allName;
	}

	static public function getAllSongs():SongLists{
		ensureScan();
		var AllListSong:Array<SongInfo> = [];
		var listCount:Int = listFolders.length + freeplayCount();
		for (i in 0...listCount){
			var allList = getList(i).list;
			for (ii in allList){
				AllListSong.push(ii);
			}
		}
		return {
			name: 'All Songs',
			list: AllListSong
		};
	}

	static function nameOf(i:Int):String
	{
		if (i < listFolders.length) return listNames[i];
		if (freeplayList != null && freeplayList.name != null) return freeplayList.name;
		return 'Playlist $i';
	}

	static function buildSongLists(i:Int):SongLists
	{
		var out:Array<SongInfo> = [];
		for (e in listEntries[i])
		{
			var info:SongInfo = entryToSongInfo(listFolders[i], e);
			if (info != null) out.push(info);
		}
		return {name: listNames[i], list: out};
	}

	// 重扫 PlayList/ 根目录；每轮扫描会把差异同步回各歌单的 List.json
	static function scanAll():Void
	{
		listFolders = [];
		listNames = [];
		listEntries = [];
		scanned = true;

		if (!FileSystem.exists(PLAYLIST_ROOT))
		{
			try FileSystem.createDirectory(PLAYLIST_ROOT) catch (e:Dynamic) {}
			return;
		}

		var folders:Array<String> = [];
		try
		{
			for (item in FileSystem.readDirectory(PLAYLIST_ROOT))
				if (FileSystem.isDirectory(PLAYLIST_ROOT + item) && !StringTools.startsWith(item, '.'))
					folders.push(item);
		}
		catch (e:Dynamic) return;

		// 目录序跨平台不稳定，按名字排序保证歌单顺序一致
		folders.sort(function(a, b)
		{
			var la = a.toLowerCase();
			var lb = b.toLowerCase();
			return la < lb ? -1 : (la > lb ? 1 : 0);
		});

		for (folder in folders)
		{
			var playlist = scanPlaylist(folder);
			if (playlist == null) continue;
			listFolders.push(folder);
			listNames.push(playlist.name);
			listEntries.push(playlist.entries);
		}
	}

	static function ensureScan():Void
	{
		if (!scanned) scanAll();
	}

	static function scanPlaylist(folder:String):{name:String, entries:Array<Dynamic>}
	{
		var dir:String = PLAYLIST_ROOT + folder + '/';
		var jsonFile:String = dir + 'List.json';
		if (!FileSystem.exists(jsonFile) && FileSystem.exists(dir + 'list.json'))
			jsonFile = dir + 'list.json';

		var name:String = folder;
		var entries:Array<Dynamic> = [];
		var hasJson:Bool = FileSystem.exists(jsonFile);

		if (hasJson)
		{
			try
			{
				var data:Dynamic = Json.parse(File.getContent(jsonFile));
				if (data != null && data.name != null && Std.isOfType(data.name, String) && data.name.length > 0)
					name = data.name;
				if (data != null && data.list != null && Std.isOfType(data.list, Array))
				{
					var rawList:Array<Dynamic> = data.list;
					for (e in rawList)
					{
						// 只收至少带一个有效音频路径的条目，坏条目原样忽略
						if (e == null || e.sound == null || !Std.isOfType(e.sound, Array)) continue;
						var sounds:Array<Dynamic> = e.sound;
						if (sounds.length == 0 || sounds[0] == null || !Std.isOfType(sounds[0], String)) continue;
						entries.push(e);
					}
				}
			}
			catch (e:Dynamic)
				trace('[PlayList] $folder 歌单解析失败（$jsonFile）：$e');
		}

		// 扫描本地音频：歌单根目录 + songs/ 子目录
		var audioFiles:Array<String> = [];
		scanAudioDir(dir, '', audioFiles);
		scanAudioDir(dir + 'songs/', 'songs/', audioFiles);
		if (!hasJson && audioFiles.length == 0 && entries.length == 0)
			return null; // 空文件夹不算歌单

		// 条目音频失连 → 清掉；新音频 → 生成默认条目追加。任一变化都触发回写
		var used:Map<String, Bool> = new Map<String, Bool>();
		var kept:Array<Dynamic> = [];
		var changed:Bool = false;
		for (e in entries)
		{
			var sounds:Array<Dynamic> = e.sound;
			var rel:String = resolveEntryFile(dir, sounds[0]);
			if (rel == null)
			{
				changed = true;
				trace('[PlayList] $folder：条目音频不存在，已从 List.json 移除 -> ${sounds[0]}');
				continue;
			}
			used.set(rel, true);
			kept.push(e);
		}
		entries = kept;

		for (rel in audioFiles)
		{
			if (used.exists(rel)) continue;
			entries.push(makeAutoEntry(dir, rel));
			changed = true;
			trace('[PlayList] $folder：发现新歌曲 $rel，已写入 List.json');
		}

		if (changed)
			savePlaylist(jsonFile, name, entries);

		return {name: name, entries: entries};
	}

	static function scanAudioDir(dirPath:String, prefix:String, out:Array<String>):Void
	{
		if (!FileSystem.exists(dirPath) || !FileSystem.isDirectory(dirPath)) return;
		var files:Array<String>;
		try files = FileSystem.readDirectory(dirPath) catch (e:Dynamic) return;
		for (f in files)
		{
			if (StringTools.startsWith(f, '.')) continue;
			if (FileSystem.isDirectory(dirPath + f)) continue;
			if (AUDIO_EXTS.indexOf(Path.extension(f).toLowerCase()) == -1) continue;
			out.push(prefix + f);
		}
	}

	// 把条目里的音频相对路径解析成歌单内实际存在的文件（裸文件名会尝试 songs/ 子目录）
	static function resolveEntryFile(dir:String, raw:String):String
	{
		if (raw == null || raw.length == 0) return null;
		raw = StringTools.trim(raw);
		var candidates:Array<String> = [raw];
		if (raw.indexOf('/') == -1 && raw.indexOf('\\') == -1)
			candidates.push('songs/' + raw);

		for (cand in candidates)
			if (FileSystem.exists(dir + cand) && !FileSystem.isDirectory(dir + cand))
				return StringTools.replace(cand, '\\', '/');
		return null;
	}

	// 在歌单根目录（及可选子目录）里找与音频同名的资源文件
	static function findSameName(dir:String, stem:String, exts:Array<String>, ?subDirs:Array<String>):String
	{
		if (subDirs == null) subDirs = [''];
		for (sub in subDirs)
		{
			for (ext in exts)
			{
				var rel:String = sub + stem + '.' + ext;
				if (FileSystem.exists(dir + rel)) return rel;
			}
		}
		return null;
	}

	// 扫描新音频 → 生成默认条目（回写后用户可直接在 List.json 里精修）
	static function makeAutoEntry(dir:String, relPath:String):Dynamic
	{
		var stem:String = Path.withoutExtension(Path.withoutDirectory(relPath));
		var name:String = stem;
		var writer:String = '';
		// "Artist - Title.mp3" 自动拆出曲师
		var sep:Int = stem.indexOf(' - ');
		if (sep > 0)
		{
			writer = stem.substr(0, sep);
			name = stem.substr(sep + 3);
		}

		var cover:String = findSameName(dir, stem, IMAGE_EXTS, ['', 'covers/']);
		var lyrics:String = findSameName(dir, stem, LYRIC_EXTS, ['', 'lyrics/']);

		return {
			name: name,
			sound: [relPath],
			background: (cover != null) ? [cover] : null,
			lyrics: lyrics,
			record: null,
			bpm: 0,
			writer: writer
		};
	}

	static function savePlaylist(jsonFile:String, name:String, entries:Array<Dynamic>):Void
	{
		try
		{
			File.saveContent(jsonFile, Json.stringify({name: name, list: entries}, '\t'));
		}
		catch (e:Dynamic)
			trace('[PlayList] 写回 $jsonFile 失败：$e');
	}

	// JSON 条目 → UI 用的 SongInfo；歌单内文件统一解析成 PlayList/... 的完整相对路径
	static function entryToSongInfo(folder:String, e:Dynamic):SongInfo
	{
		var dir:String = PLAYLIST_ROOT + folder + '/';

		var sound:Array<FlxSoundAsset> = [];
		if (e.sound != null && Std.isOfType(e.sound, Array))
		{
			var sounds:Array<Dynamic> = e.sound;
			for (item in sounds)
			{
				if (item == null || !Std.isOfType(item, String)) continue;
				var rel:String = resolveEntryFile(dir, item);
				if (rel != null) sound.push(dir + rel);
			}
		}
		if (sound.length == 0) return null;

		var name:String = (e.name != null && Std.string(e.name).length > 0)
			? Std.string(e.name)
			: Path.withoutExtension(Path.withoutDirectory(Std.string(sound[0])));

		var writer:String = (e.writer != null) ? Std.string(e.writer) : '';
		var bpm:Float = 0;
		if (e.bpm != null)
		{
			bpm = Std.parseFloat(Std.string(e.bpm));
			if (Math.isNaN(bpm)) bpm = 0;
		}

		var font:String = (e.font != null && Std.isOfType(e.font, String)) ? e.font : null;

		return {
			name: name,
			sound: sound,
			background: resolvePathArray(dir, e.background, IMAGE_EXTS),
			record: resolvePathArray(dir, e.record, IMAGE_EXTS),
			lyrics: resolveFilePath(dir, e.lyrics, LYRIC_EXTS),
			bpm: bpm,
			writer: writer,
			font: font
		};
	}

	// 封面/唱片数组：歌单内存在的文件 → 完整路径；否则原样透传（资源键，走 Paths.image）
	static function resolvePathArray(dir:String, raw:Dynamic, ?autoExts:Array<String>):Array<FlxGraphicAsset>
	{
		if (raw == null || !Std.isOfType(raw, Array)) return null;
		var out:Array<FlxGraphicAsset> = [];
		var rawArr:Array<Dynamic> = raw;
		for (item in rawArr)
		{
			if (item == null || !Std.isOfType(item, String)) continue;
			var s:String = StringTools.trim(item);
			if (Path.isAbsolute(s))
			{
				out.push(s);
				continue;
			}
			var rel:String = null;
			if (s.indexOf('/') >= 0 || s.indexOf('\\') >= 0)
			{
				if (FileSystem.exists(dir + s)) rel = s;
			}
			else
			{
				// 裸文件名：先按原样找，再尝试补全可省略的扩展名
				if (FileSystem.exists(dir + s))
					rel = s;
				else if (autoExts != null)
					for (ext in autoExts)
						if (FileSystem.exists(dir + s + '.' + ext))
						{
							rel = s + '.' + ext;
							break;
						}
			}
			out.push((rel != null) ? dir + rel : s);
		}
		return out;
	}

	static function resolveFilePath(dir:String, raw:Dynamic, ?autoExts:Array<String>):String
	{
		if (raw == null || !Std.isOfType(raw, String)) return null;
		var s:String = StringTools.trim(raw);
		if (s.length == 0) return null;
		if (Path.isAbsolute(s))
			return FileSystem.exists(s) ? s : null;
		if (FileSystem.exists(dir + s)) return dir + s;
		if (s.indexOf('/') == -1 && s.indexOf('\\') == -1)
		{
			if (FileSystem.exists(dir + 'lyrics/' + s)) return dir + 'lyrics/' + s;
			if (autoExts != null)
				for (ext in autoExts)
					if (FileSystem.exists(dir + s + '.' + ext)) return dir + s + '.' + ext;
		}
		// 不在歌单内 → 原样返回（交给 FileSystem.exists 兜底判断）
		return s;
	}

	// =========================================================
	// 歌单本地文件的加载辅助（RelaxSubState / 磁贴封面共用）
	// =========================================================

	// 歌单内文件的完整路径都以 PlayList/ 开头，据此区分资源键（走 Paths）
	public static function isPlaylistPath(path:String):Bool
	{
		return path != null && StringTools.startsWith(path, PLAYLIST_ROOT);
	}

	public static function resolveSound(path:String):Sound
	{
		if (path == null) return null;
		if (!isPlaylistPath(path))
			return Paths.returnSound(path, null, null, false, true);

		if (!FileSystem.exists(path)) return null;
		var sound:Sound = Cache.currentTrackedSounds.get(path);
		if (sound == null)
		{
			sound = Sound.fromFile(path);
			Cache.currentTrackedSounds.set(path, sound);
		}
		Cache.trackLocalAsset(path);
		return sound;
	}

	public static function resolveImage(key:String):FlxGraphic
	{
		if (key == null || key.length == 0) return null;
		if (!isPlaylistPath(key))
			return Paths.image(key, null, false, true);

		if (!FileSystem.exists(key)) return null;
		if (Cache.currentTrackedAssets.exists(key))
		{
			Cache.trackLocalAsset(key);
			return Cache.currentTrackedAssets.get(key);
		}
		// 与 Paths.image 同一套缓存/GPU 管线，只是文件在歌单目录里
		return Paths.cacheBitmap(key, BitmapData.fromFile(key), false);
	}

	// =========================================================
	// 歌词：标准 LRC（推荐）+ 旧版 JSON 格式
	// =========================================================

	static var timeTagRe:EReg = ~/^\[(\d+):(\d+)(?:[.:](\d+))?\]/;
	static var wordTagRe:EReg = ~/<[^>]*>/g; // 增强型 LRC 的逐字时间标签

	static public function getSongLyrics(songInfo:SongInfo):Array<Dynamic>{
		if (songInfo.lyrics == null || !FileSystem.exists(songInfo.lyrics))
			return [];

		var content:String = File.getContent(songInfo.lyrics);
		if (content == null) return [];

		// LRC：[mm:ss.xx]歌词；JSON：{font, lyrics:[[毫秒, "文本"]]}
		if (StringTools.endsWith(songInfo.lyrics.toLowerCase(), '.lrc'))
		{
			var lrcMap = parseLRC(content);
			if (lrcMap == null) return [];
			return [lrcMap, songInfo.font];
		}

		try{
			var lyricsData:SongLyrics = Json.parse(content);

			var LyricsDatas:Map<Int, String> = new Map<Int, String>();
			for (lyricEntry in lyricsData.lyrics) {
				var timestamp:Int = Std.int(lyricEntry[0]);
				var text:String = lyricEntry[1];
				LyricsDatas.set(timestamp, text);
			}

			// 字体优先级：歌词 JSON 内嵌 > 条目 font 字段
			var font:String = (lyricsData.font != null) ? lyricsData.font : songInfo.font;
			return [LyricsDatas, font];
		}catch(e:Dynamic){
			trace('[PlayList] 歌词解析失败（${songInfo.lyrics}）：$e');
			return [];
		}
	}

	static function parseLRC(content:String):Map<Int, String>
	{
		if (content.charCodeAt(0) == 0xFEFF) // BOM
			content = content.substr(1);

		var map = new Map<Int, String>();
		for (rawLine in content.split('\n'))
		{
			var line:String = StringTools.trim(rawLine);
			if (line.length == 0) continue;

			// 一行可以带多个时间标签
			var times:Array<Int> = [];
			while (timeTagRe.match(line))
			{
				var min:Int = Std.parseInt(timeTagRe.matched(1));
				var sec:Int = Std.parseInt(timeTagRe.matched(2));
				var ms:Int = 0;
				var frac:String = timeTagRe.matched(3);
				if (frac != null && frac.length > 0)
				{
					ms = Std.parseInt(frac);
					if (frac.length == 1) ms *= 100;      // [..:ss.s]
					else if (frac.length == 2) ms *= 10;  // [..:ss.ss]
					else ms = Std.parseInt(frac.substr(0, 3));
				}
				times.push(min * 60000 + sec * 1000 + ms);
				line = StringTools.trim(timeTagRe.matchedRight());
			}

			if (times.length == 0) continue; // [ar:...] 之类的元数据行
			line = wordTagRe.split(line).join('');
			if (line.length == 0) continue;

			for (t in times)
				map.set(t, line);
		}
		return map;
	}
}
#end
