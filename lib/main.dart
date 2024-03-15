import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostrmo/client/nostr.dart';
import 'package:nostrmo/client/relay/relay_pool.dart';
import 'package:nostrmo/provider/badge_definition_provider.dart';
import 'package:nostrmo/provider/community_info_provider.dart';
import 'package:nostrmo/provider/follow_new_event_provider.dart';
import 'package:nostrmo/provider/mention_me_new_provider.dart';
import 'package:nostrmo/router/relays/relay_info_router.dart';
import 'package:nostrmo/router/user/followed_router.dart';
import 'package:nostrmo/router/user/followed_tags_list_router.dart';
import 'package:nostrmo/router/user/user_history_contact_list_router.dart';
import 'package:nostrmo/router/user/user_zap_list_router.dart';
import 'package:nostrmo/router/web_utils/web_utils_router.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/colors.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/consts/theme_style.dart';
import 'package:nostrmo/data/db.dart';
import 'package:nostrmo/home_component.dart';
import 'package:nostrmo/provider/badge_provider.dart';
import 'package:nostrmo/provider/community_approved_provider.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/provider/data_util.dart';
import 'package:nostrmo/provider/dm_provider.dart';
import 'package:nostrmo/provider/event_reactions_provider.dart';
import 'package:nostrmo/provider/filter_provider.dart';
import 'package:nostrmo/provider/follow_event_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/link_preview_data_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/list_set_provider.dart';
import 'package:nostrmo/provider/mention_me_provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/provider/pc_router_fake_provider.dart';
import 'package:nostrmo/provider/notice_provider.dart';
import 'package:nostrmo/provider/replaceable_event_provider.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/provider/webview_provider.dart';
import 'package:nostrmo/router/bookmark/bookmark_router.dart';
import 'package:nostrmo/router/community/community_detail_router.dart';
import 'package:nostrmo/router/dm/dm_detail_router.dart';
import 'package:nostrmo/router/donate/donate_router.dart';
import 'package:nostrmo/router/event_detail/event_detail_router.dart';
import 'package:nostrmo/router/filter/filter_router.dart';
import 'package:nostrmo/router/profile_editor/profile_editor_router.dart';
import 'package:nostrmo/router/index/index_router.dart';
import 'package:nostrmo/router/keybackup/key_backup_router.dart';
import 'package:nostrmo/router/notice/notice_router.dart';
import 'package:nostrmo/router/qrscanner/qrscanner_router.dart';
import 'package:nostrmo/router/relays/relays_router.dart';
import 'package:nostrmo/router/setting/setting_router.dart';
import 'package:nostrmo/router/tag/tag_detail_router.dart';
import 'package:nostrmo/router/thread/thread_detail_router.dart';
import 'package:nostrmo/router/user/followed_communities_router.dart';
import 'package:nostrmo/router/user/user_contact_list_router.dart';
import 'package:nostrmo/router/user/user_relays_router.dart';
import 'package:nostrmo/router/user/user_router.dart';
import 'package:nostrmo/system_timer.dart';
import 'package:nostrmo/util/colors_util.dart';
import 'package:nostrmo/util/image/cache_manager_builder.dart';
import 'package:nostrmo/util/media_data_cache.dart';
import 'package:nostrmo/util/string_util.dart';

late SharedPreferences sharedPreferences;
late SettingProvider settingProvider;
late MetadataProvider metadataProvider;
late ContactListProvider contactListProvider;
late FollowEventProvider followEventProvider;
late FollowNewEventProvider followNewEventProvider;
late MentionMeProvider mentionMeProvider;
late MentionMeNewProvider mentionMeNewProvider;
late DMProvider dmProvider;
late IndexProvider indexProvider;
late EventReactionsProvider eventReactionsProvider;
late NoticeProvider noticeProvider;
late FilterProvider filterProvider;
late LinkPreviewDataProvider linkPreviewDataProvider;
late BadgeDefinitionProvider badgeDefinitionProvider;
late MediaDataCache mediaDataCache;
late CacheManager localCacheManager;
late PcRouterFakeProvider pcRouterFakeProvider;
late Map<String, WidgetBuilder> routes;
late WebViewProvider webViewProvider;
// late CustomEmojiProvider customEmojiProvider;
late CommunityApprovedProvider communityApprovedProvider;
late CommunityInfoProvider communityInfoProvider;
late ReplaceableEventProvider replaceableEventProvider;
late BookmarkProvider bookmarkProvider;
late EmojiProvider emojiProvider;
late BadgeProvider badgeProvider;

late Nostr nostr;

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

  var dbInitTask = DB.getCurrentDatabase();
  var dataUtilTask = DataUtil.getInstance();
  var dataFutureResultList = await Future.wait([dbInitTask, dataUtilTask]);
  sharedPreferences = dataFutureResultList[1] as SharedPreferences;

  var settingTask = SettingProvider.getInstance();
  var metadataTask = MetadataProvider.getInstance();
  var futureResultList = await Future.wait([settingTask, metadataTask]);
  settingProvider = futureResultList[0] as SettingProvider;
  metadataProvider = futureResultList[1] as MetadataProvider;
  contactListProvider = ContactListProvider.getInstance();
  followEventProvider = FollowEventProvider();
  followNewEventProvider = FollowNewEventProvider();
  mentionMeProvider = MentionMeProvider();
  mentionMeNewProvider = MentionMeNewProvider();
  dmProvider = DMProvider();
  indexProvider = IndexProvider(
    indexTap: settingProvider.defaultIndex,
  );
  eventReactionsProvider = EventReactionsProvider();
  noticeProvider = NoticeProvider();
  filterProvider = FilterProvider.getInstance();
  linkPreviewDataProvider = LinkPreviewDataProvider();
  badgeDefinitionProvider = BadgeDefinitionProvider();
  mediaDataCache = MediaDataCache();
  localCacheManager = CacheManagerBuilder.build();
  pcRouterFakeProvider = PcRouterFakeProvider();
  webViewProvider = WebViewProvider();
  // customEmojiProvider = CustomEmojiProvider.load();
  communityApprovedProvider = CommunityApprovedProvider();
  communityInfoProvider = CommunityInfoProvider();
  replaceableEventProvider = ReplaceableEventProvider();
  bookmarkProvider = BookmarkProvider();
  badgeProvider = BadgeProvider();

  if (StringUtil.isNotBlank(settingProvider.network)) {
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

    routes = {
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
    };

    return MultiProvider(
      providers: [
        ListenableProvider<SettingProvider>.value(
          value: settingProvider,
        ),
        ListenableProvider<RelayPool>.value(
          value: nostr.pool,
        ),
        ListenableProvider<MetadataProvider>.value(
          value: metadataProvider,
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
        // ListenableProvider<CustomEmojiProvider>.value(
        //   value: customEmojiProvider,
        // ),
        ListenableProvider<CommunityApprovedProvider>.value(
          value: communityApprovedProvider,
        ),
        ListenableProvider<CommunityInfoProvider>.value(
          value: communityInfoProvider,
        ),
        ListenableProvider<ReplaceableEventProvider>.value(
          value: replaceableEventProvider,
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
          navigatorObservers: [BotToastNavigatorObserver()],
          // showPerformanceOverlay: true,
          debugShowCheckedModeBanner: false,
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
