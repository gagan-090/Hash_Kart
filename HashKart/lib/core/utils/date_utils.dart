class DateUtils {
  /// Safely parse a date string, returning a default value if null or invalid
  static DateTime safeParseDate(dynamic dateString, {DateTime? defaultValue}) {
    try {
      if (dateString == null) {
        return defaultValue ?? DateTime.now();
      }
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return defaultValue ?? DateTime.now();
    }
  }
  
  /// Safely parse an optional date string, returning null if null or invalid
  static DateTime? safeParseOptionalDate(dynamic dateString) {
    try {
      if (dateString == null) {
        return null;
      }
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return null;
    }
  }
}
