import 'package:flutter/material.dart';
import 'package:loure/client/aid.dart';
import 'package:loure/client/event.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/main.dart';
import 'package:loure/util/later_function.dart';
import 'package:loure/client/event_kind.dart';

class CommunityApprovedProvider extends ChangeNotifier with LaterFunction {
  final Map<String, int> _approvedMap = {};

  List<String> eids = [];

  List<Event> pendingEvents = [];

  bool check(String pubkey, String eid, {AId? aId}) {
    if (_approvedMap[eid] != null || aId == null) {
      return true;
    }

    if (contactListProvider.getContact(pubkey) != null ||
        pubkey == nostr.publicKey) {
      return true;
    }

    // plan to query
    eids.add(eid);
    later(laterFunction, null);

    return false;
  }

  void laterFunction() {
    if (eids.isNotEmpty) {
      final filter = Filter(kinds: [EventKind.COMMUNITY_APPROVED], e: eids);
      eids.clear();
      pool.subscribeManyEose(["wss://relay.nostr.band"], [filter],
          onEvent: onEvent);
    }

    if (pendingEvents.isNotEmpty) {
      bool updated = false;

      for (var e in pendingEvents) {
        var eid = getEId(e);
        if (eid != null) {
          if (_approvedMap[eid] == null) {
            updated = true;
          }

          _approvedMap[eid] = 1;
        }
      }

      pendingEvents.clear();
      if (updated) {
        notifyListeners();
      }
    }
  }

  void onEvent(Event? event) {
    if (event == null) return;
    pendingEvents.add(event);
    later(laterFunction, null);
  }

  String? getEId(Event e) {
    var tags = e.tags;
    for (var tag in tags) {
      if (tag.length > 1) {
        var key = tag[0];
        var value = tag[1];

        if (key == "e") {
          return value;
        }
      }
    }

    return null;
  }
}
