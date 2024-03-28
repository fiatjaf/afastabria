import "dart:async";

class Debounce {
  Debounce(this.delay, this.callback, {this.immediate = false});

  final Duration delay;
  final Function() callback;
  bool immediate = false;
  Timer? _timer;

  void call() {
    _timer?.cancel();
    if (this.immediate) {
      callback();
      this.immediate = false;
    } else {
      _timer = Timer(delay, callback);
    }
  }

  void cancel() {
    _timer?.cancel();
  }
}
