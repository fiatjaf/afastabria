import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loure/client/metadata_loader.dart';
import 'package:loure/client/nostr.dart';
import 'package:loure/client/relay/relay_pool.dart';
import 'package:loure/provider/badge_definition_provider.dart';
import 'package:loure/provider/community_info_provider.dart';
import 'package:loure/provider/follow_new_event_provider.dart';
import 'package:loure/provider/mention_me_new_provider.dart';
import 'package:loure/router/relays/relay_info_router.dart';
import 'package:loure/router/user/followed_router.dart';
import 'package:loure/router/user/followed_tags_list_router.dart';
import 'package:loure/router/user/user_history_contact_list_router.dart';
import 'package:loure/router/user/user_zap_list_router.dart';
import 'package:loure/router/web_utils/web_utils_router.dart';
import 'package:loure/util/platform_util.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'package:loure/consts/base.dart';
import 'package:loure/consts/colors.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/consts/theme_style.dart';
import 'package:loure/data/db.dart';
import 'package:loure/home_component.dart';
import 'package:loure/provider/badge_provider.dart';
import 'package:loure/provider/community_approved_provider.dart';
import 'package:loure/provider/contact_list_provider.dart';
import 'package:loure/provider/dm_provider.dart';
import 'package:loure/provider/event_reactions_provider.dart';
import 'package:loure/provider/filter_provider.dart';
import 'package:loure/provider/follow_event_provider.dart';
import 'package:loure/provider/index_provider.dart';
import 'package:loure/provider/link_preview_data_provider.dart';
import 'package:loure/provider/list_provider.dart';
import 'package:loure/provider/mention_me_provider.dart';
import 'package:loure/provider/pc_router_fake_provider.dart';
import 'package:loure/provider/notice_provider.dart';
import 'package:loure/provider/setting_provider.dart';
import 'package:loure/provider/webview_provider.dart';
import 'package:loure/router/bookmark/bookmark_router.dart';
import 'package:loure/router/community/community_detail_router.dart';
import 'package:loure/router/dm/dm_detail_router.dart';
import 'package:loure/router/donate/donate_router.dart';
import 'package:loure/router/event_detail/event_detail_router.dart';
import 'package:loure/router/filter/filter_router.dart';
import 'package:loure/router/profile_editor/profile_editor_router.dart';
import 'package:loure/router/index/index_router.dart';
import 'package:loure/router/keybackup/key_backup_router.dart';
import 'package:loure/router/notice/notice_router.dart';
import 'package:loure/router/qrscanner/qrscanner_router.dart';
import 'package:loure/router/relays/relays_router.dart';
import 'package:loure/router/setting/setting_router.dart';
import 'package:loure/router/tag/tag_detail_router.dart';
import 'package:loure/router/thread/thread_detail_router.dart';
import 'package:loure/router/user/followed_communities_router.dart';
import 'package:loure/router/user/user_contact_list_router.dart';
import 'package:loure/router/user/user_relays_router.dart';
import 'package:loure/router/user/user_router.dart';
import 'package:loure/system_timer.dart';
import 'package:loure/util/colors_util.dart';
import 'package:loure/util/media_data_cache.dart';

final Map<String, WidgetBuilder> routes = {};

final RelayPool pool = RelayPool();
final metadataLoader = MetadataLoader();

Nostr nostr =
    Nostr("0000000000000000000000000000000000000000000000000000000000000001");
late SharedPreferences sharedPreferences;

final settingProvider = SettingProvider();
final contactListProvider = ContactListProvider();
final followEventProvider = FollowEventProvider();
final mentionMeProvider = MentionMeProvider();
final mentionMeNewProvider = MentionMeNewProvider();
final dmProvider = DMProvider();
final indexProvider = IndexProvider();
final eventReactionsProvider = EventReactionsProvider();
final noticeProvider = NoticeProvider();
final filterProvider = FilterProvider();
final linkPreviewDataProvider = LinkPreviewDataProvider();
final badgeDefinitionProvider = BadgeDefinitionProvider();
final mediaDataCache = MediaDataCache();
final pcRouterFakeProvider = PcRouterFakeProvider();
final webViewProvider = WebViewProvider();
final communityApprovedProvider = CommunityApprovedProvider();
final communityInfoProvider = CommunityInfoProvider();
final bookmarkProvider = BookmarkProvider();
final followNewEventProvider = FollowNewEventProvider();
final emojiProvider = EmojiProvider();
final badgeProvider = BadgeProvider();

bool firstLogin = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!PlatformUtil.isWeb() && PlatformUtil.isPC()) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: Base.APP_NAME,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (PlatformUtil.isWeb()) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (PlatformUtil.isWindowsOrLinux()) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  } catch (e) {
    print(e);
  }

  DB.init();

  sharedPreferences = await SharedPreferences.getInstance();

  settingProvider.init();

  contactListProvider.reload();
  contactListProvider.query();
  followEventProvider.doQuery();
  mentionMeProvider.doQuery();
  dmProvider.initDMSessions().then((_) {
    dmProvider.query();
  });
  bookmarkProvider.init();
  badgeProvider.reload();
  emojiProvider.init();
  followNewEventProvider.start();

  if (settingProvider.network != null && settingProvider.network != "") {
    var network = settingProvider.network;
    network = network!.trim();
    SocksProxy.initProxy(proxy: network);
  }

  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyApp();
  }
}

class _MyApp extends State<MyApp> {
  reload() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Color mainColor = _getMainColor();
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarColor: mainColor,
    // ));

    var lightTheme = getLightTheme();
    var darkTheme = getDarkTheme();
    ThemeData defaultTheme;
    ThemeData? defaultDarkTheme;
    if (settingProvider.themeStyle == ThemeStyle.LIGHT) {
      defaultTheme = lightTheme;
    } else if (settingProvider.themeStyle == ThemeStyle.DARK) {
      defaultTheme = darkTheme;
    } else {
      defaultTheme = lightTheme;
      defaultDarkTheme = darkTheme;
    }

    routes.addAll({
      RouterPath.INDEX: (context) => IndexRouter(reload: reload),
      RouterPath.DONATE: (context) => const DonateRouter(),
      RouterPath.USER: (context) => const UserRouter(),
      RouterPath.USER_CONTACT_LIST: (context) => const UserContactListRouter(),
      RouterPath.USER_HISTORY_CONTACT_LIST: (context) =>
          const UserHistoryContactListRouter(),
      RouterPath.USER_ZAP_LIST: (context) => const UserZapListRouter(),
      RouterPath.USER_RELAYS: (context) => const UserRelayRouter(),
      RouterPath.DM_DETAIL: (context) => const DMDetailRouter(),
      RouterPath.THREAD_DETAIL: (context) => const ThreadDetailRouter(),
      RouterPath.EVENT_DETAIL: (context) => const EventDetailRouter(),
      RouterPath.TAG_DETAIL: (context) => const TagDetailRouter(),
      RouterPath.NOTICES: (context) => const NoticeRouter(),
      RouterPath.KEY_BACKUP: (context) => const KeyBackupRouter(),
      RouterPath.RELAYS: (context) => const RelaysRouter(),
      RouterPath.FILTER: (context) => const FilterRouter(),
      RouterPath.PROFILE_EDITOR: (context) => const ProfileEditorRouter(),
      RouterPath.SETTING: (context) => SettingRouter(indexReload: reload),
      RouterPath.QRSCANNER: (context) => const QRScannerRouter(),
      RouterPath.WEBUTILS: (context) => const WebUtilsRouter(),
      RouterPath.RELAY_INFO: (context) => const RelayInfoRouter(),
      RouterPath.FOLLOWED_TAGS_LIST: (context) =>
          const FollowedTagsListRouter(),
      RouterPath.COMMUNITY_DETAIL: (context) => const CommunityDetailRouter(),
      RouterPath.FOLLOWED_COMMUNITIES: (context) =>
          const FollowedCommunitiesRouter(),
      RouterPath.FOLLOWED: (context) => const FollowedRouter(),
      RouterPath.BOOKMARK: (context) => const BookmarkRouter(),
    });

    return MultiProvider(
      providers: [
        ListenableProvider<SettingProvider>.value(
          value: settingProvider,
        ),
        ListenableProvider<RelayPool>.value(
          value: pool,
        ),
        ListenableProvider<IndexProvider>.value(
          value: indexProvider,
        ),
        ListenableProvider<ContactListProvider>.value(
          value: contactListProvider,
        ),
        ListenableProvider<FollowEventProvider>.value(
          value: followEventProvider,
        ),
        ListenableProvider<FollowNewEventProvider>.value(
          value: followNewEventProvider,
        ),
        ListenableProvider<MentionMeProvider>.value(
          value: mentionMeProvider,
        ),
        ListenableProvider<MentionMeNewProvider>.value(
          value: mentionMeNewProvider,
        ),
        ListenableProvider<DMProvider>.value(
          value: dmProvider,
        ),
        ListenableProvider<EventReactionsProvider>.value(
          value: eventReactionsProvider,
        ),
        ListenableProvider<NoticeProvider>.value(
          value: noticeProvider,
        ),
        ListenableProvider<FilterProvider>.value(
          value: filterProvider,
        ),
        ListenableProvider<LinkPreviewDataProvider>.value(
          value: linkPreviewDataProvider,
        ),
        ListenableProvider<BadgeDefinitionProvider>.value(
          value: badgeDefinitionProvider,
        ),
        ListenableProvider<PcRouterFakeProvider>.value(
          value: pcRouterFakeProvider,
        ),
        ListenableProvider<WebViewProvider>.value(
          value: webViewProvider,
        ),
        ListenableProvider<CommunityApprovedProvider>.value(
          value: communityApprovedProvider,
        ),
        ListenableProvider<CommunityInfoProvider>.value(
          value: communityInfoProvider,
        ),
        ListenableProvider<BookmarkProvider>.value(
          value: bookmarkProvider,
        ),
        ListenableProvider<EmojiProvider>.value(
          value: emojiProvider,
        ),
        ListenableProvider<BadgeProvider>.value(
          value: badgeProvider,
        ),
      ],
      child: HomeComponent(
        theme: defaultTheme,
        child: MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [
            BotToastNavigatorObserver(),
          ],
          // showPerformanceOverlay: true,
          // debugShowCheckedModeBanner: true,
          title: Base.APP_NAME,
          theme: defaultTheme,
          darkTheme: defaultDarkTheme,
          initialRoute: RouterPath.INDEX,
          routes: routes,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemTimer.run();
  }

  @override
  void dispose() {
    super.dispose();
    SystemTimer.stopTask();
  }

  ThemeData getLightTheme() {
    Color color500 = _getMainColor();
    MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    // Color? mainTextColor;
    Color hintColor = Colors.grey;
    var scaffoldBackgroundColor = Colors.grey[100];

    double baseFontSize = settingProvider.fontSize;

    var textTheme = TextTheme(
      bodyLarge: TextStyle(fontSize: baseFontSize + 2),
      bodyMedium: TextStyle(fontSize: baseFontSize),
      bodySmall: TextStyle(fontSize: baseFontSize - 2),
    );
    var titleTextStyle = TextStyle(
      color: PlatformUtil.isPC() ? Colors.black : Colors.white,
    );

    if (settingProvider.fontFamily != null) {
      textTheme =
          GoogleFonts.getTextTheme(settingProvider.fontFamily!, textTheme);
      titleTextStyle = GoogleFonts.getFont(settingProvider.fontFamily!,
          textStyle: titleTextStyle);
    }

    return ThemeData(
      platform: TargetPlatform.iOS,
      primarySwatch: themeColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColor[500]!,
        brightness: Brightness.light,
      ),
      // scaffoldBackgroundColor: Base.SCAFFOLD_BACKGROUND_COLOR,
      // scaffoldBackgroundColor: Colors.grey[100],
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: themeColor[500],
      appBarTheme: AppBarTheme(
        // color: Base.APPBAR_COLOR,
        backgroundColor:
            PlatformUtil.isPC() ? scaffoldBackgroundColor : themeColor[500],
        titleTextStyle: titleTextStyle,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: Colors.grey,
      cardColor: Colors.white,
      // dividerColor: Colors.grey[200],
      // indicatorColor: ColorsUtil.hexToColor("#818181"),
      textTheme: textTheme,
      hintColor: hintColor,
      buttonTheme: const ButtonThemeData(),
      shadowColor: Colors.black.withOpacity(0.1),
      tabBarTheme: TabBarTheme(
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[200],
      ),
    );
  }

  ThemeData getDarkTheme() {
    Color color500 = _getMainColor();
    MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    // Color? mainTextColor;
    Color? topFontColor = Colors.white;
    Color hintColor = Colors.grey;

    double baseFontSize = settingProvider.fontSize;

    var textTheme = TextTheme(
      bodyLarge: TextStyle(fontSize: baseFontSize + 2),
      bodyMedium: TextStyle(fontSize: baseFontSize),
      bodySmall: TextStyle(fontSize: baseFontSize - 2),
    );
    var titleTextStyle = TextStyle(
      color: topFontColor,
      // color: Colors.black,
    );

    if (settingProvider.fontFamily != null) {
      textTheme =
          GoogleFonts.getTextTheme(settingProvider.fontFamily!, textTheme);
      titleTextStyle = GoogleFonts.getFont(settingProvider.fontFamily!,
          textStyle: titleTextStyle);
    }

    return ThemeData(
      platform: TargetPlatform.iOS,
      primarySwatch: themeColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColor[500]!,
        brightness: Brightness.dark,
      ),
      // scaffoldBackgroundColor: Base.SCAFFOLD_BACKGROUND_COLOR,
      scaffoldBackgroundColor: ColorsUtil.hexToColor("#212121"),
      primaryColor: themeColor[500],
      appBarTheme: AppBarTheme(
        // color: Base.APPBAR_COLOR,
        backgroundColor: Colors.grey[800],
        titleTextStyle: titleTextStyle,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: Colors.grey[200],
      cardColor: Colors.grey[800],
      // indicatorColor: ColorsUtil.hexToColor("#818181"),
      textTheme: textTheme,
      hintColor: hintColor,
      shadowColor: Colors.black.withOpacity(0.1),
      tabBarTheme: TabBarTheme(
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[200],
      ),
    );
  }
}

Color _getMainColor() {
  Color color500 = const Color(0xff519495);
  if (settingProvider.themeColor != null) {
    color500 = Color(settingProvider.themeColor!);
  }
  return color500;
}
