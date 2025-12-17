import 'package:nocterm/nocterm.dart';

import 'run_app_stub.dart'
    if (dart.library.io) 'run_app_io.dart'
    if (dart.library.html) 'run_app_web.dart';

export 'screen_mode.dart';

/// Run a TUI application.
///
/// This is the main entry point for starting a Nocterm TUI application.
/// It automatically detects the platform and configures the appropriate backend:
///
/// - **Native (Linux, macOS)**: Uses StdioBackend, checks for shell mode
/// - **Web**: Uses WebBackend with static bridge for WASM/JS apps
///
/// On native platforms, also checks for nocterm shell mode for IDE debugging.
///
/// ## Screen Modes
///
/// [screenMode] controls how the TUI renders in the terminal:
///
/// - [ScreenMode.alternateScreen] (default): Takes over the full terminal.
///   Previous terminal content is restored when the app exits. Use this for
///   full-screen applications like editors, dashboards, and file managers.
///
/// - [ScreenMode.inline]: Renders inline without alternate screen. Output
///   stays in terminal history. Ideal for CLIs, test runners, build tools,
///   and interactive prompts.
///
/// ## Inline Mode Exit Behavior
///
/// [inlineExitBehavior] controls what happens when exiting inline mode
/// (ignored for alternate screen mode):
///
/// - [InlineExitBehavior.preserve] (default): Leave rendered content visible
///   in the terminal. Users can scroll back to see the final output.
///
/// - [InlineExitBehavior.clear]: Erase all rendered content on exit, leaving
///   the terminal as if the app never ran.
///
/// ## Example
///
/// ```dart
/// // Full-screen app (default)
/// await runApp(MyDashboard());
///
/// // Inline test runner
/// await runApp(
///   TestRunner(),
///   screenMode: ScreenMode.inline,
///   inlineExitBehavior: InlineExitBehavior.preserve,
/// );
///
/// // Interactive prompt that clears on exit
/// await runApp(
///   ConfirmDialog(),
///   screenMode: ScreenMode.inline,
///   inlineExitBehavior: InlineExitBehavior.clear,
/// );
/// ```
///
/// ## Inline Mode Best Practices
///
/// When using inline mode, design your layout with **static content at the top
/// and dynamic content at the bottom**. As content exceeds terminal height,
/// the top scrolls into the scrollback buffer (frozen), while the bottom
/// remains visible and updatable.
///
/// See [ScreenMode.inline] for more details and layout recommendations.
///
/// ## Hot Reload
///
/// Set [enableHotReload] to `true` (default) to enable hot reload support.
/// Run with `dart --enable-vm-service your_app.dart` to use hot reload.
Future<void> runApp(
  Component app, {
  bool enableHotReload = true,
  ScreenMode screenMode = ScreenMode.alternateScreen,
  InlineExitBehavior inlineExitBehavior = InlineExitBehavior.preserve,
}) {
  return runAppImpl(
    app,
    enableHotReload: enableHotReload,
    screenMode: screenMode,
    inlineExitBehavior: inlineExitBehavior,
  );
}
