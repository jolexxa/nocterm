import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const TextInContainer());
}

class TextInContainer extends StatelessComponent {
  const TextInContainer({super.key});

  @override
  Component build(BuildContext context) {
    return Container(
        color: Colors.blue,
        alignment: Alignment.center,
        child: Text('Hello, World!', style: TextStyle(color: Colors.white)));
  }
}
