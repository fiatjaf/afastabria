import "dart:isolate";

import "package:flutter_socks_proxy/socks_proxy.dart";
import "package:loure/util/string_util.dart";
import "package:web_socket_channel/web_socket_channel.dart";

import "package:loure/client/relay/relay_isolate.dart";

class RelayIsolateWorker {
  RelayIsolateWorker({
    required this.config,
  });
  RelayIsolateConfig config;
  WebSocketChannel? wsChannel;

  Future<void> run() async {
    if (StringUtil.isNotBlank(config.network)) {
      // handle isolate network
      var network = config.network;
      network = network!.trim();
      SocksProxy.initProxy(proxy: network);
    }

    final ReceivePort mainToSubReceivePort = ReceivePort();
    final mainToSubSendPort = mainToSubReceivePort.sendPort;
    config.subToMainSendPort.send(mainToSubSendPort);

    mainToSubReceivePort.listen((final message) async {
      if (message is String) {
        // this is the msg need to sended.
        if (wsChannel != null) {
          wsChannel!.sink.add(message);
        }
      } else if (message is int) {
        // this is const msg.
        // print("msg is $message ${config.url}");
        if (message == RelayIsolateMsgs.CONNECT) {
          // print("${config.url} worker receive connect command");
          // receive the connect command!
          if (wsChannel == null || wsChannel!.closeCode != null) {
            // the websocket is close, close again and try to connect.
            _closeWS(wsChannel);
            // print("${config.url} worker connect again");
            wsChannel = await handleWS();
          } else {
            // print("${config.url} worker send ping");
            // wsChannel!.sink.add("ping");
            // TODO the websocket is connected, try to check or reconnect.
          }
        } else if (message == RelayIsolateMsgs.DIS_CONNECT) {
          _closeWS(wsChannel);
          config.subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
        }
      }
    });

    wsChannel = await handleWS();
  }

  static void runRelayIsolate(final RelayIsolateConfig config) {
    final worker = RelayIsolateWorker(config: config);
    worker.run();
  }

  Future<WebSocketChannel?> handleWS() async {
    final String url = config.url;
    final SendPort subToMainSendPort = config.subToMainSendPort;

    final wsUrl = Uri.parse(url);
    try {
      print("Begin to connect ${config.url}");
      wsChannel = WebSocketChannel.connect(wsUrl);
      wsChannel!.stream.listen(subToMainSendPort.send,
          onError: (final error) async {
        _closeWS(wsChannel);
        wsChannel = null;
        subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
      }, onDone: () {
        print("Websocket stream closed by remote:  $url");
        _closeWS(wsChannel);
        subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
      });
      await wsChannel!.ready;
      print("Connect complete! ${config.url}");
      subToMainSendPort.send(RelayIsolateMsgs.CONNECTED);

      return wsChannel;
    } catch (e) {
      _closeWS(wsChannel);
      subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
    }

    return null;
  }

  bool _closeWS(WebSocketChannel? wsChannel) {
    if (wsChannel == null) {
      return false;
    }

    try {
      wsChannel.sink.close();
    } catch (e) {
      print("ws close error ${e.toString()}");
    }

    wsChannel = null;
    return true;
  }
}
