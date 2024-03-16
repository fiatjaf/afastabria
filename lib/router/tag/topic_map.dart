class TopicMap {
  static List<List<String>> topicLists = [
    ["nostr", "Nostr", "NOSTR"],
    ["zap", "ZAP", "Zap"],
    ["sats", "Sats", "SATS"],
    ["onlyzap", "onlyZap", "onlyZAP"],
    // client
    ["nostrmo", "Nostrmo", "NostrMo", "NostrMO"],
    ["nostrmofaq", "Nostrmofaq", "NostrmoFAQ"],
    ["Damus", "damus", "DAMUS"],
    ["Amethyst", "amethyst"],
    // coint
    ["Bitcion", "btc", "BTC", "bition"],
    ["nft", "NFT"],
    // country
    ["japan", "jp", "Japan", "JAPAN"],
    ["Zapan", "zapan", "Zapathon", "zapathon"],
    // others
    ["game", "Game", "GAME"],
  ];

  static Map<String, List<String>> topicMap = {};

  static List<String>? getList(final String topic) {
    if (topicMap.isEmpty) {
      for (final list in topicLists) {
        for (final t in list) {
          topicMap[t] = list;
        }
      }

      // nips
      for (var i = 0; i < 10; i++) {
        final list = [
          "NIP0$i",
          "NIP-0$i",
          "nip0$i",
          "nip-0$i",
          "Nip0$i",
          "Nip-0$i"
        ];
        for (final t in list) {
          topicMap[t] = list;
        }
      }
      for (var i = 10; i < 100; i++) {
        final list = ["NIP$i", "NIP-$i", "nip$i", "nip-$i", "Nip$i", "Nip-$i"];
        for (final t in list) {
          topicMap[t] = list;
        }
      }
    }

    return topicMap[topic];
  }
}
