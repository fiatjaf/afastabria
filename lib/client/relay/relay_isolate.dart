import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:nostrmo/main.dart';
import 'package:nostrmo/client/event.dart';

import 'package:nostrmo/client/relay/relay.dart';
import 'package:nostrmo/client/relay/relay_isolate_worker.dart';

// The real relay, which is run in other isolate.
// It can move jsonDecode and event id check and sign check from main Isolate
class RelayIsolate extends Relay {
  RelayIsolate(
    String url,
    RelayStatus relayStatus, {
    bool assumeValid = true,
    Event Function(List<List<String>>)? makeAuthEvent,
  }) : super(url, relayStatus, assumeValid, makeAuthEvent);

  Isolate? isolate;
  ReceivePort? subToMainReceivePort;
  SendPort? mainToSubSendPort;
  Completer<bool>? relayConnectResultComplete;

  @override
  Future<bool> doConnect() async {
    if (subToMainReceivePort == null) {
      relayStatus.connected = ConnState.CONNECTING;
      getRelayInfo(url);

      // never run isolate, begin to run
      subToMainReceivePort = ReceivePort("relay_stm_$url");
      subToMainListener(subToMainReceivePort!);

      relayConnectResultComplete = Completer();
      isolate = await Isolate.spawn(
        RelayIsolateWorker.runRelayIsolate,
        RelayIsolateConfig(
          url: url,
          subToMainSendPort: subToMainReceivePort!.sendPort,
          network: settingProvider.network,
        ),
      );
      // isolate has run and return a completer.future, wait for subToMain msg to complete this completer.
      return relayConnectResultComplete!.future;
    } else {
      // the isolate had bean run
      if (relayStatus.connected == ConnState.CONNECTED) {
        // relay has bean connected, return true, but also send a connect message.
        mainToSubSendPort!.send(RelayIsolateMsgs.CONNECT);
        return true;
      } else {
        // haven't connected
        if (relayConnectResultComplete != null) {
          return relayConnectResultComplete!.future;
        } else {
          // this maybe relay had disconnect after connected, try to connected again.
          if (mainToSubSendPort != null) {
            relayStatus.connected = ConnState.CONNECTING;
            // send connect msg
            mainToSubSendPort!.send(RelayIsolateMsgs.CONNECT);
            // wait connected msg.
            relayConnectResultComplete = Completer();
            return relayConnectResultComplete!.future;
          }
        }
      }
    }

    return false;
  }

  @override
  Future<void> disconnect() async {
    if (relayStatus.connected != ConnState.UN_CONNECT) {
      relayStatus.connected = ConnState.UN_CONNECT;
      if (mainToSubSendPort != null) {
        mainToSubSendPort!.send(RelayIsolateMsgs.DIS_CONNECT);
      }
    }
  }

  @override
  send(List message) {
    if (mainToSubSendPort != null &&
        relayStatus.connected == ConnState.CONNECTED) {
      final encoded = jsonEncode(message);
      // print(encoded);
      mainToSubSendPort!.send(encoded);
    }
  }

  void subToMainListener(ReceivePort receivePort) {
    receivePort.listen((message) {
      if (message is int) {
        // this is const msg.
        // print("msg is $message $url");
        if (message == RelayIsolateMsgs.CONNECTED) {
          // print("$url receive connected status!");
          relayStatus.connected = ConnState.CONNECTED;
          relayStatusCallback!();
          _relayConnectComplete(true);
        } else if (message == RelayIsolateMsgs.DIS_CONNECTED) {
          onError("Websocket error $url", reconnect: true);
          _relayConnectComplete(false);
        }
      } else if (message is String) {
        onMessage(jsonDecode(message));
      } else if (message is SendPort) {
        mainToSubSendPort = message;
      }
    });
  }

  void _relayConnectComplete(bool result) {
    if (relayConnectResultComplete != null) {
      relayConnectResultComplete!.complete(result);
      relayConnectResultComplete = null;
    }
  }

  @override
  void dispose() {
    if (isolate != null) {
      isolate!.kill();
    }
  }
}

class RelayIsolateConfig {
  final String url;
  final SendPort subToMainSendPort;
  String? network;

  RelayIsolateConfig({
    required this.url,
    required this.subToMainSendPort,
    this.network,
  });
}

class RelayIsolateMsgs {
  static const int CONNECT = 1;
  static const int DIS_CONNECT = 2;
  static const int CONNECTED = 101;
  static const int DIS_CONNECTED = 102;
}
