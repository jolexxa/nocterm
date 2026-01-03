import 'dart:math' show max;

import 'package:nocterm/src/framework/framework.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rectangle.dart';
import 'paint_command.dart';

/// A recorded list of paint commands that can be replayed.
class DisplayList {
  final List<PaintCommand> commands;

  const DisplayList(this.commands);

  /// Create an empty display list.
  const DisplayList.empty() : commands = const [];

  /// Replay all commands to a canvas.
  void playback(TerminalCanvas canvas, [Offset offset = Offset.zero]) {
    for (final command in commands) {
      _executeCommand(command, canvas, offset);
    }
  }

  void _executeCommand(
    PaintCommand command,
    TerminalCanvas canvas,
    Offset offset,
  ) {
    switch (command) {
      case DrawTextCommand():
        canvas.drawText(
          Offset(
              command.position.dx + offset.dx, command.position.dy + offset.dy),
          command.text,
          style: command.style,
        );
      case FillRectCommand():
        canvas.fillRect(
          Rect.fromLTWH(
            command.rect.left + offset.dx,
            command.rect.top + offset.dy,
            command.rect.width,
            command.rect.height,
          ),
          command.char,
          style: command.style,
        );
      case SetCellCommand():
        canvas.drawText(
          Offset(command.x.toDouble() + offset.dx,
              command.y.toDouble() + offset.dy),
          command.char,
          style: command.style,
        );
      case ClipCommand():
        final clippedCanvas = canvas.clip(
          Rect.fromLTWH(
            command.clipRect.left + offset.dx,
            command.clipRect.top + offset.dy,
            command.clipRect.width,
            command.clipRect.height,
          ),
        );
        for (final child in command.children) {
          _executeCommand(child, clippedCanvas, Offset.zero);
        }
    }
  }

  /// Find regions that changed compared to a previous display list.
  Set<Rect> diff(DisplayList previous) {
    final dirtyRegions = <Rect>{};

    final maxLen = max(commands.length, previous.commands.length);
    for (int i = 0; i < maxLen; i++) {
      final prev = i < previous.commands.length ? previous.commands[i] : null;
      final curr = i < commands.length ? commands[i] : null;

      if (prev != curr) {
        // Command changed - mark both old and new bounds as dirty
        if (prev != null) dirtyRegions.add(prev.bounds);
        if (curr != null) dirtyRegions.add(curr.bounds);
      }
    }

    return dirtyRegions;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DisplayList) return false;
    if (commands.length != other.commands.length) return false;
    for (int i = 0; i < commands.length; i++) {
      if (commands[i] != other.commands[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(commands);
}
