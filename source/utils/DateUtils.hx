package utils;

// REFACTOR: imports for relocated root classes
import backend.ClientPrefs;
import backend.CoolUtil;

// An utilties class for Date and Time related things (so we don't have to bloat CoolUtil)
// and also because I didn't like how things weren't unified lol
final class DateUtils {
  public static var cleanedDate(get, never):String; // an cleaner version of the current date
  public static var date(default, null):Date = Date.now();
  static inline function get_cleanedDate(){
    var dateNow:String = Date.now().toString();
    dateNow = dateNow.replace(" ", "_");
    dateNow = dateNow.replace(":", "'");
    return dateNow;
  }

  @:noCompletion
  inline public static function isChristmas():Bool
    //Only triggers if the date is between 12/16 and 12/31
    return (date.getMonth() == 11 && date.getDate() >= 16 && date.getDate() <= 31);

  @:noCompletion
  inline public static function isAprilFools():Bool
    #if FUNNY_ALLOWED
    return ((date.getMonth() == 3 && date.getDate() == 1) && !ClientPrefs.disableAprilFools); // funny
    #else
    return false;
    #end

  @:noCompletion
  inline public static function isFunkin():Bool
    return (date.getDay() == 5 && date.getHours() >= 18);
}
