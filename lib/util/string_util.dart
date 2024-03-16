class StringUtil {
  static bool isNotBlank(String? str) {
    if (str != null && str != "") {
      return true;
    }
    return false;
  }

  static bool isBlank(String? str) {
    return !isNotBlank(str);
  }

  static String breakWord(String word) {
    if (word.isEmpty) {
      return word;
    }
    String breakWord = '';
    for (var element in word.runes) {
      breakWord += String.fromCharCode(element);
      breakWord += '\u200B';
    }
    return breakWord;
  }
}
