# Terminal Background Color Detection

This document describes how to implement automatic light/dark theme detection in nocterm by querying the terminal's background color.

## Overview

Terminal background color detection enables TUI applications to automatically select light or dark themes based on the user's terminal configuration. The primary method is the **OSC 11** escape sequence, with fallbacks to environment variables.

## OSC 11 Escape Sequence

### Query Format

```
\x1b]11;?\x07     (using BEL terminator - broader compatibility)
\x1b]11;?\x1b\\   (using ST terminator)
```

Where:
- `\x1b]` = OSC (Operating System Command) introducer
- `11` = background color query
- `?` = query indicator
- `\x07` = BEL terminator (recommended)
- `\x1b\\` = ST (String Terminator) alternative

### Response Format

The terminal responds with:
```
\x1b]11;rgb:RRRR/GGGG/BBBB\x07
```

Examples:
- Black: `rgb:0000/0000/0000`
- White: `rgb:ffff/ffff/ffff`
- Dark gray: `rgb:1d1d/1f1f/2121`

**Note**: RGB values are 4-digit hex (16-bit per channel). Some terminals use 2-digit hex (8-bit).

### OSC 10 (Foreground Color)

Same format but uses `10` instead of `11`:
```
\x1b]10;?\x07
```

---

## Dart Implementation

### Step 1: Query Background Color

```dart
import 'dart:io';
import 'dart:async';

Future<String?> queryBackgroundColor({
  Duration timeout = const Duration(milliseconds: 50),
}) async {
  if (!stdin.hasTerminal || !stdout.hasTerminal) {
    return null;
  }

  // Save current terminal state
  final wasLineMode = stdin.lineMode;
  final wasEchoMode = stdin.echoMode;

  try {
    // Enter raw mode
    stdin.echoMode = false;
    stdin.lineMode = false;

    // Send OSC 11 query (using BEL terminator for broader compatibility)
    stdout.write('\x1b]11;?\x07');
    await stdout.flush();

    // Read response with timeout
    final buffer = StringBuffer();
    final completer = Completer<String?>();

    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final subscription = stdin.listen((data) {
      buffer.write(String.fromCharCodes(data));
      final response = buffer.toString();

      // Check for response terminator (BEL or ST)
      if (response.contains('\x07') || response.contains('\x1b\\')) {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }
    });

    final response = await completer.future;
    await subscription.cancel();

    return response;
  } finally {
    // Always restore terminal state
    stdin.lineMode = wasLineMode;
    stdin.echoMode = wasEchoMode;
  }
}
```

### Step 2: Parse RGB Response

```dart
class TerminalRgbColor {
  final int r, g, b;
  TerminalRgbColor(this.r, this.g, this.b);

  /// Calculate perceived luminance (0.0 = black, 1.0 = white)
  double get luminance {
    // Convert to 0-1 range
    final rNorm = r / 65535.0;
    final gNorm = g / 65535.0;
    final bNorm = b / 65535.0;

    // Using standard luminance formula (Rec. 709)
    return 0.2126 * rNorm + 0.7152 * gNorm + 0.0722 * bNorm;
  }

  bool get isDark => luminance < 0.5;
  bool get isLight => luminance >= 0.5;
}

TerminalRgbColor? parseOsc11Response(String? response) {
  if (response == null) return null;

  // Pattern: rgb:RRRR/GGGG/BBBB (4-digit hex)
  // Also handle: rgb:RR/GG/BB (2-digit hex)
  final regex = RegExp(r'rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)');
  final match = regex.firstMatch(response);

  if (match == null) return null;

  final rHex = match.group(1)!;
  final gHex = match.group(2)!;
  final bHex = match.group(3)!;

  // Normalize to 16-bit values
  int normalize(String hex) {
    final value = int.parse(hex, radix: 16);
    if (hex.length == 2) {
      return value * 257; // Scale 8-bit to 16-bit (0xFF -> 0xFFFF)
    } else if (hex.length == 4) {
      return value;
    }
    return value;
  }

  return TerminalRgbColor(normalize(rHex), normalize(gHex), normalize(bHex));
}
```

### Step 3: COLORFGBG Fallback

```dart
/// Detect dark mode from COLORFGBG environment variable.
/// Returns null if the variable is not set or cannot be parsed.
bool? detectDarkModeFromColorFgBg() {
  final colorfgbg = Platform.environment['COLORFGBG'];
  if (colorfgbg == null) return null;

  // Format: "fg;bg" or "fg;extra;bg"
  final parts = colorfgbg.split(';');
  if (parts.isEmpty) return null;

  // Get the last value (background)
  final bg = int.tryParse(parts.last);
  if (bg == null) return null;

  // ANSI colors 0-6 and 8 are considered dark
  // 0=black, 1=red, 2=green, 3=yellow, 4=blue, 5=magenta, 6=cyan, 8=bright black
  // 7=white and 9-15 are light colors
  return bg >= 0 && bg <= 6 || bg == 8;
}
```

### Step 4: macOS System Appearance

```dart
/// Check macOS system appearance (Dark Mode setting).
/// Returns null if not on macOS or detection fails.
Future<bool?> detectMacOSDarkMode() async {
  if (!Platform.isMacOS) return null;

  try {
    final result = await Process.run(
      'defaults',
      ['read', '-g', 'AppleInterfaceStyle'],
    );

    if (result.exitCode == 0) {
      final output = result.stdout.toString().trim().toLowerCase();
      return output == 'dark';
    }

    // If command fails (exit code != 0), macOS is in light mode
    // (the key doesn't exist when in light mode)
    return false;
  } catch (e) {
    return null;
  }
}
```

### Step 5: Complete Detection Function

```dart
/// Detected terminal brightness.
enum TerminalBrightness { light, dark }

/// Detect the terminal's color scheme (light or dark).
///
/// Detection order:
/// 1. OSC 11 query (50ms timeout)
/// 2. COLORFGBG environment variable
/// 3. macOS AppleInterfaceStyle (macOS only)
/// 4. Default to dark
Future<TerminalBrightness> detectTerminalBrightness() async {
  // Method 1: Try OSC 11 query
  if (stdin.hasTerminal && stdout.hasTerminal) {
    try {
      final response = await queryBackgroundColor(
        timeout: const Duration(milliseconds: 50),
      );
      final color = parseOsc11Response(response);
      if (color != null) {
        return color.isDark
            ? TerminalBrightness.dark
            : TerminalBrightness.light;
      }
    } catch (e) {
      // Fall through to next method
    }
  }

  // Method 2: Check COLORFGBG environment variable
  final isDarkFromEnv = detectDarkModeFromColorFgBg();
  if (isDarkFromEnv != null) {
    return isDarkFromEnv
        ? TerminalBrightness.dark
        : TerminalBrightness.light;
  }

  // Method 3: Check macOS appearance
  if (Platform.isMacOS) {
    final isDarkMacOS = await detectMacOSDarkMode();
    if (isDarkMacOS != null) {
      return isDarkMacOS
          ? TerminalBrightness.dark
          : TerminalBrightness.light;
    }
  }

  // Default: assume dark (most common for terminal users)
  return TerminalBrightness.dark;
}
```

---

## Integration with TuiTheme

### Suggested API

```dart
// In NoctermApp or TuiTheme
class TuiTheme {
  /// Automatically detect and apply the appropriate theme.
  static Future<TuiThemeData> detectTheme({
    TuiThemeData? darkTheme,
    TuiThemeData? lightTheme,
  }) async {
    final brightness = await detectTerminalBrightness();

    if (brightness == TerminalBrightness.light) {
      return lightTheme ?? TuiThemeData.light;
    } else {
      return darkTheme ?? TuiThemeData.dark;
    }
  }
}

// Usage in app
void main() async {
  final theme = await TuiTheme.detectTheme();

  runApp(
    TuiTheme(
      data: theme,
      child: MyApp(),
    ),
  );
}
```

### Alternative: Brightness in TuiThemeData

```dart
// Add factory constructor to TuiThemeData
class TuiThemeData {
  // Existing code...

  /// Create a theme based on detected terminal brightness.
  static Future<TuiThemeData> fromTerminal() async {
    final brightness = await detectTerminalBrightness();
    return brightness == TerminalBrightness.light
        ? TuiThemeData.light
        : TuiThemeData.dark;
  }
}
```

---

## Terminal Compatibility

### Full OSC 11 Support ✅

| Terminal | Platform | Notes |
|----------|----------|-------|
| iTerm2 | macOS | Full support |
| Warp | macOS | Full support |
| Alacritty | All | Full support |
| kitty | All | Full support |
| GNOME Terminal | Linux | Full support |
| xterm | All | Full support |
| Windows Terminal | Windows | v1.22+ |
| VS Code Terminal | All | Full support |
| tmux | All | Passthrough support |
| rxvt-unicode | Linux | Full support |
| mintty | Windows | Full support |
| Konsole | Linux | Full support |
| Hyper | All | Full support |

### Limited/No Support ❌

| Terminal | Platform | Fallback |
|----------|----------|----------|
| Terminal.app | macOS | Use macOS AppleInterfaceStyle |
| ConEmu | Windows | Use COLORFGBG or default |
| PuTTY | Windows | Default to dark |
| cmd.exe | Windows | Default to dark |
| PowerShell (native) | Windows | Default to dark |

### COLORFGBG Support

| Terminal | Sets COLORFGBG |
|----------|----------------|
| iTerm2 | ✅ Yes |
| Konsole | ✅ Yes |
| rxvt family | ✅ Yes |
| Most others | ❌ No |

---

## Implementation Notes

### Timing Considerations

- Use a **short timeout** (20-100ms) for OSC 11 query
- Terminals that don't support the query won't respond at all
- Never block app startup indefinitely

### Terminal State Management

```dart
// ALWAYS use try/finally to restore terminal state
try {
  stdin.echoMode = false;
  stdin.lineMode = false;
  // ... query logic
} finally {
  stdin.lineMode = true;  // Restore
  stdin.echoMode = true;  // Restore
}
```

### When NOT to Query

```dart
// Don't query if stdin/stdout aren't terminals (piped I/O)
if (!stdin.hasTerminal || !stdout.hasTerminal) {
  return TerminalBrightness.dark; // Default
}
```

### Caching

- Detect **once** at app startup
- Cache the result for the session
- Don't re-query during rendering
- Allow user override via settings/flags

### Detection Timing

```
┌─────────────────────────────────────────┐
│  App Start                              │
├─────────────────────────────────────────┤
│  1. detectTerminalBrightness()  ◄─────  │  BEFORE TUI init
│  2. Create TuiThemeData                 │
│  3. Initialize TUI framework            │
│  4. Run app                             │
└─────────────────────────────────────────┘
```

---

## Fallback Strategy

```
┌─────────────────────────────────┐
│  OSC 11 Query (50ms timeout)    │
└──────────────┬──────────────────┘
               │ (no response / parse error)
               ▼
┌─────────────────────────────────┐
│  COLORFGBG Environment Variable │
└──────────────┬──────────────────┘
               │ (not set)
               ▼
┌─────────────────────────────────┐
│  macOS: AppleInterfaceStyle     │
└──────────────┬──────────────────┘
               │ (not macOS / error)
               ▼
┌─────────────────────────────────┐
│  Default: DARK                  │
└─────────────────────────────────┘
```

**Why default to dark?**
- Terminal users typically prefer dark themes
- Dark themes are safer for code highlighting contrast
- Matches most terminal default configurations

---

## References

- [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html) - Official escape sequence documentation
- [termbg (Rust)](https://github.com/dalance/termbg) - Reference implementation
- [terminal-light (Rust)](https://github.com/Canop/terminal-light) - Simpler implementation
- [bat Theme Detection](https://github.com/sharkdp/bat) - Production example in Rust
