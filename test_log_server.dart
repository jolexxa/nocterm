import 'dart:io';
import 'package:nocterm/nocterm.dart';

void main() async {
  print('Starting log server test...');

  final logServer = LogServer();

  try {
    await logServer.start();
    print('Log server started on port: ${logServer.port}');

    // Check if port file was written
    final portFile = File('.nocterm/log_port');
    if (await portFile.exists()) {
      final content = await portFile.readAsString();
      print('Port file contents: $content');
    } else {
      print('ERROR: Port file was not created!');
    }

    // Log some messages
    logServer.log('Test message 1');
    logServer.log('Test message 2');
    logServer.log('Test message 3');

    print('Logged 3 messages. Server is running.');
    print('Try connecting with: nocterm logs');
    print('Press Ctrl+C to exit...');

    // Keep running
    await Future.delayed(Duration(hours: 1));
  } catch (e, stack) {
    print('Error starting log server: $e');
    print('Stack trace: $stack');
  } finally {
    await logServer.close();
  }
}
