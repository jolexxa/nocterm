import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const ChangingTest());
}

class ChangingTest extends StatefulComponent {
  const ChangingTest({super.key});

  @override
  State<ChangingTest> createState() => _ChangingTestState();
}

class _ChangingTestState extends State<ChangingTest> {
  bool changed = false;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        setState(() {
          changed = !changed;
        });
        return true;
      },
      child: Column(children: [
        changed
            ? Expanded(
                child: Text('one'),
              )
            : Text('two')
      ]),
    );
  }
}
