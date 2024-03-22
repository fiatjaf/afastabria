import "package:flutter/material.dart";

import "package:loure/client/event_kind.dart";
import "package:loure/client/event.dart";
import "package:loure/client/filter.dart";
import "package:loure/client/nip04/dm_session.dart";
import "package:loure/data/dm_session_info.dart";
import "package:loure/data/dm_session_info_db.dart";
import "package:loure/data/event_db.dart";
import "package:loure/main.dart";
import "package:loure/util/pendingevents_later_function.dart";
import "package:loure/util/string_util.dart";

class DMProvider extends ChangeNotifier with PendingEventsLaterFunction {
  final List<DMSessionDetail> _knownList = [];
  final List<DMSessionDetail> _unknownList = [];
  final Map<String, DMSession> _sessions = {};
  Map<String, DMSessionInfo> infoMap = {};
  List<DMSessionDetail> get knownList => _knownList;
  List<DMSessionDetail> get unknownList => _unknownList;

  DMSession? getSession(final String pubkey) {
    return _sessions[pubkey];
  }

  DMSessionDetail findOrNewADetail(final String pubkey) {
    for (final detail in knownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    for (final detail in _unknownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    final dmSession = DMSession(pubkey: pubkey);
    final DMSessionDetail detail = DMSessionDetail(dmSession);
    detail.info = DMSessionInfo(pubkey: pubkey, readedTime: 0);

    return detail;
  }

  void updateReadedTime(final DMSessionDetail? detail) {
    if (detail != null &&
        detail.info != null &&
        detail.dmSession.newestEvent != null) {
      detail.info!.readedTime = detail.dmSession.newestEvent!.createdAt;
      DMSessionInfoDB.update(detail.info!);
      notifyListeners();
    }
  }

  void addEventAndUpdateReadedTime(
      final DMSessionDetail detail, final Event event) {
    pendingEvents.add(event);
    eventLaterHandle(pendingEvents, updateUI: false);
    updateReadedTime(detail);
  }

  Future<DMSessionDetail> addDmSessionToKnown(
      final DMSessionDetail detail) async {
    final keyIndex = settingProvider.privateKeyIndex!;
    final pubkey = detail.dmSession.pubkey;
    final DMSessionInfo o = DMSessionInfo(pubkey: pubkey);
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

    final keyIndex = settingProvider.privateKeyIndex!;
    final events =
        await EventDB.list(keyIndex, EventKind.DIRECT_MESSAGE, 0, 10000000);
    if (events.isNotEmpty) {
      // find the newest event, subscribe behind the new newest event
      _initSince = events.first.createdAt;
    }

    Map<String, List<Event>> eventListMap = {};
    for (final event in events) {
      // print("dmEvent");
      // print(event.toJson());
      final pubkey = _getPubkey(nostr.publicKey, event);
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
    final infos = await DMSessionInfoDB.all(keyIndex);
    for (final info in infos) {
      infoMap[info.pubkey!] = info;
    }

    for (final entry in eventListMap.entries) {
      final pubkey = entry.key;
      final list = entry.value;

      final session = DMSession(pubkey: pubkey);
      session.addEvents(list);

      _sessions[pubkey] = session;

      final info = infoMap[pubkey];
      final detail = DMSessionDetail(session, info: info);
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

  void _doSortDetailList(final List<DMSessionDetail> detailList) {
    detailList.sort((final detail0, final detail1) {
      return detail1.dmSession.newestEvent!.createdAt -
          detail0.dmSession.newestEvent!.createdAt;
    });

    // // copy to a new list for provider update
    // var length = detailList.length;
    // List<DMSessionDetail> newlist =
    //     List.generate(length, (index) => detailList[index]);
    // return newlist;
  }

  String? _getPubkey(final String localPubkey, final Event event) {
    if (event.pubkey != localPubkey) {
      return event.pubkey;
    }

    for (final tag in event.tags) {
      if (tag[0] == "p") {
        return tag[1];
      }
    }

    return null;
  }

  void query() {
    final filter0 = Filter(
      kinds: [EventKind.DIRECT_MESSAGE],
      authors: [nostr.publicKey],
      since: _initSince + 1,
    );
    final filter1 = Filter(
      kinds: [EventKind.DIRECT_MESSAGE],
      p: [nostr.publicKey],
      since: _initSince + 1,
    );

    pool.subscribeMany(nostr.relayList.read, [filter0, filter1],
        onEvent: (final Event event) {
      later(event, eventLaterHandle, null);
    });
  }

  bool _addEvent(final String localPubkey, final Event event) {
    final pubkey = _getPubkey(localPubkey, event);
    if (StringUtil.isBlank(pubkey)) {
      return false;
    }

    var session = _sessions[pubkey];
    if (session == null) {
      session = DMSession(pubkey: pubkey!);
      _sessions[pubkey] = session;
    }
    final addResult = session.addEvent(event);

    if (addResult) {
      session = session.clone();
      _sessions[pubkey!] = session;
    }

    return addResult;
  }

  void eventLaterHandle(final List<Event> events,
      {final bool updateUI = true}) {
    bool updated = false;
    final keyIndex = settingProvider.privateKeyIndex!;
    for (final event in events) {
      final addResult = _addEvent(nostr.publicKey, event);
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
  DMSessionDetail(this.dmSession, {this.info});
  DMSession dmSession;
  DMSessionInfo? info;

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
