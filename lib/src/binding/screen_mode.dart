/// Controls how the TUI renders in the terminal.
///
/// Most TUI applications use [alternateScreen] (the default), which takes over
/// the entire terminal. However, some use cases benefit from [inline] mode,
/// which renders output directly into the terminal's scrollback history.
///
/// ## Example
///
/// ```dart
/// // Default: takes over the terminal
/// await runApp(MyComponent());
///
/// // Inline: output stays in terminal history
/// await runApp(
///   MyComponent(),
///   screenMode: ScreenMode.inline,
/// );
/// ```
///
/// See also:
/// - [InlineExitBehavior] for controlling what happens when inline mode exits
/// - `example/inline_demo.dart` for a simple progress bar example
/// - `example/test_runner_demo.dart` for a test runner simulation
enum ScreenMode {
  /// Use alternate screen buffer (default).
  ///
  /// The TUI takes over the full terminal and restores the previous content
  /// on exit. This is the traditional mode for full-screen TUI applications
  /// like text editors, file managers, and interactive dashboards.
  ///
  /// The terminal content before the app started is preserved and restored
  /// when the app exits.
  alternateScreen,

  /// Render inline without alternate screen.
  ///
  /// Output renders directly into the terminal's scrollback history, similar
  /// to regular command-line output. This is ideal for:
  ///
  /// - **Test runners**: Show completed tests scrolling up, current test at bottom
  /// - **Build tools**: Progress and status at bottom, logs scrolling up
  /// - **Interactive prompts**: Question/answer flows
  /// - **Project scaffolders**: Step-by-step progress
  ///
  /// ## Layout Behavior
  ///
  /// In inline mode, components receive **unbounded height constraints**,
  /// meaning they determine their own height. When content exceeds the terminal
  /// height, the top portion scrolls into the terminal's scrollback buffer
  /// (frozen/immutable), while the bottom portion stays visible and updatable.
  ///
  /// ## Best Practice: Put Dynamic Content at the Bottom
  ///
  /// Since the top of your UI may scroll into the scrollback (becoming frozen),
  /// design your layout with static content at the top and dynamic content at
  /// the bottom:
  ///
  /// ```
  /// ┌─────────────────────────┐
  /// │ Static header/info      │  ← May scroll into scrollback (OK - it's static)
  /// │ Completed items...      │
  /// ├─────────────────────────┤
  /// │ Currently running item  │  ← Stays visible and updates
  /// │ Progress/summary        │
  /// └─────────────────────────┘
  /// ```
  ///
  /// Use [InlineExitBehavior] to control whether the output is preserved or
  /// cleared when the app exits.
  inline,
}

/// Controls what happens to inline content when the app exits.
///
/// This only applies when using [ScreenMode.inline]. It determines whether
/// the rendered output remains visible in the terminal after the app exits
/// or is erased.
///
/// ## Example
///
/// ```dart
/// // Preserve output (default) - user can see final state
/// await runApp(
///   MyComponent(),
///   screenMode: ScreenMode.inline,
///   inlineExitBehavior: InlineExitBehavior.preserve,
/// );
///
/// // Clear output - terminal looks like app never ran
/// await runApp(
///   MyComponent(),
///   screenMode: ScreenMode.inline,
///   inlineExitBehavior: InlineExitBehavior.clear,
/// );
/// ```
enum InlineExitBehavior {
  /// Leave rendered content visible in terminal (default for inline).
  ///
  /// The final output remains in the terminal's scrollback history after exit.
  /// This is useful when you want the user to see the final state, such as:
  /// - Test results summary
  /// - Build completion status
  /// - Generated file paths
  preserve,

  /// Clear all rendered content, leaving terminal as if app never ran.
  ///
  /// The area where the TUI was rendered is erased on exit. This is useful
  /// for temporary interactive prompts or when you don't want to leave
  /// artifacts in the terminal history.
  clear,
}
