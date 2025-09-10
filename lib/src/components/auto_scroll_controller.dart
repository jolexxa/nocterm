import 'package:nocterm/nocterm.dart';

/// A ScrollController that automatically scrolls to the bottom when new content
/// is added, but preserves scroll position when the user scrolls up.
/// Useful for chat interfaces, logs, and other auto-scrolling content.
class AutoScrollController extends ScrollController {
  AutoScrollController({
    double initialScrollOffset = 0.0,
    this.autoScrollThreshold = 1.0,
  }) : super(initialScrollOffset: initialScrollOffset);

  /// The distance from the bottom within which auto-scroll is enabled.
  /// If the user is within this distance from the bottom, new content
  /// will trigger auto-scroll. Default is 1.0 pixel.
  final double autoScrollThreshold;

  /// Whether auto-scroll is currently enabled based on scroll position.
  bool _isAutoScrollEnabled = true;

  /// Whether auto-scroll is currently enabled.
  bool get isAutoScrollEnabled => _isAutoScrollEnabled;

  /// Track the previous max scroll extent to detect content changes.
  double _previousMaxScrollExtent = 0.0;

  @override
  void updateMetrics({
    required double minScrollExtent,
    required double maxScrollExtent,
    required double viewportDimension,
  }) {
    // Check if we should auto-scroll before updating metrics
    final wasNearBottom = _isNearBottom();
    final contentGrew = maxScrollExtent > _previousMaxScrollExtent;

    // Update metrics
    super.updateMetrics(
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
      viewportDimension: viewportDimension,
    );

    // Auto-scroll if we were near bottom and content grew
    if (_isAutoScrollEnabled && wasNearBottom && contentGrew) {
      // Schedule scroll to end after the frame
      try {
        TerminalBinding.instance.addPostFrameCallback(() {
          scrollToEnd();
        });
      } catch (e) {
        // In test environment or when binding is not available, scroll immediately
        scrollToEnd();
      }
    }

    _previousMaxScrollExtent = maxScrollExtent;
  }

  /// Check if the scroll position is near the bottom.
  bool _isNearBottom() {
    if (maxScrollExtent == 0) return true; // No scrolling needed
    return offset >= maxScrollExtent - autoScrollThreshold;
  }

  /// Update auto-scroll state based on current position.
  void _updateAutoScrollState() {
    final wasEnabled = _isAutoScrollEnabled;
    _isAutoScrollEnabled = _isNearBottom();

    if (wasEnabled != _isAutoScrollEnabled) {
      notifyListeners();
    }
  }

  @override
  void jumpTo(double value) {
    super.jumpTo(value);
    _updateAutoScrollState();
  }

  @override
  void scrollBy(double delta) {
    super.scrollBy(delta);
    _updateAutoScrollState();
  }

  /// Manually enable auto-scroll and scroll to bottom.
  void enableAutoScroll() {
    _isAutoScrollEnabled = true;
    scrollToEnd();
    notifyListeners();
  }

  /// Manually disable auto-scroll.
  void disableAutoScroll() {
    _isAutoScrollEnabled = false;
    notifyListeners();
  }

  /// Scroll to bottom with auto-scroll enabled.
  void scrollToBottom() {
    enableAutoScroll();
  }
}
