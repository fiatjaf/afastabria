mixin WhenStopFunction {
  bool _WhenStopRunning = true;

  int whenStopMS = 200;

  int stopTime = 0;

  bool waitingStop = false;

  void whenStop(final Function func) {
    _updateStopTime();
    if (!waitingStop) {
      waitingStop = true;
      _goWaitForStop(func);
    }
  }

  void _updateStopTime() {
    stopTime = DateTime.now().millisecondsSinceEpoch + whenStopMS;
  }

  void _goWaitForStop(final Function func) {
    Future.delayed(Duration(milliseconds: whenStopMS), () {
      if (!_WhenStopRunning) {
        return;
      }

      final nowMS = DateTime.now().millisecondsSinceEpoch;
      if (nowMS >= stopTime) {
        waitingStop = false;
        func();
      } else {
        _goWaitForStop(func);
      }
    });
  }

  void disposeWhenStop() {
    _WhenStopRunning = false;
  }
}
