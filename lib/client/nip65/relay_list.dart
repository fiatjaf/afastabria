import "package:loure/client/event.dart";
import "package:loure/client/relay/util.dart";

class RelayList {
  RelayList(this.pubkey, this.read, this.write, {this.event});

  factory RelayList.fromEvent(final Event event) {
    List<String> read = [];
    List<String> write = [];
    for (final tag in event.tags) {
      if (tag.length < 2) {
        continue;
      }

      final url = RelayUtil.normalizeURL(tag[1]);

      if (tag.length >= 3) {
        if (tag[2] == "read") {
          read.add(url);
          continue;
        }
        if (tag[2] == "write") {
          read.add(url);
          continue;
        }
        if (tag[2] == "") {
          read.add(url);
          write.add(url);
        }
      } else {
        read.add(url);
        write.add(url);
      }
    }
    return RelayList(event.pubKey, read, write, event: event);
  }

  final List<String> read;
  final List<String> write;
  final String pubkey;
  final Event? event;

  Event toEvent(final SignerFunction signer) {
    List<List<String>> tags = [];
    for (final relay in this.write) {
      List<String> tag = ["r", relay, "write"];
      if (this.read.contains(relay)) {
        tag = tag.sublist(0, 2);
      }
      tags.add(tag);
    }

    for (final relay in this.read) {
      if (this.write.contains(relay)) continue;
      tags.add(["r", relay, "read"]);
    }

    return Event.finalizeWithSigner(signer, 10002, tags, "");
  }

  List<String> get all {
    List<String> urls = [];
    for (final relay in this.write) {
      urls.add(relay);
    }
    for (final relay in this.read) {
      if (this.write.contains(relay)) continue;
      urls.add(relay);
    }
    return urls;
  }

  void add(String relay, final bool read, final bool write) {
    relay = RelayUtil.normalizeURL(relay);
    if (read) {
      this.read.add(relay);
    }
    if (write) {
      this.write.add(relay);
    }
  }

  void remove(String relay) {
    relay = RelayUtil.normalizeURL(relay);
    this.read.remove(relay);
    this.write.remove(relay);
  }
}
