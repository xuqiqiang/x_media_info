import 'dart:convert';

import 'package:file_picker_fork/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:x_media_info/x_media_info.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  xMediaInfo.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // String _platformVersion = 'Unknown';
  // final _xMediaInfoPlugin = XMediaInfo();
  final methodChannel = const MethodChannel('x_media_info');
  String? _mediaInfo;

  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }

  Future<String?> pickFiles(FileType fileType) async {
    try {
      List<PlatformFile>? _paths =
          (await FilePicker.platform.pickFiles(type: fileType))?.files;
      if (_paths != null && _paths.isNotEmpty) {
        return _paths.first.path;
      }
    } catch (e) {
      print('pickFiles error $e');
    }
    return null;
  }

  createThumbnail() async {
    String? uri = await pickFiles(FileType.any);
    if (uri == null) return;
    // uri = 'https://movietrailers.apple.com/movies/paramount/the-spongebob-movie-sponge-on-the-run/the-spongebob-movie-sponge-on-the-run-big-game_h720p.mov';
    xMediaInfo.createThumbnail(uri, 'G:\\test1.png', timePercent: 0.1);
  }

  getMediaInfo() async {
    String? uri = await pickFiles(FileType.any);
    if (uri == null) return;
    // uri = 'https://movietrailers.apple.com/movies/paramount/the-spongebob-movie-sponge-on-the-run/the-spongebob-movie-sponge-on-the-run-big-game_h720p.mov';
    MediaInfo info = await xMediaInfo.getMediaInfo(uri);
    setState(() {
      _mediaInfo = info.toString();
      print('getMediaInfo $_mediaInfo');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            TextButton(
                onPressed: createThumbnail, child: const Text('createThumbnail')),
            const SizedBox(height: 6),
            TextButton(onPressed: getMediaInfo, child: const Text('mediaInfo')),
            const SizedBox(height: 6),
            if (_mediaInfo != null) Text(_mediaInfo!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
