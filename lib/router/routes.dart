import "dart:async";

import "package:flutter/material.dart";
import "package:loure/client/event.dart";

import "package:loure/router/bookmark/bookmark_router.dart";
import "package:loure/router/index/index_router.dart";
import "package:loure/router/user/followed_communities_router.dart";
import "package:loure/router/user/followed_router.dart";
import "package:loure/router/community/community_detail_router.dart";
import "package:loure/router/dm/dm_detail_router.dart";
import "package:loure/router/filter/filter_router.dart";
import "package:loure/router/keybackup/key_backup_router.dart";
import "package:loure/router/notice/notice_router.dart";
import "package:loure/router/profile_editor/profile_editor_router.dart";
import "package:loure/router/qrscanner/qrscanner_router.dart";
import "package:loure/router/relays/relay_info_router.dart";
import "package:loure/router/relays/relays_router.dart";
import "package:loure/router/setting/setting_router.dart";
import "package:loure/router/thread/thread_detail_router.dart";
import "package:loure/router/user/followed_tags_list_router.dart";
import "package:loure/router/user/user_contact_list_router.dart";
import "package:loure/router/user/user_history_contact_list_router.dart";
import "package:loure/router/user/user_relays_router.dart";
import "package:loure/router/user/user_router.dart";
import "package:loure/router/web_utils/web_utils_router.dart";

class InternalRouter {
  final StreamController<Widget> _streamController = StreamController<Widget>();

  List<Widget> _stack = [];
  List<dynamic> _arguments = [];
  List<Completer> _completers = [];

  Stream<Widget> get stream => _streamController.stream;

  static const Widget base =
      Center(child: Text("There should be a universe here."));

  Future<dynamic> push(Widget widget, {bool clear = false, dynamic arg}) {
    if (clear) {
      for (final c in this._completers) {
        c.complete(null);
      }
      this._stack = [];
      this._arguments = [];
      this._completers = [];
    }

    final completer = Completer();

    this._stack.add(widget);
    this._arguments.add(arg);
    this._completers.add(completer);

    this._streamController.add(widget);

    return completer.future;
  }

  void pop([dynamic withValue]) {
    if (this._completers.length == 0) return;

    this._completers[this._completers.length - 1].complete(withValue);

    this._stack.removeLast();
    this._completers.removeLast();

    Widget next = InternalRouter.base;
    if (this._stack.length > 0) {
      next = this._stack[this._stack.length - 1];
    }
    this._streamController.add(next);
  }

  dynamic lastArgument() {
    return this._arguments[this._arguments.length - 1];
  }
}

class RouterPath {
  static const String INDEX = "/";
  static const String EDITOR = "/editor";
  static const String NOTICES = "/notices";
  static const String KEY_BACKUP = "/keyBackup";
  static const String RELAYS = "/relays";
  static const String FILTER = "/filter";
  static const String USER = "/user";
  static const String PROFILE_EDITOR = "/profileEditor";
  static const String USER_CONTACT_LIST = "/userContactList";
  static const String USER_HISTORY_CONTACT_LIST = "/userHistoryContactList";
  static const String USER_RELAYS = "/userRelays";
  static const String DM_DETAIL = "/dmDetail";
  static const String THREAD_DETAIL = "/threadDetail";
  static const String SETTING = "/setting";
  static const String QRSCANNER = "/qrScanner";
  static const String WEBUTILS = "/webUtils";
  static const String RELAY_INFO = "/relayInfo";
  static const String FOLLOWED_TAGS_LIST = "/followedTagsList";
  static const String COMMUNITY_DETAIL = "/communityDetail";
  static const String FOLLOWED_COMMUNITIES = "/followedCommunities";
  static const String FOLLOWED = "/followed";
  static const String BOOKMARK = "/bookmark";
}

Widget renderWidget(RouteSettings rs) {
  switch (rs.name) {
    case RouterPath.INDEX:
      return const IndexRouter();
    case RouterPath.USER:
      return UserRouter(rs.arguments as String);
    case RouterPath.USER_CONTACT_LIST:
      return const UserContactListRouter();
    case RouterPath.USER_HISTORY_CONTACT_LIST:
      return const UserHistoryContactListRouter();
    case RouterPath.USER_RELAYS:
      return const UserRelayRouter();
    case RouterPath.DM_DETAIL:
      return const DMDetailRouter();
    case RouterPath.THREAD_DETAIL:
      return ThreadDetailRouter(rs.arguments as Event);
    case RouterPath.NOTICES:
      return const NoticeRouter();
    case RouterPath.KEY_BACKUP:
      return const KeyBackupRouter();
    case RouterPath.RELAYS:
      return const RelaysRouter();
    case RouterPath.FILTER:
      return const FilterRouter();
    case RouterPath.PROFILE_EDITOR:
      return const ProfileEditorRouter();
    case RouterPath.SETTING:
      return const SettingRouter();
    case RouterPath.QRSCANNER:
      return const QRScannerRouter();
    case RouterPath.WEBUTILS:
      return const WebUtilsRouter();
    case RouterPath.RELAY_INFO:
      return const RelayInfoRouter();
    case RouterPath.FOLLOWED_TAGS_LIST:
      return const FollowedTagsListRouter();
    case RouterPath.COMMUNITY_DETAIL:
      return const CommunityDetailRouter();
    case RouterPath.FOLLOWED_COMMUNITIES:
      return const FollowedCommunitiesRouter();
    case RouterPath.FOLLOWED:
      return const FollowedRouter();
    case RouterPath.BOOKMARK:
      return const BookmarkRouter();
    case _:
      return const IndexRouter();
  }
}
