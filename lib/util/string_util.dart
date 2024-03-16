class StringUtil {
  static bool isNotBlank(final String? str) {
    if (str != null && str != "") {
      return true;
    }
    return false;
  }

  static bool isBlank(final String? str) {
    return !isNotBlank(str);
  }

  static String breakWord(final String word) {
    if (word.isEmpty) {
      return word;
    }
    String breakWord = "";
    for (final element in word.runes) {
      breakWord += String.fromCharCode(element);
      breakWord += "\u200B";
    }
    return breakWord;
  }
}
