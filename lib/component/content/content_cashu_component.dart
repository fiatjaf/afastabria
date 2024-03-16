import "package:flutter/material.dart";
import "package:loure/client/cashu/cashu_tokens.dart";
import "package:loure/util/colors_util.dart";

import "package:loure/consts/base.dart";
import "package:loure/util/cashu_util.dart";

class ContentCashuComponent extends StatelessWidget {
  ContentCashuComponent({
    required this.tokens,
    required this.cashuStr,
    super.key,
  });
  String cashuStr;

  Tokens tokens;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final cardColor = themeData.cardColor;
    const double largeFontSize = 20;

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
            margin: const EdgeInsets.only(
              bottom: 15,
            ),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: Base.BASE_PADDING),
                  child: Image.asset(
                    "assets/imgs/cashu_logo.png",
                    width: 50,
                    height: 50,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                                right: Base.BASE_PADDING_HALF),
                            child: Text(
                              tokens.totalAmount().toString(),
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
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Text(
                        tokens.memo != null ? tokens.memo! : "",
                        style: TextStyle(color: hintColor),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: InkWell(
              onTap: () async {
                // call to pay
                CashuUtil.goTo(context, cashuStr);
              },
              child: Container(
                color: ColorsUtil.hexToColor("#dcc099"),
                height: 42,
                alignment: Alignment.center,
                child: const Text(
                  "Claim",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
