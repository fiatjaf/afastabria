import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import 'package:nostrmo/component/appbar4stack.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/coffee_ids.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

class DonateRouter extends StatefulWidget {
  const DonateRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DonateRouter();
  }
}

class _DonateRouter extends CustState<DonateRouter> {
  @override
  Widget doBuild(BuildContext context) {
    
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;

    Color? appbarBackgroundColor = Colors.transparent;
    var appBar = Appbar4Stack(
      backgroundColor: appbarBackgroundColor,
      title: const Text(
        "Donate",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    List<Widget> list = [];
    list.add(Container(
      child: const Icon(
        Icons.coffee_outlined,
        size: 160,
        // color: mainColor,
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        bottom: 40,
      ),
      child: const Text("Buy me a coffee!"),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DonateBtn(
            name: "X1",
            onTap: () {
              buy(CoffeeIds.COFFEE1);
            },
            price: price1,
          ),
          DonateBtn(
            name: "X2",
            onTap: () {
              buy(CoffeeIds.COFFEE2);
            },
            price: price2,
          ),
        ],
      ),
    ));

    list.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DonateBtn(
          name: "X5",
          onTap: () {
            buy(CoffeeIds.COFFEE5);
          },
          price: price5,
        ),
        DonateBtn(
          name: "X10",
          onTap: () {
            buy(CoffeeIds.COFFEE2);
          },
          price: price10,
        ),
      ],
    ));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mediaDataCache.size.width,
            height: mediaDataCache.size.height - mediaDataCache.padding.top,
            margin: EdgeInsets.only(top: mediaDataCache.padding.top),
            child: Container(
              color: cardColor,
              child: Center(
                child: SizedBox(
                  width: mediaDataCache.size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: list,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: mediaDataCache.padding.top,
            child: SizedBox(
              width: mediaDataCache.size.width,
              child: appBar,
            ),
          ),
        ],
      ),
    );
  }

  String price1 = "";
  String price2 = "";
  String price5 = "";
  String price10 = "";

  Future<void> updateIAPItems() async {
    var list = await FlutterInappPurchase.instance.getProducts([
      CoffeeIds.COFFEE1,
      CoffeeIds.COFFEE2,
      CoffeeIds.COFFEE5,
      CoffeeIds.COFFEE10
    ]);
    print(list);
    for (var item in list) {
      if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE1) {
        price1 = item.localizedPrice!;
      } else if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE2) {
        price2 = item.localizedPrice!;
      } else if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE5) {
        price5 = item.localizedPrice!;
      } else if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE10) {
        price10 = item.localizedPrice!;
      }
    }
    setState(() {});
  }

  Future<void> buy(String id) async {
    await FlutterInappPurchase.instance.requestPurchase(id);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    updateIAPItems();
  }
}

class DonateBtn extends StatelessWidget {
  String name;

  Function onTap;

  String price;

  DonateBtn({
    super.key,
    required this.name,
    required this.onTap,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var textColor = themeData.textTheme.bodyMedium!.color;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    return Container(
      margin: const EdgeInsets.only(
        left: 30,
        right: 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              onTap();
            },
            style: ButtonStyle(
              side: MaterialStateProperty.all(BorderSide(
                width: 1,
                color: hintColor.withOpacity(0.4),
              )),
            ),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: largeTextSize,
                  color: textColor,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
            child: Text(price),
          ),
        ],
      ),
    );
  }
}
