package mobile.backend;

import lime.system.System as LimeSystem;

#if android
import android.jni.JNICache;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
#end

/**
 * A storage class for mobile.
 * @author Mihai Alexandru (M.A. Jigsaw) and Lily (mcagabe19)
 */
class SUtil
{
	#if sys
	public static function getStorageDirectory(type:StorageType = EXTERNAL, ?folderOverride:String = null):String
	{
		var daPath:String = '';
		#if android
			var folderName:String = (folderOverride != null) ? folderOverride : lime.app.Application.current.meta.get("file");
		switch (type)
		{
			case EXTERNAL:
				daPath = AndroidEnvironment.getExternalStorageDirectory() + '/.' + folderName;
		}
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#else
		daPath = Sys.getCwd();
		#end
		daPath = haxe.io.Path.addTrailingSlash(daPath);
		return daPath;
	}

	public static function mkDirs(directory:String):Void
	{
		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				try
				{
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
				catch (e:haxe.Exception)
					trace('Error while creating folder. (${e.message}');
			}
		}
	}

	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'You forgor to add somethin\' in yo code :3'):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/' + fileName + fileExtension, fileData);
			showPopUp(fileName + " file has been saved.", "Success!");
		}
		catch (e:haxe.Exception)
			trace('File couldn\'t be saved. (${e.message})');
	}

	#if android
	public static function doPermissionsShit():Void
	{
		// 按 Android 版本分流（移植自 FE Mobile StorageUtil）：
		//   API 30+  —— 只认「所有文件访问权限」，isExternalStorageManager 在这区间才有意义
		//   API 29-  —— 只认运行时存储权限；isExternalStorageManager 在这区间恒 true，
		//              拿它判断会让整段权限检查失效，目录能建出来但写不进去
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.R)
		{
			if (!AndroidEnvironment.isExternalStorageManager())
				AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		try
		{
			// 去掉尾部斜杠再 mkdir：FUSE 上带斜杠的路径个别 ROM 会拒绝
			var root:String = getStorageDirectory();
			if (root.endsWith('/'))
				root = root.substr(0, root.length - 1);
			if (!FileSystem.exists(root))
				FileSystem.createDirectory(root);

			// 写探针：目录建得出来不代表写得进去（scoped storage / 运行时权限被拒）。
			// 写不进去时后续复制和 zip 解压都会静默全失败，玩家看到的是「目录是空的」。
			var probe:String = root + '/.nf_write_probe';
			File.saveContent(probe, 'ok');
			FileSystem.deleteFile(probe);
		}
		catch (e:Dynamic)
		{
			// 区分「权限没给」和「真的建不出来」：提示必须把人送去能解决问题的那一页，
			// 否则玩家看到的是「请手动创建文件夹」，而真正缺的是权限。
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.R)
			{
				if (!AndroidEnvironment.isExternalStorageManager())
				{
					AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
					showPopUp('The engine needs "All files access" to create\n'
						+ getStorageDirectory()
						+ '\n\nTurn it on in the settings page that just opened, then reopen the game.', 'Error!');
				}
				else
					showPopUp('Please create folder to\n' + getStorageDirectory() + '\nPress OK to close the game', 'Error!');
			}
			else
			{
				// Android 10 及以下没有「所有文件访问权限」开关，缺的是运行时存储权限
				AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
				AndroidSettings.requestSetting('APPLICATION_DETAILS_SETTINGS');
				showPopUp('The engine needs storage permission to write\n'
					+ getStorageDirectory()
					+ '\n\nAllow "Storage" for this app in the settings page that just opened, then reopen the game.', 'Error!');
			}
			LimeSystem.exit(1);
		}
	}
	#end

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		// AndroidTools wraps even a null callback in a temporary HaxeObject.
		// The Java dialog can outlive that wrapper and call an invalid native
		// object when OK is pressed. Pass null callback objects to Java instead.
		JNICache.createStaticMethod('org/haxe/extension/Tools', 'showAlertDialog',
			'(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lorg/haxe/lime/HaxeObject;Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V')(title,
				message, 'OK', null, null, null);
		#else
		var application = lime.app.Application.current;
		if (application != null && application.window != null)
			application.window.alert(message, title);
		else
			Sys.println('$title\n$message');
		#end
	}
	#end
}

enum StorageType
{
	EXTERNAL;
}
