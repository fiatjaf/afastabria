import "package:loure/client/event.dart";

class ThreadDetailEvent {
  ThreadDetailEvent({required this.event});
  Event event;

  int totalLevelNum = 1;

  int currentLevel = 1;

  int handleTotalLevelNum(final int preLevel) {
    currentLevel = preLevel + 1;

    if (subItems.isEmpty) {
      return 1;
    }
    var maxSubLevelNum = 0;
    for (final subItem in subItems) {
      final subLevelNum = subItem.handleTotalLevelNum(currentLevel);
      if (subLevelNum > maxSubLevelNum) {
        maxSubLevelNum = subLevelNum;
      }
    }

    totalLevelNum = maxSubLevelNum + 1;
    return totalLevelNum;
  }

  List<ThreadDetailEvent> subItems = [];
}
