import 'package:flutter/material.dart';

import 'package:loure/client/event_kind.dart';
import 'package:loure/client/event.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/client/nip04/dm_session.dart';
import 'package:loure/data/dm_session_info.dart';
import 'package:loure/data/dm_session_info_db.dart';
import 'package:loure/data/event_db.dart';
import 'package:loure/main.dart';
import 'package:loure/util/pendingevents_later_function.dart';
import 'package:loure/util/string_util.dart';

class DMProvider extends ChangeNotifier with PendingEventsLaterFunction {
  final List<DMSessionDetail> _knownList = [];
  final List<DMSessionDetail> _unknownList = [];
  final Map<String, DMSession> _sessions = {};
  Map<String, DMSessionInfo> infoMap = {};
  List<DMSessionDetail> get knownList => _knownList;
  List<DMSessionDetail> get unknownList => _unknownList;

  DMSession? getSession(String pubkey) {
    return _sessions[pubkey];
  }

  DMSessionDetail findOrNewADetail(String pubkey) {
    for (var detail in knownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    for (var detail in _unknownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    var dmSession = DMSession(pubkey: pubkey);
    DMSessionDetail detail = DMSessionDetail(dmSession);
    detail.info = DMSessionInfo(pubkey: pubkey, readedTime: 0);

    return detail;
  }

  void updateReadedTime(DMSessionDetail? detail) {
    if (detail != null &&
        detail.info != null &&
        detail.dmSession.newestEvent != null) {
      detail.info!.readedTime = detail.dmSession.newestEvent!.createdAt;
      DMSessionInfoDB.update(detail.info!);
      notifyListeners();
    }
  }

  void addEventAndUpdateReadedTime(DMSessionDetail detail, Event event) {
    pendingEvents.add(event);
    eventLaterHandle(pendingEvents, updateUI: false);
    updateReadedTime(detail);
  }

  Future<DMSessionDetail> addDmSessionToKnown(DMSessionDetail detail) async {
    var keyIndex = settingProvider.privateKeyIndex!;
    var pubkey = detail.dmSession.pubkey;
    DMSessionInfo o = DMSessionInfo(pubkey: pubkey);
    o.keyIndex = keyIndex;
    o.readedTime = detail.dmSession.newestEvent!.createdAt;
    await DMSessionInfoDB.insert(o);

    dmProvider.infoMap[pubkey] = o;
    detail.info = o;

    unknownList.remove(detail);
    knownList.add(detail);

    _sortDetailList();
    notifyListeners();

    return detail;
  }

  int _initSince = 0;

  Future<void> initDMSessions() async {
    _sessions.clear();
    _knownList.clear();
    _unknownList.clear();

    var keyIndex = settingProvider.privateKeyIndex!;
    var events =
        await EventDB.list(keyIndex, EventKind.DIRECT_MESSAGE, 0, 10000000);
    if (events.isNotEmpty) {
      // find the newest event, subscribe behind the new newest event
      _initSince = events.first.createdAt;
    }

    Map<String, List<Event>> eventListMap = {};
    for (var event in events) {
      // print("dmEvent");
      // print(event.toJson());
      var pubkey = _getPubkey(nostr.publicKey, event);
      if (StringUtil.isNotBlank(pubkey)) {
        var list = eventListMap[pubkey!];
        if (list == null) {
          list = [];
          eventListMap[pubkey] = list;
        }
        list.add(event);
      }
    }

    infoMap = {};
    var infos = await DMSessionInfoDB.all(keyIndex);
    for (var info in infos) {
      infoMap[info.pubkey!] = info;
    }

    for (var entry in eventListMap.entries) {
      var pubkey = entry.key;
      var list = entry.value;

      var session = DMSession(pubkey: pubkey);
      session.addEvents(list);

      _sessions[pubkey] = session;

      var info = infoMap[pubkey];
      var detail = DMSessionDetail(session, info: info);
      if (info != null) {
        _knownList.add(detail);
      } else {
        _unknownList.add(detail);
      }
    }

    _sortDetailList();
    notifyListeners();
  }

  void _sortDetailList() {
    _doSortDetailList(_knownList);
    _doSortDetailList(_unknownList);
  }

  void _doSortDetailList(List<DMSessionDetail> detailList) {
    detailList.sort((detail0, detail1) {
      return detail1.dmSession.newestEvent!.createdAt -
          detail0.dmSession.newestEvent!.createdAt;
    });

    // // copy to a new list for provider update
    // var length = detailList.length;
    // List<DMSessionDetail> newlist =
    //     List.generate(length, (index) => detailList[index]);
    // return newlist;
  }

  String? _getPubkey(String localPubkey, Event event) {
    if (event.pubKey != localPubkey) {
      return event.pubKey;
    }

    for (var tag in event.tags) {
      if (tag[0] == "p") {
        return tag[1];
      }
    }

    return null;
  }

  void query() {
    var filter0 = Filter(
      kinds: [EventKind.DIRECT_MESSAGE],
      authors: [nostr.publicKey],
      since: _initSince + 1,
    );
    var filter1 = Filter(
      kinds: [EventKind.DIRECT_MESSAGE],
      p: [nostr.publicKey],
      since: _initSince + 1,
    );

    nostr.pool.subscribeMany(nostr.relayList.read, [filter0, filter1],
        onEvent: (Event event) {
      later(event, eventLaterHandle, null);
    });
  }

  bool _addEvent(String localPubkey, Event event) {
    var pubkey = _getPubkey(localPubkey, event);
    if (StringUtil.isBlank(pubkey)) {
      return false;
    }

    var session = _sessions[pubkey];
    if (session == null) {
      session = DMSession(pubkey: pubkey!);
      _sessions[pubkey] = session;
    }
    var addResult = session.addEvent(event);

    if (addResult) {
      session = session.clone();
      _sessions[pubkey!] = session;
    }

    return addResult;
  }

  void eventLaterHandle(List<Event> events, {bool updateUI = true}) {
    bool updated = false;
    var keyIndex = settingProvider.privateKeyIndex!;
    for (var event in events) {
      var addResult = _addEvent(nostr.publicKey, event);
      // save to local
      if (addResult) {
        updated = true;
        EventDB.insert(keyIndex, event);
      }
    }

    if (updated) {
      _sortDetailList();
      if (updateUI) {
        notifyListeners();
      }
    }
  }

  void clear() {
    _sessions.clear();
    _knownList.clear();
    _unknownList.clear();

    notifyListeners();
  }
}

class DMSessionDetail {
  DMSession dmSession;
  DMSessionInfo? info;

  DMSessionDetail(this.dmSession, {this.info});

  bool hasNewMessage() {
    if (info == null) {
      return true;
    } else if (dmSession.newestEvent != null &&
        info!.readedTime! < dmSession.newestEvent!.createdAt) {
      return true;
    }
    return false;
  }
}
