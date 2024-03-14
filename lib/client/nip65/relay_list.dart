import 'package:nostrmo/client/event.dart';

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

      if (tag.length >= 3) {
        if (tag[2] == "read") {
          read.add(tag[1]);
          continue;
        }
        if (tag[2] == "write") {
          read.add(tag[1]);
          continue;
        }
        if (tag[2] == "") {
          read.add(tag[1]);
          write.add(tag[1]);
        }
      } else {
        read.add(tag[1]);
        write.add(tag[1]);
      }
    }
    return RelayList(read, write);
  }

  Event toEvent(String privateKey) {
    List<List<String>> tags = [];
    for (var relay in write) {
      tags.add(["r", relay, "write"]);
    }

    return Event.finalize(privateKey, 10002, tags, "");
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
