package psychlua.callbacks;

import backend.Paths;
import psychlua.FunkinLua;
import psychlua.LuaUtils;

// REFACTOR: extracted from psychlua.FunkinLua (file IO API)
class FileCallbacks
{
	public static function register(funk:FunkinLua):Void {
		@:privateAccess {
		FunkinLua.registerFunction("checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute)
			{
				return FileSystem.exists(filename);
			}

			var path:String = Paths.modFolders(filename);
			if(FileSystem.exists(path))
			{
				return true;
			}
			return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
			#else
			if(absolute)
			{
				return Assets.exists(filename);
			}
			return Assets.exists(Paths.getPath('assets/$filename', TEXT));
			#end
		});
		FunkinLua.registerFunction("saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try {
				if(!absolute)
					File.saveContent(Paths.mods(path), content);
				else
					File.saveContent(path, content);

				return true;
			} catch (e:Dynamic) {
				LuaUtils.luaTrace(funk.lua, "saveFile | Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		FunkinLua.registerFunction("deleteFile", function(path:String, ?ignoreModFolders:Bool = false)
		{
			try {
				#if MODS_ALLOWED
				if(!ignoreModFolders)
				{
					var lePath:String = Paths.modFolders(path);
					if(FileSystem.exists(lePath))
					{
						FileSystem.deleteFile(lePath);
						return true;
					}
				}
				#end

				var lePath:String = Paths.getPath(path, TEXT);
				if(Assets.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) {
				LuaUtils.luaTrace(funk.lua, "deleteFile | Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		FunkinLua.registerFunction("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		FunkinLua.registerFunction("directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});
		}
	}
}
