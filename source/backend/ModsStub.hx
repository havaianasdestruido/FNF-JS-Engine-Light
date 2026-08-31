package backend;

// Always-available no-op stub of backend.Mods for non-MODS_ALLOWED targets.
// Callers can reference Mods.<method> without wrapping in #if MODS_ALLOWED;
// on MODS_ALLOWED builds this is shadowed by the real backend.Mods import in import.hx.
class Mods
{
	static public var currentModDirectory:String = '';
	public static var ignoreModFolders:Array<String> = [];
	inline public static function getGlobalMods():Array<String>
		return [];
	inline public static function pushGlobalMods():Array<String>
		return [];
	inline public static function getModDirectories():Array<String>
		return [];
	inline public static function mergeAllTextsNamed(path:String, defaultDirectory:String = null, allowDuplicates:Bool = false):Array<String>
		return [];
	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true):Array<String>
		return [];
	inline public static function getPack(?folder:String = null):Dynamic
		return null;
	public static var updatedOnState:Bool = false;
	inline public static function parseList():ModsList
		return {enabled: [], disabled: [], all: []};
	inline public static function loadTopMod():Void {}
}

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};
