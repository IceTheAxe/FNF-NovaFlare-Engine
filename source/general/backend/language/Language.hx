package general.backend.language;

class Language
{
	static var groups:Map<String, CustomLangGroup> = [];

	public static function get(value:String, type:String = 'options'):String
	{
		var group = groups.get(type);
		if (group != null)
			return group.get(value);
		return ClientPrefs.data.developerMode ? value + ' (404)' : value;
	}

	/**
	 * 带占位符替换的短语读取（FE charm 栈移植）。
	 * 在所有语言分组里找 key，找不到用 defaultPhrase，然后把 {1}..{n} 换成 args 对应项。
	 * 注意：不能走 CustomLangGroup.get()——它缺失时返回 key 本身，无法和"真的翻译成了 key"区分。
	 */
	public static function getPhrase(key:String, defaultPhrase:String, ?args:Array<Dynamic>):String
	{
		var result:String = null;
		for (group in groups)
		{
			var v:String = group.data.get(key);
			if (v == null) v = group.defaultData.get(key);
			if (v != null)
			{
				result = v;
				break;
			}
		}
		if (result == null) result = defaultPhrase;

		if (args != null)
		{
			for (i in 0...args.length)
				result = StringTools.replace(result, '{' + (i + 1) + '}', Std.string(args[i]));
		}
		return result;
	}

	public static function resetData()
	{
		check();
		discoverGroups();
		for (group in groups)
			group.updateLang();
	}

	static function discoverGroups()
	{
		var basePath = Paths.getPath('language') + '/' + ClientPrefs.data.language;
		if (!FileSystem.isDirectory(basePath))
			return;

		for (entry in FileSystem.readDirectory(basePath))
		{
			if (FileSystem.isDirectory(basePath + '/' + entry))
			{
				if (!groups.exists(entry))
					groups.set(entry, new CustomLangGroup(entry));
			}
		}
	}

	public static function check()
	{
		if (!FileSystem.isDirectory(Paths.getPath('language') + '/' + ClientPrefs.data.language))
			ClientPrefs.data.language = 'English';
	}

	public static function setupData(follow:CustomLangGroup, directoryPath:Array<String>)
	{
		for (path in 0...directoryPath.length) {
			if (FileSystem.isDirectory(directoryPath[path])) {
				for (file in FileSystem.readDirectory(directoryPath[path])) {
					if (file.toLowerCase().endsWith('.lang')) {
						var outputData = CoolUtil.coolTextFile(directoryPath[path] + '/' + file);
						for (list in 0...outputData.length) {
							var line = outputData[list];
							if (line.length > 0 && line.indexOf(' => ') != -1) {
								var key:String = line.substr(0, line.indexOf(' => '));
								var value:String = line.substr(line.indexOf(' => ') + 4, line.length);
								if (path == 0)
									follow.defaultData.set(key, value);
								else
									follow.data.set(key, value);
							}
						}
					}
				}
			}
		}
	}
}
