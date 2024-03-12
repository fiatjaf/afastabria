import 'package:shared_preferences/shared_preferences.dart';

class DataUtil {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> getInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}

class DataKey {
  static const String SETTING = "setting";

  // static final String RELAYS = "relays";

  static const String CONTACT_LISTS = "contactLists";

  // static final String CONTACT_LIST = "contactList";

  // static final String RELAY_LIST = "relayList";

  // static final String RELAY_UPDATED_TIME = "relayUpdatedTime";

  static const String BLOCK_LIST = "blockList";

  static const String DIRTYWORD_LIST = "dirtywordList";

  static const String CUSTOM_EMOJI_LIST = "customEmojiList";
}
