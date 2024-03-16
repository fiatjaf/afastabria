import 'package:flutter/material.dart';
import 'package:loure/client/aid.dart';
import 'package:loure/client/event.dart';
import 'package:loure/main.dart';
import 'package:loure/util/later_function.dart';
import 'package:loure/client/event_kind.dart' as kind;

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
      // load
      Map<String, dynamic> filter = {};
      filter["kinds"] = [kind.EventKind.COMMUNITY_APPROVED];
      List<String> ids = [];
      ids.addAll(eids);
      filter["#e"] = ids;
      eids.clear();
      nostr.pool.querySync(["wss://relay.nostr.band"], filter).then(onEvent);
    }

    if (pendingEvents.isNotEmpty) {
      bool updated = false;

      for (var e in pendingEvents) {
        var eid = getEId(e);
        if (eid != null) {
          // TODO need to check pubkey is Moderated or not.
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
