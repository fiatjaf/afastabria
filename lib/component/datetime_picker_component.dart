import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:numberpicker/numberpicker.dart";
import "package:table_calendar/table_calendar.dart";

import "package:loure/consts/base.dart";
import "package:loure/util/router_util.dart";

// ignore: must_be_immutable
class DatetimePickerComponent extends StatefulWidget {
  DatetimePickerComponent({
    required this.showDate,
    required this.showHour,
    super.key,
    this.dateTime,
  });
  DateTime? dateTime;

  bool showDate;

  bool showHour;

  static Future<DateTime?> show(
    final BuildContext context, {
    final DateTime? dateTime,
    final bool showDate = true,
    final bool showHour = true,
  }) async {
    return await showDialog(
      context: context,
      builder: (final context) {
        return DatetimePickerComponent(
          dateTime: dateTime,
          showDate: showDate,
          showHour: showHour,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _DatetimePickerComponent();
  }
}

class _DatetimePickerComponent extends State<DatetimePickerComponent> {
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  int hour = 12;

  int minute = 0;

  DateTime _selectedDay = DateTime.now();

  DateTime _currentDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.dateTime != null) {
      _selectedDay = widget.dateTime!;
      hour = widget.dateTime!.hour;
      minute = widget.dateTime!.minute;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    final mainColor = themeData.appBarTheme.backgroundColor;
    final bigTextSize = themeData.textTheme.bodyLarge!.fontSize;

    final now = DateTime.now();
    final calendarFirstDay = now.add(const Duration(days: -3650));
    final calendarLastDay = now.add(const Duration(days: 3650));

    final titleDateFormat = DateFormat("MMM yyyy");

    final datePicker = Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING,
              bottom: Base.BASE_PADDING + Base.BASE_PADDING_HALF,
            ),
            child: Text(
              titleDateFormat.format(_currentDay),
              style: TextStyle(
                fontSize: bigTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TableCalendar(
            firstDay: calendarFirstDay,
            lastDay: calendarLastDay,
            focusedDay: _selectedDay,
            headerVisible: false,
            selectedDayPredicate: (final d) {
              return isSameDay(d, _selectedDay);
            },
            calendarStyle: CalendarStyle(
              rangeHighlightColor: mainColor!,
              selectedDecoration: BoxDecoration(
                color: mainColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                fontSize: 16.0,
              ),
              todayDecoration: const BoxDecoration(
                color: null,
              ),
            ),
            onDaySelected:
                (final DateTime selectedDay, final DateTime focusedDay) {
              print(selectedDay);
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            onPageChanged: (final dateTime) {
              setState(() {
                _currentDay = dateTime;
                _selectedDay = dateTime;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
        ],
      ),
    );

    final timeTitleTextStyle = TextStyle(
      fontSize: bigTextSize,
      fontWeight: FontWeight.bold,
    );
    final timePicker = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildNumberPicker("Hour", 0, 23, hour, (final value) {
          setState(() {
            hour = value;
          });
        }, timeTitleTextStyle),
        Text(
          ":",
          style: timeTitleTextStyle,
        ),
        buildNumberPicker("Minute", 0, 59, minute, (final value) {
          setState(() {
            minute = value;
          });
        }, timeTitleTextStyle),
      ],
    );

    List<Widget> mainList = [
      // datePicker,
      // timePicker,
    ];
    if (widget.showDate) {
      mainList.add(datePicker);
    }
    if (widget.showHour) {
      mainList.add(timePicker);
    }

    mainList.add(InkWell(
      onTap: confirm,
      child: Container(
        height: 40,
        color: mainColor,
        child: Center(
          child: Text(
            "Confirm",
            style: TextStyle(
              color: Colors.white,
              fontSize: bigTextSize,
            ),
          ),
        ),
      ),
    ));

    final main = Container(
      color: scaffoldBackgroundColor,
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: mainList,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // Overlay 中 textField autoFocus 需要包一层 FocusScope
        node: _focusScopeNode,
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cancelFunc,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: GestureDetector(
              // 防止误关闭了页面
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  void cancelFunc() {
    RouterUtil.back(context);
  }

  Widget buildNumberPicker(
      final String title,
      final int min,
      final int max,
      final int value,
      final Function(int) onChange,
      final TextStyle textStyle) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: textStyle,
          ),
          NumberPicker(
            itemCount: 1,
            minValue: min,
            maxValue: max,
            value: value,
            onChanged: onChange,
          )
        ],
      ),
    );
  }

  void confirm() {
    final dateTime = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour, minute);
    RouterUtil.back(context, dateTime);
  }
}
