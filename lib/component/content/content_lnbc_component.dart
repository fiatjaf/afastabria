import "package:flutter/material.dart";
import "package:loure/util/lightning_util.dart";

import "package:loure/client/zap/zap_num_util.dart";
import "package:loure/consts/base.dart";

class ContentLnbcComponent extends StatelessWidget {
  ContentLnbcComponent({required this.lnbc, super.key});
  String lnbc;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final cardColor = themeData.cardColor;
    const double largeFontSize = 20;

    var numStr = "Any";
    final num = ZapNumUtil.getNumFromStr(lnbc);
    if (num > 0) {
      numStr = num.toString();
    }

    return Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING),
      padding: const EdgeInsets.all(Base.BASE_PADDING * 2),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 0),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(bottom: Base.BASE_PADDING),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: hintColor,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.orange,
                  ),
                ),
                const Text("Lightning Invoice"),
              ],
            ),
          ),
          // Container(
          //   alignment: Alignment.bottomLeft,
          //   padding: EdgeInsets.only(top: Base.BASE_PADDING),
          //   child: Text("Wallet of Satoshi"),
          // ),
          Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING,
              bottom: Base.BASE_PADDING,
            ),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
                  child: Text(
                    numStr,
                    style: const TextStyle(
                      fontSize: largeFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Text(
                  "sats",
                  style: TextStyle(
                    fontSize: largeFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: InkWell(
              onTap: () async {
                // call to pay
                LightningUtil.goToPay(context, lnbc);
              },
              child: Container(
                color: Colors.black,
                height: 50,
                alignment: Alignment.center,
                child: const Text(
                  "Pay",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
