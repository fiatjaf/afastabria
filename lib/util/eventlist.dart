import "package:loure/client/event.dart";

// returns the index into which the event should be inserted, if it doesn't exist
// if it exists already, returns -1 -- using a kind of binary search
int whereToInsert(List<Event> destination, Event needle) {
  var mostRecentIdx = 0;
  var oldestIdx = destination.length;
  var midIdx = mostRecentIdx + ((oldestIdx - mostRecentIdx) >> 1);

  while (mostRecentIdx < oldestIdx) {
    midIdx = mostRecentIdx + ((oldestIdx - mostRecentIdx) >> 1);
    var element = destination[midIdx];

    if (needle.createdAt > element.createdAt) {
      oldestIdx = midIdx;
      continue;
    }
    if (needle.createdAt < element.createdAt) {
      mostRecentIdx = midIdx + 1;
      continue;
    }
    if (element.id == needle.id) {
      return -1; // we already have this element, so return -1
    }
    break; // we don't have it, but we found the best point possible
  }

  return midIdx;
}
