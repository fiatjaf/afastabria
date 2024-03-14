class RelayUtil {
  static String normalizeURL(String url) {
    url = url.trim();
    if (url.startsWith('http')) {
      url = "ws${url.substring(4)}";
    }
    var qs = url.indexOf("?", 8);
    if (qs != -1) {
      url = url.substring(0, qs);
    }
    while (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String? getSubscriptionId(String json) {
    int idx = json.substring(0, 22).indexOf('"EVENT"');
    if (idx == -1) return null;

    int pstart = json.indexOf('"', idx + 7 + 1);
    if (pstart == -1) return null;
    int start = pstart;

    int pend = json.substring(start + 1, start + 80).indexOf('"');
    if (pend == -1) return null;
    int end = start + 1 + pend;

    return json.substring(start + 1, end);
  }

  static String? getEventId(String json) {
    int idx = json.indexOf('"id":') + 5;
    if (idx == -1) {
      return null;
    }
    int s = json.indexOf('"', idx) + 1;
    return json.substring(s, s + 64);
  }
}
