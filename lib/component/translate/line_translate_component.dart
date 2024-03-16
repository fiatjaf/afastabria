import "package:flutter/material.dart";
import "package:google_mlkit_language_id/google_mlkit_language_id.dart";
import "package:google_mlkit_translation/google_mlkit_translation.dart";
import "package:provider/provider.dart";

import "package:loure/consts/base_consts.dart";
import "package:loure/main.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/cust_state.dart";

class LineTranslateComponent extends StatefulWidget {
  LineTranslateComponent(this.inlines, {super.key, this.textOnTap});
  List<dynamic> inlines;

  Function? textOnTap;

  @override
  State<StatefulWidget> createState() {
    return _LineTranslateComponent();
  }
}

class _LineTranslateComponent extends CustState<LineTranslateComponent> {
  Map<String, String> targetTextMap = {};

  String sourceText = "";

  static const double MARGIN = 4;

  TranslateLanguage? sourceLanguage;

  TranslateLanguage? targetLanguage;

  bool showSource = false;

  @override
  Widget doBuild(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    final themeData = Theme.of(context);
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    final fontSize = themeData.textTheme.bodyMedium!.fontSize;
    final iconWidgetWidth = fontSize! + 4;
    final hintColor = themeData.hintColor;

    if (isInited) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        checkAndTranslate();
      });
    }

    List<InlineSpan> spans = [];

    if (targetLanguage != null &&
        sourceLanguage != null &&
        targetTextMap.isNotEmpty) {
      // translate
      TextSpan? translateTips = TextSpan(
        text: " <- ${targetLanguage!.bcpCode} | ${sourceLanguage!.bcpCode} -> ",
        style: TextStyle(
          color: hintColor,
        ),
      );
      for (final inline in widget.inlines) {
        if (inline is String) {
          final targetInline = targetTextMap[inline];
          if (StringUtil.isNotBlank(targetInline)) {
            spans.add(TextSpan(text: "$targetInline "));

            if (showSource) {
              spans.add(translateTips);
              spans.add(TextSpan(
                text: "$inline ",
                style: TextStyle(
                  color: hintColor,
                ),
              ));
            }
          } else {
            spans.add(TextSpan(text: "$inline "));
          }
        } else {
          spans.add(WidgetSpan(child: inline));
        }
      }

      final iconBtn = WidgetSpan(
        child: GestureDetector(
          onTap: () {
            setState(() {
              showSource = !showSource;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(
              left: MARGIN,
              right: MARGIN,
            ),
            height: iconWidgetWidth,
            width: iconWidgetWidth,
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: hintColor),
              borderRadius: BorderRadius.circular(iconWidgetWidth / 2),
            ),
            child: Icon(
              Icons.translate,
              size: smallTextSize,
              color: hintColor,
            ),
          ),
        ),
      );
      spans.add(iconBtn);
    } else {
      // no translate
      for (final inline in widget.inlines) {
        if (inline is String) {
          spans.add(TextSpan(text: "$inline "));
        } else {
          spans.add(WidgetSpan(child: inline));
        }
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      onTap: () {
        if (widget.textOnTap != null) {
          widget.textOnTap!();
        }
      },
    );
  }

  @override
  Future<void> onReady(final BuildContext context) async {
    checkAndTranslate();
  }

  Future<void> checkAndTranslate() async {
    var newSourceText = "";

    for (final inline in widget.inlines) {
      if (inline is String) {
        newSourceText += inline;
      }
    }

    if (newSourceText.length > 1000) {
      return;
    }

    if (settingProvider.openTranslate != OpenStatus.OPEN) {
      // is close
      if (targetTextMap.isNotEmpty) {
        // set targetTextMap to null
        setState(() {
          targetTextMap.clear();
        });
      }
      return;
    } else {
      // is open
      // check targetTextMap
      if (targetTextMap.isNotEmpty) {
        // targetText had bean translated
        if (targetLanguage != null &&
            targetLanguage!.bcpCode == settingProvider.translateTarget &&
            newSourceText == sourceText) {
          // and currentTargetLanguage = settingTranslate
          return;
        }
      }
    }

    final translateTarget = settingProvider.translateTarget;
    if (StringUtil.isBlank(translateTarget)) {
      return;
    }
    targetLanguage = BCP47Code.fromRawValue(translateTarget!);
    if (targetLanguage == null) {
      return;
    }

    LanguageIdentifier? languageIdentifier;
    OnDeviceTranslator? onDeviceTranslator;

    sourceText = newSourceText;

    try {
      languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final List<IdentifiedLanguage> possibleLanguages =
          await languageIdentifier.identifyPossibleLanguages(newSourceText);

      if (possibleLanguages.isNotEmpty) {
        final pl = possibleLanguages[0];
        if (!settingProvider.translateSourceArgsCheck(pl.languageTag)) {
          if (targetTextMap.isNotEmpty) {
            // set targetText to null
            setState(() {
              targetTextMap.clear();
            });
          }
          return;
        }

        sourceLanguage = BCP47Code.fromRawValue(pl.languageTag);
      }

      if (sourceLanguage != null) {
        onDeviceTranslator = OnDeviceTranslator(
            sourceLanguage: sourceLanguage!, targetLanguage: targetLanguage!);

        for (final inline in widget.inlines) {
          if (inline is String) {
            final result = await onDeviceTranslator.translateText(inline);
            if (StringUtil.isNotBlank(result)) {
              targetTextMap[inline] = result;
            }
          }
        }

        setState(() {});
      }
    } finally {
      if (languageIdentifier != null) {
        languageIdentifier.close();
      }
      if (onDeviceTranslator != null) {
        onDeviceTranslator.close();
      }
    }
  }
}
