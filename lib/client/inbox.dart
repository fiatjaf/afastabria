import "package:collection/collection.dart";
import "package:flutter/material.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/data/db.dart";
import "package:loure/data/note_db.dart";
import "package:loure/main.dart";
import "package:loure/util/eventlist.dart";

class InboxManager extends ChangeNotifier {
  InboxManager();

  List<Event> events = [];
  final ValueNotifier<int> newEvents = ValueNotifier(0);

  ManySubscriptionHandle? subHandle;
  final List<Event> unmerged = [];

  void init() async {
    // load notes from db
    this.events = await NoteDB.loadMentions();
    this.notifyListeners();

    // start subscription
    this.subHandle = pool.subscribeMany(
      nostr.relayList.read,
      [
        Filter(kinds: [
          EventKind.TEXT_NOTE,
          EventKind.REPOST,
          EventKind.BADGE_AWARD,
          EventKind.GENERIC_REPOST,
          EventKind.LONG_FORM,
        ], since: this.events.length == 0 ? 0 : this.events[0].createdAt)
      ],
      onEvent: this.handleEvent,
      id: "inbox",
    );
  }

  void reload() async {
    if (this.subHandle != null) {
      this.subHandle!.close();
    }
    this.events = [];
    this.init();
  }

  void handleEvent(final event) {
    this.unmerged.add(event);
    this.newEvents.value++;
  }

  mergeNewNotes() {
    DB.transaction((final txn) async {
      for (final event in this.unmerged) {
        final idx = whereToInsert(this.events, event);
        if (idx == -1) {
          // event is already here
          continue;
        }
        this.events.insert(idx, event);

        await nostr.processDownloadedEvent(event, db: txn);
      }
    });
    this.notifyListeners();

    this.unmerged.clear();
    this.newEvents.value = 0;
  }

  @override
  dispose() {
    super.dispose();
    if (this.subHandle != null) this.subHandle!.close();
  }

  static bool isMention(Event evt) {
    return evt.tags.firstWhereOrNull(
            (tag) => tag.length > 1 && tag[1] == nostr.publicKey) !=
        null;
  }
}
