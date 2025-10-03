import 'dart:io';

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
      (files) async {
        String output = '';
        for (var file in files) {
          int length;
          if (file.path != null) {
            final f = File(file.path!);
            length = await f.length();
          } else {
            length = -1;
          }

          output +=
              'name: ${file.name}, path: ${file.path}, uri: ${file.uri}, size: $length\n';
        }
        setState(() {
          _output = output;
        });

        if (Platform.isIOS) {
          await _openFileHandlerPlugin.releaseIosURIs();
        }
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
