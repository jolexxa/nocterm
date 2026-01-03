import 'package:nocterm/src/framework/framework.dart';
import 'package:nocterm/src/framework/terminal_canvas.dart';
import 'package:nocterm/src/rectangle.dart';
import 'package:nocterm/src/style.dart';
import 'display_list.dart';
import 'paint_command.dart';

/// A canvas that records paint operations into a DisplayList instead of
/// painting directly to a buffer.
class RecordingCanvas implements TerminalCanvas {
  final List<PaintCommand> _commands = [];
  final Rect _area;
  final List<_ClipScope> _pendingClipScopes = [];

  RecordingCanvas(this._area);

  @override
  Rect get area => _area;

  @override
  void drawText(Offset position, String text, {TextStyle? style}) {
    _addCommand(DrawTextCommand(position, text, style: style));
  }

  @override
  void fillRect(Rect rect, String char, {TextStyle? style}) {
    _addCommand(FillRectCommand(rect, char, style: style));
  }

  @override
  void drawBox(Rect rect, {BorderStyle? border, TextStyle? style}) {
    if (border == null) return;

    final left = rect.left.toInt();
    final top = rect.top.toInt();
    final right = (rect.left + rect.width - 1).toInt();
    final bottom = (rect.top + rect.height - 1).toInt();

    final s = style ?? const TextStyle();

    // Corners
    _addCommand(SetCellCommand(left, top, border.topLeft, s));
    _addCommand(SetCellCommand(right, top, border.topRight, s));
    _addCommand(SetCellCommand(left, bottom, border.bottomLeft, s));
    _addCommand(SetCellCommand(right, bottom, border.bottomRight, s));

    // Horizontal edges
    for (int x = left + 1; x < right; x++) {
      _addCommand(SetCellCommand(x, top, border.horizontal, s));
      _addCommand(SetCellCommand(x, bottom, border.horizontal, s));
    }

    // Vertical edges
    for (int y = top + 1; y < bottom; y++) {
      _addCommand(SetCellCommand(left, y, border.vertical, s));
      _addCommand(SetCellCommand(right, y, border.vertical, s));
    }
  }

  @override
  TerminalCanvas clip(Rect clipRect) {
    final scope = _ClipScope(clipRect, this);
    _pendingClipScopes.add(scope);
    return _ClippedRecordingCanvas(this, scope);
  }

  void _addCommand(PaintCommand command) {
    _commands.add(command);
  }

  void _closeClipScope(_ClipScope scope) {
    _pendingClipScopes.remove(scope);
    if (scope.children.isNotEmpty) {
      _commands
          .add(ClipCommand(scope.clipRect, List.unmodifiable(scope.children)));
    }
  }

  /// Finish recording and return the display list.
  DisplayList finish() {
    // Close any pending clip scopes
    for (final scope in _pendingClipScopes.toList()) {
      _closeClipScope(scope);
    }
    return DisplayList(List.unmodifiable(_commands));
  }
}

/// Tracks a clip scope and its children.
class _ClipScope {
  final Rect clipRect;
  final RecordingCanvas root;
  final List<PaintCommand> children = [];

  _ClipScope(this.clipRect, this.root);
}

/// A clipped recording canvas that collects commands into a ClipCommand.
class _ClippedRecordingCanvas implements TerminalCanvas {
  final RecordingCanvas _root;
  final _ClipScope _scope;

  _ClippedRecordingCanvas(this._root, this._scope);

  @override
  Rect get area => _scope.clipRect;

  @override
  void drawText(Offset position, String text, {TextStyle? style}) {
    _scope.children.add(DrawTextCommand(position, text, style: style));
  }

  @override
  void fillRect(Rect rect, String char, {TextStyle? style}) {
    _scope.children.add(FillRectCommand(rect, char, style: style));
  }

  @override
  void drawBox(Rect rect, {BorderStyle? border, TextStyle? style}) {
    if (border == null) return;

    final left = rect.left.toInt();
    final top = rect.top.toInt();
    final right = (rect.left + rect.width - 1).toInt();
    final bottom = (rect.top + rect.height - 1).toInt();

    final s = style ?? const TextStyle();

    // Corners
    _scope.children.add(SetCellCommand(left, top, border.topLeft, s));
    _scope.children.add(SetCellCommand(right, top, border.topRight, s));
    _scope.children.add(SetCellCommand(left, bottom, border.bottomLeft, s));
    _scope.children.add(SetCellCommand(right, bottom, border.bottomRight, s));

    // Horizontal edges
    for (int x = left + 1; x < right; x++) {
      _scope.children.add(SetCellCommand(x, top, border.horizontal, s));
      _scope.children.add(SetCellCommand(x, bottom, border.horizontal, s));
    }

    // Vertical edges
    for (int y = top + 1; y < bottom; y++) {
      _scope.children.add(SetCellCommand(left, y, border.vertical, s));
      _scope.children.add(SetCellCommand(right, y, border.vertical, s));
    }
  }

  @override
  TerminalCanvas clip(Rect clipRect) {
    // Create a nested clip scope
    final nestedScope = _ClipScope(clipRect, _root);
    return _NestedClippedRecordingCanvas(_scope, nestedScope);
  }
}

/// A nested clipped recording canvas for handling nested clips.
class _NestedClippedRecordingCanvas implements TerminalCanvas {
  final _ClipScope _parentScope;
  final _ClipScope _scope;

  _NestedClippedRecordingCanvas(this._parentScope, this._scope);

  @override
  Rect get area => _scope.clipRect;

  @override
  void drawText(Offset position, String text, {TextStyle? style}) {
    _scope.children.add(DrawTextCommand(position, text, style: style));
    _finalizeIfNeeded();
  }

  @override
  void fillRect(Rect rect, String char, {TextStyle? style}) {
    _scope.children.add(FillRectCommand(rect, char, style: style));
    _finalizeIfNeeded();
  }

  @override
  void drawBox(Rect rect, {BorderStyle? border, TextStyle? style}) {
    if (border == null) return;

    final left = rect.left.toInt();
    final top = rect.top.toInt();
    final right = (rect.left + rect.width - 1).toInt();
    final bottom = (rect.top + rect.height - 1).toInt();

    final s = style ?? const TextStyle();

    _scope.children.add(SetCellCommand(left, top, border.topLeft, s));
    _scope.children.add(SetCellCommand(right, top, border.topRight, s));
    _scope.children.add(SetCellCommand(left, bottom, border.bottomLeft, s));
    _scope.children.add(SetCellCommand(right, bottom, border.bottomRight, s));

    for (int x = left + 1; x < right; x++) {
      _scope.children.add(SetCellCommand(x, top, border.horizontal, s));
      _scope.children.add(SetCellCommand(x, bottom, border.horizontal, s));
    }

    for (int y = top + 1; y < bottom; y++) {
      _scope.children.add(SetCellCommand(left, y, border.vertical, s));
      _scope.children.add(SetCellCommand(right, y, border.vertical, s));
    }
    _finalizeIfNeeded();
  }

  @override
  TerminalCanvas clip(Rect clipRect) {
    final nestedScope = _ClipScope(clipRect, _scope.root);
    return _NestedClippedRecordingCanvas(_scope, nestedScope);
  }

  bool _finalized = false;

  void _finalizeIfNeeded() {
    if (!_finalized && _scope.children.isNotEmpty) {
      _finalized = true;
      _parentScope.children.add(
        ClipCommand(_scope.clipRect, _scope.children),
      );
    }
  }
}
