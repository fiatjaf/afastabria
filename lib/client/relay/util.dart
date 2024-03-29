class RelayUtil {
  static String normalizeURL(String url) {
    url = url.trim();
    if (url.startsWith("http")) {
      url = "ws${url.substring(4)}";
    }
    final qs = url.indexOf("?");
    if (qs != -1) {
      url = url.substring(0, qs);
    }
    while (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String? getSubscriptionId(final String json) {
    final match = json.startsWith('["EVENT","');
    if (!match) return null;

    const start = 9;
    final int pend = json.substring(start + 1, start + 80).indexOf('"');
    if (pend == -1) return null;
    final int end = start + 1 + pend;

    return json.substring(start + 1, end);
  }

  static String? getEventId(final String json) {
    final int idx = json.indexOf('"id":') + 5;
    if (idx == -1) {
      return null;
    }
    final int s = json.indexOf('"', idx) + 1;
    return json.substring(s, s + 64);
  }
}
