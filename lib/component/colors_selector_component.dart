import "package:flutter/material.dart";

import "package:loure/consts/base.dart";
import "package:loure/consts/colors.dart";
import "package:loure/util/router_util.dart";

class ColorSelectorComponent extends StatelessWidget {
  const ColorSelectorComponent({super.key});

  static Future<Color?> show(final BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (final context) {
        return const ColorSelectorComponent();
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);

    List<Widget> widgets = [];
    for (var i = 0; i < ColorList.ALL_COLOR.length; i++) {
      final c = ColorList.ALL_COLOR[i];
      widgets.add(SliverToBoxAdapter(
        child: ColorSelectorItemComponent(
          color: c,
          // isLast: i == ColorList.ALL_COLOR.length - 1,
        ),
      ));
    }

    final Widget main = Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.white,
        ),
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: widgets,
        ));

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}

class ColorSelectorItemComponent extends StatelessWidget {
  // final bool isLast;

  const ColorSelectorItemComponent({
    required this.color,
    super.key,
    // this.isLast = false,
  });
  static const double HEIGHT = 44;

  final Color color;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final dividerColor = themeData.dividerColor;

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context, color);
      },
      child: Container(
        // decoration: BoxDecoration(
        //     border: isLast
        //         ? null
        //         : Border(bottom: BorderSide(color: dividerColor))),
        margin: const EdgeInsets.all(Base.BASE_PADDING),
        alignment: Alignment.center,
        height: HEIGHT,
        child: Container(
          height: HEIGHT,
          width: HEIGHT,
          color: color,
        ),
      ),
    );
  }
}
