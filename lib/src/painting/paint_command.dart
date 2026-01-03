import 'package:nocterm/src/framework/framework.dart';
import 'package:nocterm/src/rectangle.dart';
import 'package:nocterm/src/style.dart';

/// Base class for all paint commands in a display list.
sealed class PaintCommand {
  const PaintCommand();

  /// The bounding rectangle affected by this command.
  Rect get bounds;
}

/// Draws text at a position.
class DrawTextCommand extends PaintCommand {
  final Offset position;
  final String text;
  final TextStyle? style;

  const DrawTextCommand(this.position, this.text, {this.style});

  @override
  Rect get bounds => Rect.fromLTWH(
        position.dx,
        position.dy,
        text.length.toDouble(),
        1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawTextCommand &&
          _offsetEquals(position, other.position) &&
          text == other.text &&
          style == other.style;

  @override
  int get hashCode => Object.hash(position.dx, position.dy, text, style);
}

/// Fills a rectangle with a single character.
class FillRectCommand extends PaintCommand {
  final Rect rect;
  final String char;
  final TextStyle? style;

  const FillRectCommand(this.rect, this.char, {this.style});

  @override
  Rect get bounds => rect;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FillRectCommand &&
          _rectEquals(rect, other.rect) &&
          char == other.char &&
          style == other.style;

  @override
  int get hashCode => Object.hash(
        rect.left,
        rect.top,
        rect.width,
        rect.height,
        char,
        style,
      );
}

/// Sets a single cell directly.
class SetCellCommand extends PaintCommand {
  final int x;
  final int y;
  final String char;
  final TextStyle style;

  const SetCellCommand(this.x, this.y, this.char, this.style);

  @override
  Rect get bounds => Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetCellCommand &&
          x == other.x &&
          y == other.y &&
          char == other.char &&
          style == other.style;

  @override
  int get hashCode => Object.hash(x, y, char, style);
}

/// A group of commands within a clipped region.
class ClipCommand extends PaintCommand {
  final Rect clipRect;
  final List<PaintCommand> children;

  const ClipCommand(this.clipRect, this.children);

  @override
  Rect get bounds => clipRect;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClipCommand) return false;
    if (!_rectEquals(clipRect, other.clipRect)) return false;
    if (children.length != other.children.length) return false;
    for (int i = 0; i < children.length; i++) {
      if (children[i] != other.children[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        clipRect.left,
        clipRect.top,
        clipRect.width,
        clipRect.height,
        Object.hashAll(children),
      );
}

/// Helper to compare Offsets (they may not have == defined).
bool _offsetEquals(Offset a, Offset b) => a.dx == b.dx && a.dy == b.dy;

/// Helper to compare Rects (they may not have == defined).
bool _rectEquals(Rect a, Rect b) =>
    a.left == b.left &&
    a.top == b.top &&
    a.width == b.width &&
    a.height == b.height;
