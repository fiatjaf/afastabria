import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/relay/util.dart';

class RelayList {
  final List<String> read;
  final List<String> write;

  RelayList(this.read, this.write);

  factory RelayList.fromEvent(Event event) {
    List<String> read = [];
    List<String> write = [];
    for (var tag in event.tags) {
      if (tag.length < 2) {
        continue;
      }

      var url = RelayUtil.normalizeURL(tag[1]);

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
    return RelayList(read, write);
  }

  Event toEvent(String privateKey) {
    List<List<String>> tags = [];
    for (var relay in this.write) {
      List<String> tag = ["r", relay, "write"];
      if (this.read.contains(relay)) {
        tag = tag.sublist(0, 2);
      }
      tags.add(tag);
    }

    for (var relay in this.read) {
      if (this.write.contains(relay)) continue;
      tags.add(["r", relay, "read"]);
    }

    return Event.finalize(privateKey, 10002, tags, "");
  }

  List<String> get all {
    List<String> urls = [];
    for (var relay in this.write) {
      urls.add(relay);
    }
    for (var relay in this.read) {
      if (this.write.contains(relay)) continue;
      urls.add(relay);
    }
    return urls;
  }

  void add(String relay, bool read, bool write) {
    if (read) {
      this.read.add(relay);
    }
    if (write) {
      this.write.add(relay);
    }
  }

  void remove(String relay) {
    this.read.remove(relay);
    this.write.remove(relay);
  }
}
