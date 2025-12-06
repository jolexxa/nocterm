import 'dart:io';

import 'package:nocterm/nocterm.dart' hide StdioBackend;

Future<void> runRestoreShellCommand() async {
  stdout.write(EscapeCodes.disable.values.join(''));
  stdout.write(EscapeCodes.showCursor);

  try {
    if (!stdin.echoMode) stdin.echoMode = true;
    if (!stdin.lineMode) stdin.lineMode = true;
  } catch (_) {}
}
