# nocterm CLI

CLI tools for nocterm - A Terminal User Interface framework for Dart.

## Installation

Compile the CLI executable:

```bash
cd packages/nocterm_cli
dart compile exe bin/nocterm_cli.dart -o ../../nocterm
```

## Commands

### `nocterm shell`

Start a nocterm shell server that nocterm apps can render into. This allows running nocterm apps from IDEs with debugger support.

**How it works:**

1. The shell creates a Unix domain socket at `.nocterm/shell.sock`
2. It writes the socket path to `.nocterm/shell_handle`
3. When you run a nocterm app (via `dart run`), it automatically detects the shell_handle file
4. The app connects to the shell and renders frames over the socket
5. The shell displays the frames in its terminal
6. Input from the shell terminal is forwarded to the app

**Usage:**

Terminal 1 - Start the shell:
```bash
./nocterm shell
```

Terminal 2 - Run your nocterm app (or from IDE with debugger):
```bash
cd test_shell_app
dart run bin/test_app.dart
```

The app will automatically render into the shell instead of its own stdout.

**Benefits:**

- ✅ Run nocterm apps from IDEs (VSCode, IntelliJ, etc.)
- ✅ Attach debugger to nocterm apps
- ✅ Set breakpoints and inspect state
- ✅ No changes needed to app code - works automatically
- ✅ Falls back to normal rendering if shell is not running
- ✅ `print()` statements appear in your IDE/terminal, not log.txt
- ✅ Debug output is visible while TUI renders in the shell

## Development Workflow

### Normal Mode (Direct Rendering)

```bash
# Run app directly - renders to its own terminal
# print() statements go to log.txt
dart run bin/my_app.dart
```

### Shell Mode (IDE Debugging)

```bash
# Terminal 1: Start shell
./nocterm shell

# IDE or Terminal 2: Run app with debugger
# App automatically detects shell and renders there
# print() statements appear in your IDE/terminal!
dart run bin/my_app.dart
```

**Note:** In shell mode, `print()` statements appear in the terminal/IDE where you run the app (Terminal 2 above), while the TUI renders in the shell (Terminal 1). This makes debugging much easier!

## Technical Details

### Communication Protocol

The shell and app communicate via Unix domain sockets with a simple pass-through architecture:

**App → Shell:** Raw ANSI terminal output (escape sequences, colors, text)
**Shell → App:** Raw stdin input (keyboard, mouse events)

The app uses a `SocketTerminal` instead of the regular `Terminal`, which writes all output to the socket instead of stdout. The shell simply forwards this output to its stdout and forwards its stdin back to the app. This means the protocol is just raw terminal data - no custom serialization needed!

## Examples

See `test_shell_app/` for a simple example that works in both normal and shell mode.

## Troubleshooting

**App doesn't connect to shell:**
- Make sure the shell is running first
- Check that `.nocterm/shell_handle` exists in the current directory
- Verify the socket path in shell_handle is correct

**Shell shows garbled output:**
- This shouldn't happen, but if it does, check for protocol version mismatches
- Try recompiling both the CLI and the app

**Input not working:**
- Make sure your terminal supports raw mode
- Check that stdin is not being piped or redirected
