import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(
    Container(
      child: Center(
        child: Text(
          'Mouse Cleanup Test\n\n'
          'Move your mouse around to test tracking.\n'
          'Press Ctrl+C to exit.\n\n'
          'After exit, mouse movement should NOT\n'
          'produce any characters in your terminal.\n\n'
          'If cleanup works correctly, your terminal\n'
          'will be clean after exit.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}