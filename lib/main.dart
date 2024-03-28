import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:flutter_socks_proxy/socks_proxy.dart";
import "package:google_fonts/google_fonts.dart";
import "package:loure/client/metadata.dart";
import "package:loure/client/nip02/contact_list.dart";
import "package:loure/client/nip65/relay_list.dart";
import "package:loure/client/replaceable_loader.dart";
import "package:loure/router/routes.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:sqflite_common_ffi_web/sqflite_ffi_web.dart";
import "package:window_manager/window_manager.dart";

import "package:loure/client/following.dart";
import "package:loure/client/nostr.dart";
import "package:loure/client/relay/relay_pool.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/colors.dart";
import "package:loure/consts/theme_style.dart";
import "package:loure/data/db.dart";
import "package:loure/home_component.dart";
import "package:loure/provider/badge_definition_provider.dart";
import "package:loure/provider/badge_provider.dart";
import "package:loure/provider/community_approved_provider.dart";
import "package:loure/provider/community_info_provider.dart";
import "package:loure/provider/contact_list_provider.dart";
import "package:loure/provider/dm_provider.dart";
import "package:loure/provider/event_reactions_provider.dart";
import "package:loure/provider/filter_provider.dart";
import "package:loure/provider/index_provider.dart";
import "package:loure/provider/link_preview_data_provider.dart";
import "package:loure/provider/list_provider.dart";
import "package:loure/provider/mention_me_new_provider.dart";
import "package:loure/provider/mention_me_provider.dart";
import "package:loure/provider/notice_provider.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/provider/webview_provider.dart";
import "package:loure/system_timer.dart";
import "package:loure/util/colors_util.dart";
import "package:loure/util/media_data_cache.dart";
import "package:loure/util/platform_util.dart";

final RelayPool pool = RelayPool();
final metadataLoader = ReplaceableLoader(
  dbname: "metadata",
  read: Metadata.fromEvent,
  blank: Metadata.blank,
  thresholdDelta: const Duration(days: 3),
  baseRelays: nostr.METADATA_RELAYS,
  kind: 0,
  queryId: "load-metadata",
);
final relaylistLoader = ReplaceableLoader(
  dbname: "relaylist",
  read: RelayList.fromEvent,
  blank: RelayList.blank,
  deflt: (final String key) => RelayList(key, [
    "wss://relay.damus.io",
    "wss://nostr.wine",
    "wss://nos.lol"
  ], [
    "wss://relay.damus.io",
    "wss://nos.lol",
    "wss://nostr.einundzwanzig.space",
    "wss://yabu.me",
    "wss://relay.siamstr.com"
  ]),
  thresholdDelta: const Duration(days: 7),
  baseRelays: nostr.RELAYLIST_RELAYS,
  kind: 10002,
  queryId: "load-relaylist",
);
final contactListLoader = ReplaceableLoader(
  dbname: "contactlist",
  read: ContactList.fromEvent,
  blank: ContactList.blank,
  thresholdDelta: const Duration(days: 14),
  baseRelays: nostr.CONTACT_RELAYS,
  kind: 3,
  queryId: "load-cl",
);

Nostr nostr = Nostr.empty();
late SharedPreferences sharedPreferences;

final followingManager = FollowingManager();
final internalRouter = InternalRouter();

final settingProvider = SettingProvider();
final contactListProvider = ContactListProvider();
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
final webViewProvider = WebViewProvider();
final communityApprovedProvider = CommunityApprovedProvider();
final communityInfoProvider = CommunityInfoProvider();
final bookmarkProvider = BookmarkProvider();
final emojiProvider = EmojiProvider();
final badgeProvider = BadgeProvider();

bool firstLogin = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!PlatformUtil.isWeb() && PlatformUtil.isPC()) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
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

  await DB.init();

  sharedPreferences = await SharedPreferences.getInstance();

  await settingProvider.init();

  final sk = await settingProvider.privateKey();
  if (sk != null) {
    nostr = Nostr(sk);
  }

  followingManager.init();

  contactListProvider.init();
  mentionMeProvider.doQuery();
  dmProvider.initDMSessions().then((final _) {
    dmProvider.query();
  });
  bookmarkProvider.init();
  badgeProvider.reload();
  emojiProvider.init();

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
  Widget build(final BuildContext context) {
    // Color mainColor = _getMainColor();
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarColor: mainColor,
    // ));

    final lightTheme = getLightTheme();
    final darkTheme = getDarkTheme();
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
          onGenerateRoute: (RouteSettings rs) {
            return MaterialPageRoute(
              settings: rs,
              builder: (_) => renderWidget(rs),
            );
          },
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
    final Color color500 = _getMainColor();
    final MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    // Color? mainTextColor;
    const Color hintColor = Colors.grey;
    final scaffoldBackgroundColor = Colors.grey[100];

    final double baseFontSize = settingProvider.fontSize;

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
    final Color color500 = _getMainColor();
    final MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    // Color? mainTextColor;
    const Color topFontColor = Colors.white;
    const Color hintColor = Colors.grey;

    final double baseFontSize = settingProvider.fontSize;

    var textTheme = TextTheme(
      bodyLarge: TextStyle(fontSize: baseFontSize + 2),
      bodyMedium: TextStyle(fontSize: baseFontSize),
      bodySmall: TextStyle(fontSize: baseFontSize - 2),
    );
    var titleTextStyle = const TextStyle(
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
