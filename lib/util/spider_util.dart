class SpiderUtil {
  static String subUntil(
      final String content, final String before, final String end) {
    final beforeLength = before.length;
    final index = content.indexOf(before);
    if (index < 0) {
      return "";
    }

    final index2 = content.indexOf(end, index + beforeLength);
    if (index2 <= 0) {
      return "";
    }

    return content.substring(index + beforeLength, index2);
  }
}
