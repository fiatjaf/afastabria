import "package:flutter/material.dart";
import "package:google_mlkit_language_id/google_mlkit_language_id.dart";
import "package:google_mlkit_translation/google_mlkit_translation.dart";
import "package:google_mlkit_translation/src/on_device_translator.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/main.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/string_util.dart";
import "package:provider/provider.dart";

import "package:loure/component/cust_state.dart";

class TextTranslateComponent extends StatefulWidget {
  TextTranslateComponent(this.text, {super.key, this.textOnTap});
  String text;

  Function? textOnTap;

  @override
  State<StatefulWidget> createState() {
    return _TextTranslateComponent();
  }
}

class _TextTranslateComponent extends CustState<TextTranslateComponent> {
  String? sourceText;

  static const double MARGIN = 4;

  String? targetText;

  TranslateLanguage? sourceLanguage;

  TranslateLanguage? targetLanguage;

  bool showSource = false;

  @override
  Widget doBuild(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);

    if (isInited) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        checkAndTranslate();
      });
    }

    final themeData = Theme.of(context);
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    final fontSize = themeData.textTheme.bodyMedium!.fontSize;
    final iconWidgetWidth = fontSize! + 4;
    final hintColor = themeData.hintColor;

    List<InlineSpan> list = [TextSpan(text: targetText ?? widget.text)];
    if (targetLanguage != null &&
        sourceLanguage != null &&
        targetLanguage != null &&
        targetText != widget.text) {
      if (showSource) {
        list.add(
          WidgetSpan(
              child: Container(
            margin: const EdgeInsets.only(left: MARGIN),
            child: Text(
              "<- ${targetLanguage!.bcpCode}",
              style: TextStyle(
                color: hintColor,
              ),
            ),
          )),
        );
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
      list.add(iconBtn);

      if (showSource) {
        list.add(
          WidgetSpan(
              child: Container(
            margin: const EdgeInsets.only(right: MARGIN),
            child: Text(
              "${sourceLanguage!.bcpCode} ->",
              style: TextStyle(
                color: hintColor,
              ),
            ),
          )),
        );

        list.add(TextSpan(
            text: widget.text,
            style: TextStyle(
              color: hintColor,
            )));
      }
    }
    return SelectableText.rich(
      TextSpan(children: list),
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
    if (widget.text.length > 1000) {
      return;
    }

    if (settingProvider.openTranslate != OpenStatus.OPEN) {
      // is close
      if (targetText != null) {
        // set targetText to null
        setState(() {
          targetText = null;
        });
      }
      return;
    } else {
      // is open
      // check target
      if (targetText != null) {
        // targetText had bean translated
        if (targetLanguage != null &&
            targetLanguage!.bcpCode == settingProvider.translateTarget &&
            widget.text == sourceText) {
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

    try {
      languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final List<IdentifiedLanguage> possibleLanguages =
          await languageIdentifier.identifyPossibleLanguages(widget.text);

      if (possibleLanguages.isNotEmpty) {
        final pl = possibleLanguages[0];
        if (!settingProvider.translateSourceArgsCheck(pl.languageTag)) {
          if (targetText != null) {
            // set targetText to null
            setState(() {
              targetText = null;
            });
          }
          return;
        }

        sourceLanguage = BCP47Code.fromRawValue(pl.languageTag);
      }

      if (sourceLanguage != null) {
        onDeviceTranslator = OnDeviceTranslator(
            sourceLanguage: sourceLanguage!, targetLanguage: targetLanguage!);

        final result = await onDeviceTranslator.translateText(widget.text);
        if (StringUtil.isNotBlank(result)) {
          setState(() {
            targetText = result;
            sourceText = widget.text;
          });
        }
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
