import 'dart:io';

import 'package:args/args.dart';
import 'package:nocterm_cli/commands/shell_command.dart';
import 'package:nocterm_cli/commands/logs_command.dart';
import 'package:nocterm_cli/commands/run_command.dart';

void main(List<String> arguments) async {
  final parser =
      ArgParser()
        ..addCommand(
          'shell',
          ArgParser()..addFlag('help', abbr: 'h', help: 'Show help'),
        )
        ..addCommand(
          'logs',
          ArgParser()..addFlag('help', abbr: 'h', help: 'Show help'),
        )
        ..addCommand(
          'run',
          ArgParser()..addFlag('help', abbr: 'h', help: 'Show help'),
        );

  try {
    final results = parser.parse(arguments);

    if (results.command == null) {
      _printUsage(parser);
      exit(1);
    }

    final command = results.command!;

    switch (command.name) {
      case 'shell':
        if (command['help'] as bool) {
          print('Usage: nocterm shell');
          print('');
          print(
            'Start a nocterm shell server that nocterm apps can render into.',
          );
          print(
            'This allows running nocterm apps from IDEs with debugger support.',
          );
          exit(0);
        }
        await runShellCommand();
        break;
      case 'logs':
        if (command['help'] as bool) {
          print('Usage: nocterm logs');
          print('');
          print('Stream logs from a running nocterm app via WebSocket.');
          print('Logs are displayed in real-time. Press Ctrl+C to exit.');
          exit(0);
        }
        await runLogsCommand();
        break;
      case 'run':
        if (command['help'] as bool) {
          print('Usage: nocterm run dart <script.dart> [arguments]');
          print('');
          print(
            'Run a Dart script with --enable-vm-service automatically added.',
          );
          print('This enables VM service for debugging and profiling.');
          print('');
          print('Example: nocterm run dart lib/main.dart');
          exit(0);
        }
        await runRunCommand(command.rest);
        break;
      default:
        _printUsage(parser);
        exit(1);
    }
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print('');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('nocterm CLI - Tools for nocterm TUI framework');
  print('');
  print('Usage: nocterm <command> [arguments]');
  print('');
  print('Available commands:');
  print('  shell    Start a nocterm shell server for debugging');
  print('  logs     Stream logs from a running nocterm app');
  print('  run      Run a Dart script with VM service enabled');
  print('');
  print('Run "nocterm <command> --help" for more information about a command.');
}
