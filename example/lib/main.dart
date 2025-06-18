import 'package:flutter/material.dart';
import 'package:open_file_handler/open_file_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _output = '';
  final _openFileHandlerPlugin = OpenFileHandler();

  @override
  void initState() {
    super.initState();

    _openFileHandlerPlugin.listen(
      (files) {
        setState(() {
          _output = files.join(', ');
        });
      },
      onError: (error) {
        setState(() {
          _output = 'Error: $error';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Text(_output.isEmpty ? 'No files opened yet.' : _output),
        ),
      ),
    );
  }
}
