class NumberFormatUtil {
  static String format(final int num) {
    String numStr = num.toString();
    if (num > 1000000) {
      numStr = "${(num / 1000000).toStringAsFixed(1)}m";
    } else if (num > 1000) {
      numStr = "${(num / 1000).toStringAsFixed(1)}k";
    }

    return numStr;
  }
}
