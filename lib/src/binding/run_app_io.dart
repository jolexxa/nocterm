import 'dart:async';
import 'dart:io';

import 'package:nocterm/nocterm.dart'
    hide StdioBackend, SocketBackend, WebBackend;
import 'package:nocterm/src/backend/socket_backend.dart';
import 'package:nocterm/src/backend/stdio_backend.dart';
import 'package:nocterm/src/backend/terminal.dart' as term;

/// Run a TUI application on native platforms (Linux, macOS, Windows).
Future<void> runAppImpl(Component app, {bool enableHotReload = true}) async {
  await _AppRunner(app, enableHotReload: enableHotReload).run();
}

class _AppRunner {
  _AppRunner(this.app, {this.enableHotReload = true})
      : _cleanUp = _CleanUp(),
        _logServer = LogServer();

  final Component app;
  final bool enableHotReload;
  final _CleanUp _cleanUp;
  final LogServer _logServer;

  bool _initialized = false;
  Future<void> _initialize() async {
    if (_initialized) return;

    _cleanUp.add(_logServer.close);

    _binding = switch (shellMode) {
      true => await _socketBackend(),
      false => _stdBackend(),
    };

    _cleanUp.add(() async {
      if (!binding.shouldExit) {
        binding.shutdown();
      }
    });

    try {
      await _logServer.start();
      _logger = Logger(logServer: _logServer);
      _cleanUp.add(logger.close);
    } catch (e) {
      _logger = Logger();
      if (shellMode) {
        stderr.writeln('Failed to start log server: $e');
      }
    }

    _initialized = true;
  }

  Logger? _logger;
  Logger get logger {
    if (_logger case final logger?) {
      return logger;
    }

    throw StateError('Logger not initialized');
  }

  bool? _shellMode;
  bool get shellMode {
    if (_shellMode case final mode?) {
      return mode;
    }
    if (!shellHandleFile.existsSync()) {
      return _shellMode = false;
    }

    final socketPath = shellHandleFile.readAsStringSync().trim();
    if (socketPath.isEmpty) {
      return _shellMode = false;
    }

    return _shellMode = File(socketPath).existsSync();
  }

  File? _shellHandleFile;
  File get shellHandleFile => switch (_shellHandleFile) {
        final file? => file,
        _ => _shellHandleFile = File(getShellHandlePath()),
      };

  TerminalBinding? _binding;
  TerminalBinding get binding => switch (_binding) {
        final binding? => binding,
        null => throw StateError('Socket backend not initialized'),
      };

  TerminalBinding _stdBackend() {
    final backend = StdioBackend();
    final terminal = term.Terminal(backend);
    final binding = TerminalBinding(terminal);
    _cleanUp.add(() async {
      if (!binding.shouldExit) {
        binding.shutdown();
      }
    });
    return binding;
  }

  Future<TerminalBinding> _socketBackend() async {
    final socketPath = await shellHandleFile.readAsString();

    if (socketPath.isEmpty) {
      throw StateError('Shell handle file is empty');
    }

    if (!File(socketPath).existsSync()) {
      throw StateError('Shell socket file does not exist: $socketPath');
    }

    final socket = await Socket.connect(
      InternetAddress(socketPath.trim(), type: InternetAddressType.unix),
      0,
    );

    final backend = SocketBackend(socket);
    final terminal = term.Terminal(backend);
    final binding = TerminalBinding(terminal);
    _cleanUp.add(() async {
      if (!binding.shouldExit) {
        binding.shutdown();
      }
    });

    _cleanUp.add(() async {
      socket.destroy();
    });

    return binding;
  }

  bool _running = false;

  Future<void> run() async {
    if (_running) return;

    _running = true;
    await _initialize();

    try {
      final binding = this.binding;

      await runZoned(
        () async {
          binding.initialize();
          binding.attachRootComponent(app);

          if (enableHotReload && !bool.fromEnvironment('dart.vm.product')) {
            await binding.initializeHotReload();
          }

          await binding.runEventLoop();
        },
        zoneSpecification: ZoneSpecification(
          print: (
            Zone self,
            ZoneDelegate parent,
            Zone zone,
            String message,
          ) {
            logger.log(message);
            parent.print(zone, message);
          },
          handleUncaughtError: (
            Zone self,
            ZoneDelegate parent,
            Zone zone,
            Object error,
            StackTrace stackTrace,
          ) {
            final errorMessage = 'ERROR: $error\n$stackTrace';
            logger.log(errorMessage);
            if (shellMode) {
              stderr.writeln(errorMessage);
            }
          },
        ),
      );
    } catch (e) {
      if (shellMode) {
        stderr.writeln('Shell mode error: $e');
      }
    } finally {
      await _cleanUp.cleanup();
    }
  }
}

class _CleanUp {
  _CleanUp();

  late final List<Future<void> Function()> _fns = [];

  void add(Future<void> Function() fn) {
    _fns.add(fn);
  }

  Future<void> cleanup() async {
    for (final fn in _fns) {
      await fn().catchError((e) {
        stderr.writeln('Error during cleanup: $e');
      });
    }
  }
}
