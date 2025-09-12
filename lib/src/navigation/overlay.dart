import 'package:nocterm/nocterm.dart';

import '../framework/framework.dart';
import '../components/render_stack.dart' show Stack;

/// A single entry in an [Overlay].
class OverlayEntry {
  /// Creates an overlay entry.
  OverlayEntry({
    required this.builder,
    bool opaque = false,
    bool maintainState = false,
  })  : _opaque = opaque,
        _maintainState = maintainState;

  /// The builder for the widget to display in the overlay.
  final ComponentBuilder builder;

  /// Whether this entry occludes the entire overlay.
  bool get opaque => _opaque;
  bool _opaque;
  set opaque(bool value) {
    if (_opaque == value) {
      return;
    }
    _opaque = value;
    _overlay?._didChangeEntryOpacity();
  }

  /// Whether this entry must be included in the tree even if there is a fully
  /// opaque entry above it.
  bool get maintainState => _maintainState;
  bool _maintainState;
  set maintainState(bool value) {
    if (_maintainState == value) {
      return;
    }
    _maintainState = value;
    _overlay?._didChangeEntryOpacity();
  }

  OverlayState? _overlay;
  final GlobalKey _key = GlobalKey();

  /// Remove this entry from the overlay.
  void remove() {
    _overlay?._remove(this);
  }

  /// Mark this entry as needing to rebuild.
  void markNeedsBuild() {
    // Request a rebuild of the overlay containing this entry
    _overlay?._markNeedsBuild();
  }
}

/// A stack of entries that can be managed independently.
class Overlay extends StatefulComponent {
  /// Creates an overlay.
  const Overlay({
    super.key,
    this.initialEntries = const <OverlayEntry>[],
  });

  /// The entries to include in the overlay initially.
  final List<OverlayEntry> initialEntries;

  /// The state from the closest instance of this class that encloses the given context.
  static OverlayState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<OverlayState>();
  }

  /// The state from the closest instance of this class that encloses the given context.
  static OverlayState of(BuildContext context) {
    final OverlayState? result = maybeOf(context);
    assert(result != null, 'No Overlay found in context');
    return result!;
  }

  @override
  State<Overlay> createState() => OverlayState();
}

/// The current state of an [Overlay].
class OverlayState extends State<Overlay> {
  final List<OverlayEntry> _entries = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    // Add initial entries directly without calling setState
    for (final OverlayEntry entry in component.initialEntries) {
      assert(entry._overlay == null);
      entry._overlay = this;
      _entries.add(entry);
    }
  }

  /// Insert the given entry into the overlay.
  void insert(OverlayEntry entry, {OverlayEntry? below, OverlayEntry? above}) {
    assert(entry._overlay == null);
    assert(above == null || below == null);
    entry._overlay = this;
    setState(() {
      final int index = _insertionIndex(below, above);
      _entries.insert(index, entry);
    });
  }

  /// Insert all the entries in the given iterable.
  void insertAll(Iterable<OverlayEntry> entries, {OverlayEntry? below, OverlayEntry? above}) {
    assert(above == null || below == null);
    if (entries.isEmpty) {
      return;
    }
    for (final OverlayEntry entry in entries) {
      assert(entry._overlay == null);
      entry._overlay = this;
    }
    setState(() {
      _entries.insertAll(_insertionIndex(below, above), entries);
    });
  }

  int _insertionIndex(OverlayEntry? below, OverlayEntry? above) {
    if (below != null) {
      return _entries.indexOf(below);
    }
    if (above != null) {
      return _entries.indexOf(above) + 1;
    }
    return _entries.length;
  }

  /// Remove the given entry from the overlay.
  void _remove(OverlayEntry entry) {
    if (entry._overlay != this) {
      return;
    }
    setState(() {
      _entries.remove(entry);
    });
    entry._overlay = null;
  }

  /// Rearrange the entries to match the given order.
  void rearrange(Iterable<OverlayEntry> newEntries) {
    final List<OverlayEntry> newEntriesList = newEntries.toList();
    setState(() {
      _entries.clear();
      _entries.addAll(newEntriesList);
    });
  }

  void _didChangeEntryOpacity() {
    setState(() {
      // Rebuild when opacity changes
    });
  }

  void _markNeedsBuild() {
    setState(() {
      // Trigger a rebuild
    });
  }

  @override
  Component build(BuildContext context) {
    // Build only the entries that need to be visible
    final List<Component> children = <Component>[];
    bool seenOpaque = false;

    // Build from top to bottom, but respect maintainState and opacity
    for (int i = _entries.length - 1; i >= 0; i -= 1) {
      final OverlayEntry entry = _entries[i];
      if (seenOpaque && !entry.maintainState) {
        // Skip this entry as it's occluded and doesn't need to maintain state
        continue;
      }

      // Use a stateful wrapper to maintain state per entry
      children.insert(
        0,
        _OverlayEntryWidget(
          key: entry._key,
          entry: entry,
        ),
      );

      if (entry.opaque) {
        seenOpaque = true;
      }
    }

    return Stack(children: children);
  }
}

/// A widget that builds and maintains the state for an [OverlayEntry].
class _OverlayEntryWidget extends StatefulComponent {
  const _OverlayEntryWidget({
    required super.key,
    required this.entry,
  });

  final OverlayEntry entry;

  @override
  State<_OverlayEntryWidget> createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<_OverlayEntryWidget> {
  @override
  Component build(BuildContext context) {
    return Container(
      color: component.entry.opaque ? Colors.red : null,
      child: component.entry.builder(context),
    );
  }
}
