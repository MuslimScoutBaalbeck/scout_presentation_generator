import 'dart:async';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final port = _resolvePort(arguments);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final clients = <WebSocket>{};
  String? latestState;
  var isClosing = false;

  stdout.writeln('Flutter Deck WebSocket server: ws://127.0.0.1:$port');

  Future<void> shutdown() async {
    if (isClosing) {
      return;
    }

    isClosing = true;

    for (final client in clients.toList(growable: false)) {
      await client.close(WebSocketStatus.goingAway, 'Server stopped');
    }

    await server.close(force: true);
  }

  ProcessSignal.sigint.watch().listen((_) => unawaited(shutdown()));
  ProcessSignal.sigterm.watch().listen((_) => unawaited(shutdown()));

  await for (final request in server) {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('Flutter Deck WebSocket server is running.');
      await request.response.close();
      continue;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    clients.add(socket);

    final state = latestState;
    if (state != null) {
      socket.add(state);
    }

    socket.listen(
      (message) {
        if (message is! String) {
          return;
        }

        latestState = message;

        for (final client in clients.toList(growable: false)) {
          if (client.readyState == WebSocket.open) {
            client.add(message);
          }
        }
      },
      onDone: () => clients.remove(socket),
      onError: (Object error, StackTrace stackTrace) {
        stderr.writeln('WebSocket client error: $error');
        clients.remove(socket);
      },
      cancelOnError: true,
    );
  }
}

int _resolvePort(List<String> arguments) {
  const defaultPort = 8080;

  for (final argument in arguments) {
    if (!argument.startsWith('--port=')) {
      continue;
    }

    return _parsePort(argument.substring('--port='.length));
  }

  final environmentPort = Platform.environment['DECK_WS_PORT'];
  if (environmentPort != null && environmentPort.isNotEmpty) {
    return _parsePort(environmentPort);
  }

  return defaultPort;
}

int _parsePort(String value) {
  final port = int.tryParse(value);

  if (port == null || port < 1 || port > 65535) {
    throw ArgumentError.value(
      value,
      'port',
      'Expected a port from 1 to 65535.',
    );
  }

  return port;
}
