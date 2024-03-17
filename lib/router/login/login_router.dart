import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:loure/client/nostr.dart";
import "package:loure/component/webview_router.dart";
import "package:loure/util/platform_util.dart";

import "package:loure/client/client_utils/keys.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/consts/base.dart";
import "package:loure/main.dart";

class LoginRouter extends StatefulWidget {
  const LoginRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return LoginRouterState();
  }
}

class LoginRouterState extends State<LoginRouter>
    with SingleTickerProviderStateMixin {
  bool? checkTerms = false;
  bool obscureText = true;
  TextEditingController controller = TextEditingController();

  late AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    // animation = ;
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final maxWidth = mediaDataCache.size.width;
    var mainWidth = maxWidth * 0.8;
    if (PlatformUtil.isTableMode()) {
      if (mainWidth > 550) {
        mainWidth = 550;
      }
    }

    final logoWiget = Image.asset(
      "assets/imgs/logo/logo512.png",
      width: 100,
      height: 100,
    );

    List<Widget> mainList = [];
    mainList.add(logoWiget);
    mainList.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: 40,
      ),
      child: const Text(
        Base.APP_NAME,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    final suffixIcon = GestureDetector(
      onTap: () {
        setState(() {
          obscureText = !obscureText;
        });
      },
      child: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
    );
    mainList.add(TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "nsec / hex private key",
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
    ));

    mainList.add(Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
      child: InkWell(
        onTap: doLogin,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: const Text(
            "Login",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    mainList.add(Container(
      margin: const EdgeInsets.only(bottom: 100),
      child: GestureDetector(
        onTap: generatePK,
        child: Text(
          "Generate a new private key",
          style: TextStyle(
            color: mainColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ));

    final termsWiget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
            value: checkTerms,
            onChanged: (final val) {
              setState(() {
                checkTerms = val;
              });
            }),
        const Text("I accept the "),
        GestureDetector(
          onTap: () {
            WebViewRouter.open(context, Base.PRIVACY_LINK);
          },
          child: Text(
            "Terms of Use",
            style: TextStyle(
              color: mainColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ).animate(controller: animationController, effects: [
      const ShakeEffect(),
    ]);

    return Scaffold(
      body: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            SizedBox(
              width: mainWidth,
              // color: Colors.red,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: mainList,
              ),
            ),
            Positioned(
              bottom: 20,
              child: termsWiget,
            ),
          ],
        ),
      ),
    );
  }

  void generatePK() {
    final sk = generatePrivateKey();
    controller.text = sk;
  }

  void doLogin() {
    if (checkTerms != true) {
      BotToast.showText(text: "Please accept the terms");
      animationController.reset();
      animationController.forward();
      return;
    }

    var sk = controller.text;
    if (Nip19.isPrivateKey(sk)) {
      sk = Nip19.decode(sk);
    }
    if (!keyIsValid(sk)) {
      BotToast.showText(text: "Private key is not valid");
      return;
    }
    settingProvider.addAndChangePrivateKey(sk, updateUI: false);
    nostr = Nostr(sk);

    firstLogin = true;
    indexProvider.setCurrentTap(1);

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    settingProvider.notifyListeners();
  }
}
