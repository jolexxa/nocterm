import 'dart:io';
import 'package:nocterm/nocterm.dart';

// Debug log file
final _debugLog = File('mouse_debug.log');

void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  _debugLog.writeAsStringSync('[$timestamp] $message\n', mode: FileMode.append);
}

void main() {
  // Clear previous debug log
  if (_debugLog.existsSync()) {
    _debugLog.deleteSync();
  }
  _log('=== Mouse Demo Started ===');

  runApp(const MouseDemo());
}

class MouseDemo extends StatefulComponent {
  const MouseDemo({super.key});

  @override
  State<MouseDemo> createState() => _MouseDemoState();
}

class _MouseDemoState extends State<MouseDemo> {
  String _lastEvent = 'No events yet';
  int _mouseX = 0;
  int _mouseY = 0;
  int _tapCount = 0;
  int _doubleTapCount = 0;
  int _longPressCount = 0;
  bool _isHovering = false;
  bool _isPressing = false;
  int? _hoveredListItem;
  int? _selectedListItem;

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 30,
          color: Color.fromRGB(100, 100, 100),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: ListView(
            children: List.generate(10, (index) {
              final isHovered = _hoveredListItem == index;
              final isSelected = _selectedListItem == index;
              return Container(
                  child: Column(
                children: [
                  MouseRegion(
                    onEnter: (event) {
                      _log('ListView item $index: onEnter');
                      setState(() {
                        _hoveredListItem = index;
                        _lastEvent = 'Hover item $index';
                      });
                    },
                    onExit: (event) {
                      _log('ListView item $index: onExit');
                      setState(() {
                        _hoveredListItem = null;
                      });
                    },
                    child: GestureDetector(
                      onTap: () {
                        shutdownApp();
                        _log('ListView item $index: onTap');
                        setState(() {
                          _selectedListItem = index;
                          _lastEvent = 'Selected item $index';
                        });
                      },
                      child: Container(
                        //padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                        decoration: BoxDecoration(
                          //border: BoxBorder.all(),
                          color: Colors.red,
                        ),
                        child: Text(
                          isSelected
                              ? '▶ Item $index (Selected)'
                              : isHovered
                                  ? '→ Item $index (Hovered)'
                                  : '  Item $index',
                          style: TextStyle(
                            fontWeight: isSelected || isHovered
                                ? FontWeight.bold
                                : null,
                            color: isSelected
                                ? const Color(0xFF00FF00)
                                : isHovered
                                    ? const Color(0xFFFFFF00)
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ));
            }),
          ),
        ),
      ],
    );
    return Container(
      width: 100,
      height: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            width: 80,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: BoxBorder.all(),
            ),
            child: const Text(
              '🖱️  MOUSE HANDLING DEMO',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 1),

          // Instructions
          Container(
            padding: const EdgeInsets.only(left: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Try the interactive areas below:'),
                Text('  • Hover over the regions'),
                Text('  • Click, double-click, and long-press'),
              ],
            ),
          ),
          const SizedBox(height: 1),

          // Status bar
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text('Position: ($_mouseX, $_mouseY)  '),
                Text('Last: $_lastEvent'),
              ],
            ),
          ),
          const SizedBox(height: 1),

          // Interactive areas
          Row(
            children: [
              const SizedBox(width: 2),

              // MouseRegion demo
              MouseRegion(
                onEnter: (event) {
                  _log(
                      'MouseRegion.onEnter: (${event.x}, ${event.y}) pressed=${event.pressed}');
                  setState(() {
                    _isHovering = true;
                    _mouseX = event.x;
                    _mouseY = event.y;
                    _lastEvent = 'Entered region';
                  });
                },
                onExit: (event) {
                  _log(
                      'MouseRegion.onExit: (${event.x}, ${event.y}) pressed=${event.pressed}');
                  setState(() {
                    _isHovering = false;
                    _mouseX = event.x;
                    _mouseY = event.y;
                    _lastEvent = 'Exited region';
                  });
                },
                onHover: (event) {
                  _log(
                      'MouseRegion.onHover: (${event.x}, ${event.y}) pressed=${event.pressed}');
                  setState(() {
                    _mouseX = event.x;
                    _mouseY = event.y;
                    _lastEvent = 'Hovering';
                  });
                },
                child: Container(
                  width: 22,
                  height: 8,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isHovering ? '✓ HOVERING' : '  Hover Me  ',
                        style: TextStyle(
                          fontWeight: _isHovering ? FontWeight.bold : null,
                          color: _isHovering ? const Color(0xFF00FF00) : null,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text('MouseRegion'),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 2),

              // GestureDetector - Tap demo
              GestureDetector(
                onTap: () {
                  _log('GestureDetector.onTap');
                  setState(() {
                    _tapCount++;
                    _lastEvent = 'Tap #$_tapCount';
                  });
                },
                onTapDown: (details) {
                  _log(
                      'GestureDetector.onTapDown: local=(${details.localPosition.dx}, ${details.localPosition.dy})');
                  setState(() {
                    _isPressing = true;
                    _lastEvent = 'Tap down';
                  });
                },
                onTapUp: (details) {
                  _log(
                      'GestureDetector.onTapUp: local=(${details.localPosition.dx}, ${details.localPosition.dy})');
                  setState(() {
                    _isPressing = false;
                  });
                },
                child: Container(
                  width: 22,
                  height: 8,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isPressing ? '[PRESSING]' : '  Click Me  ',
                        style: TextStyle(
                          fontWeight: _isPressing ? FontWeight.bold : null,
                          color: _isPressing ? const Color(0xFFFFFF00) : null,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text('Taps: $_tapCount'),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 2),

              // GestureDetector - Double tap demo
              GestureDetector(
                onDoubleTap: () {
                  _log('GestureDetector.onDoubleTap');
                  setState(() {
                    _doubleTapCount++;
                    _lastEvent = 'Double tap #$_doubleTapCount';
                  });
                },
                child: Container(
                  width: 22,
                  height: 8,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Double Click'),
                      const SizedBox(height: 1),
                      Text('Count: $_doubleTapCount'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 1),

          // Long press demo
          Row(
            children: [
              const SizedBox(width: 2),
              GestureDetector(
                onLongPress: () {
                  _log('GestureDetector.onLongPress');
                  setState(() {
                    _longPressCount++;
                    _lastEvent = 'Long press #$_longPressCount';
                  });
                },
                onLongPressStart: (details) {
                  _log(
                      'GestureDetector.onLongPressStart: local=(${details.localPosition.dx}, ${details.localPosition.dy})');
                  setState(() {
                    _lastEvent = 'Long press started...';
                  });
                },
                onLongPressEnd: (details) {
                  _log(
                      'GestureDetector.onLongPressEnd: local=(${details.localPosition.dx}, ${details.localPosition.dy})');
                  setState(() {
                    _lastEvent = 'Long press ended';
                  });
                },
                child: Container(
                  width: 70,
                  height: 4,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Press and Hold (500ms)'),
                      Text('Long presses: $_longPressCount'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 1),

          // ListView with MouseRegion demo
          Container(
            padding: const EdgeInsets.only(left: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ListView with MouseRegion:'),
                const SizedBox(height: 1),
                Container(
                  width: 94,
                  height: 8,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(),
                  ),
                  child: ListView(
                    children: List.generate(10, (index) {
                      final isHovered = _hoveredListItem == index;
                      final isSelected = _selectedListItem == index;
                      return MouseRegion(
                        onEnter: (event) {
                          _log('ListView item $index: onEnter');
                          setState(() {
                            _hoveredListItem = index;
                            _lastEvent = 'Hover item $index';
                          });
                        },
                        onExit: (event) {
                          _log('ListView item $index: onExit');
                          setState(() {
                            _hoveredListItem = null;
                          });
                        },
                        child: GestureDetector(
                          onTap: () {
                            _log('ListView item $index: onTap');
                            setState(() {
                              _selectedListItem = index;
                              _lastEvent = 'Selected item $index';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Text(
                              isSelected
                                  ? '▶ Item $index (Selected)'
                                  : isHovered
                                      ? '→ Item $index (Hovered)'
                                      : '  Item $index',
                              style: TextStyle(
                                fontWeight: isSelected || isHovered
                                    ? FontWeight.bold
                                    : null,
                                color: isSelected
                                    ? const Color(0xFF00FF00)
                                    : isHovered
                                        ? const Color(0xFFFFFF00)
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Footer
          Container(
            padding: const EdgeInsets.only(left: 2, bottom: 1),
            child: const Text('Press Ctrl+C to exit'),
          ),
        ],
      ),
    );
  }
}
