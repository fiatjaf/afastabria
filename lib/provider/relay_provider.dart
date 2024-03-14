import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/consts/relay_mode.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/string_util.dart';

import '../client/event.dart';
import '../client/event_kind.dart' as kind;
import '../client/nostr.dart';
import '../client/relay/relay.dart';
import '../client/relay/relay_base.dart';
import '../client/relay/relay_isolate.dart';
import '../consts/client_connected.dart';
import '../data/relay_status.dart';
import '../main.dart';

class RelayProvider extends ChangeNotifier {
  static RelayProvider? _relayProvider;

  List<String> relayAddrs = [];

  Map<String, RelayStatus> relayStatusMap = {};

  static RelayProvider getInstance() {
    _relayProvider ??= RelayProvider();
    return _relayProvider!;
  }

  void loadRelayAddrs(String? content) {
    var relays = parseRelayAddrs(content);
    if (relays.isEmpty) {
      relays = [
        "wss://nos.lol",
        "wss://nostr.wine",
        "wss://atlas.nostr.land",
        "wss://relay.orangepill.dev",
        "wss://relay.damus.io"
      ];
    }

    relayAddrs = relays;
  }

  List<String> parseRelayAddrs(String? content) {
    List<String> relays = [];
    if (StringUtil.isBlank(content)) {
      return relays;
    }

    var jsonObj = jsonDecode(content!);
    Map<dynamic, dynamic> jsonMap =
        jsonObj.map((key, value) => MapEntry(key, true));

    for (var entry in jsonMap.entries) {
      relays.add(entry.key.toString());
    }

    return relays;
  }

  RelayStatus? getRelayStatus(String addr) {
    return relayStatusMap[addr];
  }

  String relayNumStr() {
    var total = relayAddrs.length;

    int connectedNum = 0;
    var it = relayStatusMap.values;
    for (var status in it) {
      if (status.connected == ClientConneccted.CONNECTED) {
        connectedNum++;
      }
    }
    return "$connectedNum / $total";
  }

  int total() {
    return relayAddrs.length;
  }

  Nostr genNostr(String pk) {
    var nostr = Nostr(pk);
    log("nostr init over");

    // add initQuery
    var dmInitFuture = dmProvider.initDMSessions(nostr.publicKey);
    contactListProvider.reload(targetNostr: nostr);
    contactListProvider.query(targetNostr: nostr);
    followEventProvider.doQuery(targetNostr: nostr, initQuery: true);
    mentionMeProvider.doQuery(targetNostr: nostr, initQuery: true);
    dmInitFuture.then((_) {
      dmProvider.query(targetNostr: nostr, initQuery: true);
    });

    loadRelayAddrs(contactListProvider.content);
    listProvider.load(nostr.publicKey,
        [kind.EventKind.BOOKMARKS_LIST, kind.EventKind.EMOJIS_LIST],
        targetNostr: nostr, initQuery: true);
    badgeProvider.reload(targetNostr: nostr, initQuery: true);

    for (var relayAddr in relayAddrs) {
      log("begin to init $relayAddr");
      var custRelay = genRelay(relayAddr);
      try {
        nostr.addRelay(custRelay, init: true);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }

    return nostr;
  }

  void onRelayStatusChange() {
    notifyListeners();
  }

  void addRelay(String relayAddr) {
    if (!relayAddrs.contains(relayAddr)) {
      relayAddrs.add(relayAddr);
      _doAddRelay(relayAddr);
      _updateRelayToContactList();
    }
  }

  void _doAddRelay(String relayAddr, {bool init = false}) {
    var custRelay = genRelay(relayAddr);
    log("begin to init $relayAddr");
    nostr!.addRelay(custRelay, autoSubscribe: true, init: init);
  }

  void removeRelay(String relayAddr) {
    if (relayAddrs.contains(relayAddr)) {
      relayAddrs.remove(relayAddr);
      nostr!.removeRelay(relayAddr);

      _updateRelayToContactList();
    }
  }

  bool containRelay(String relayAddr) {
    return relayAddrs.contains(relayAddr);
  }

  void _updateRelayToContactList() {
    Map<String, dynamic> relaysContentMap = {};
    for (var addr in relayAddrs) {
      relaysContentMap[addr] = {
        "read": true,
        "write": true,
      };
    }
    var relaysContent = jsonEncode(relaysContentMap);
    contactListProvider.updateRelaysContent(relaysContent);

    notifyListeners();
  }

  Relay genRelay(String relayAddr) {
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus == null) {
      relayStatus = RelayStatus(relayAddr);
      relayStatusMap[relayAddr] = relayStatus;
    }

    if (PlatformUtil.isWeb()) {
      // dart:isolate is not supported on dart4web
      return RelayBase(
        relayAddr,
        relayStatus,
        access: WriteAccess.readWrite,
      )..relayStatusCallback = onRelayStatusChange;
    } else {
      if (settingProvider.relayMode == RelayMode.BASE_MODE) {
        return RelayBase(
          relayAddr,
          relayStatus,
          access: WriteAccess.readWrite,
        )..relayStatusCallback = onRelayStatusChange;
      } else {
        return RelayIsolate(
          relayAddr,
          relayStatus,
          access: WriteAccess.readWrite,
        )..relayStatusCallback = onRelayStatusChange;
      }
    }
  }

  void relayUpdateByContactListEvent(Event event) {
    loadRelayAddrs(event.content);
    _updateRelays(relayAddrs);
  }

  void _updateRelays(List<String> relays) {
    var entries = relayStatusMap.entries;

    for (var relayStatusEntry in entries) {
      var relayAddr = relayStatusEntry.key;
      if (!relays.contains(relayAddr)) {
        // new relay don't contain this relay, need to close
        relayStatusMap.remove(relayAddr);
        nostr!.removeRelay(relayAddr);
      }
    }

    for (var relayAddr in relays) {
      if (!relayStatusMap.containsKey(relayAddr)) {
        // local map don't contain relay, add a new one
        _doAddRelay(relayAddr);
      }
    }
  }

  void clear() {
    // sharedPreferences.remove(DataKey.RELAY_LIST);
    relayStatusMap.clear();
    loadRelayAddrs(null);
  }
}
