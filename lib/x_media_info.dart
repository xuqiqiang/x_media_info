import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter/services.dart';
import 'package:process_run/shell_run.dart';

// import 'x_media_info_platform_interface.dart';

class XMediaInfo {
  final _channel = const MethodChannel('x_media_info');

  final Map<String, Function?> _execMap = {};

  String currentPath = '';
  String binPath = '';

  Future<void> _methodCallHandler(MethodCall call) async {
    log("windowPlugin method=${call.method} arguments=${call.arguments}");
    if (call.method == 'onMediaInfo') {
      MediaInfo result = MediaInfo.fromJson(jsonDecode(call.arguments));
      Function? func = _execMap.remove(result.$id);
      log("x_media_info onMediaInfo result=$result func:${func != null}");
      func?.call(result);
    }
  }

  // Future<String?> getPlatformVersion() {
  //   return XMediaInfoPlatform.instance.getPlatformVersion();
  // }

  static bool get inDebugMode {
    bool debug = false;
    assert(debug = true);
    return debug;
  }

  static log(Object? object) {
    if (!inDebugMode) return;
    if (object == null) return;
    // ignore: avoid_print
    print('$object');
  }


  XMediaInfo._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  /// The shared instance of [XMediaInfo].
  static final XMediaInfo instance = XMediaInfo._();



  // XMediaInfo._privateConstructor() {
  //   _channel.setMethodCallHandler((MethodCall call) async {
  //
  //   });
  // }
  //
  // static final XMediaInfo _instance = XMediaInfo._privateConstructor();
  //
  // factory XMediaInfo() {
  //   return _instance;
  // }

  init() {
    currentPath = '${Directory.current.path}\\';
    log('currentPath $currentPath');
    if (inDebugMode) {
      binPath = 'build\\windows\\runner\\Debug\\';
    }
  }

  Future<MediaInfo> getMediaInfo(String uri, {bool detail = true}) async {
    Completer<MediaInfo> completer = Completer<MediaInfo>();
    String id = generateRandomString(10);
    final Map<String, dynamic> arguments = {
      'id': id,
      'uri': gbk.encode(uri),
      'detail': detail,
    };
    _execMap[id] = (result) => completer.complete(result);
    _channel.invokeMethod('getMediaInfo', arguments);
    return completer.future;
  }

  String generateRandomString(int length) {
    final random = Random();
    const availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)])
        .join();
    return randomString;
  }

  Future<bool> createThumbnail(String inputUri, String outputPath,
      {int? width,
      int? height,
      MediaType? mediaType,
      int? timeS,
      double? timePercent}) async {
    FileSystemEntityType type = FileSystemEntity.typeSync(outputPath);
    if (type == FileSystemEntityType.directory) {
      return false;
    } else if (type == FileSystemEntityType.file) {
      File(outputPath).delete();
    }
    log('getMediaThumbnail inputUri $inputUri');
    MediaInfo info = await getMediaInfo(inputUri, detail: false);
    mediaType ??= info.type;
    if (mediaType == MediaType.video && timePercent != null) {
      timeS = info.duration * timePercent ~/ 1000;
    }

    String w;
    String h;
    if (width == null && height == null) {
      w = "'min(300,iw)'"; // 避免放大
      h = '-1';
    } else {
      w = width == null ? '-1' : "'min($width,iw)'";
      h = height == null ? '-1' : "'min($height,iw)'";
    }

    log('getMediaThumbnail mediaType $mediaType');

    String args = '-i ${shellArgument(inputUri)} '
        '${mediaType == MediaType.video ? '${timeS != null ? '-ss $timeS' : ''} -vframes 1 ' : ''}'
        '-vf ${shellArgument('scale=$w:$h')} '
        '${shellArgument(outputPath)}';
    await runCommand(args);
    return FileSystemEntity.typeSync(outputPath) !=
        FileSystemEntityType.notFound;
  }

  Future<List<ProcessResult>> runCommand(String args) async {
    String command =
        '${shellArgument('$currentPath${binPath}ffmpeg.exe')} $args';
    log('runCommand $command');
    var shell = Shell();
    return await shell.run(command);
  }
}

final xMediaInfo = XMediaInfo.instance;

enum MediaType {
  unknown,
  image,
  video,
  audio,
  subtitle,
}

/// video codecs
const AV_CODEC_ID_MPEG4 = 13;
const AV_CODEC_ID_H264 = 28;
const AV_CODEC_ID_H265 = 174;

/// image codecs
const AV_CODEC_ID_MJPEG = 8;
const AV_CODEC_ID_MJPEGB = 9;
const AV_CODEC_ID_LJPEG = 10;
const AV_CODEC_ID_JPEGLS = 12;
const AV_CODEC_ID_PNG = 62;
const AV_CODEC_ID_BMP = 79;
const AV_CODEC_ID_JPEG2000 = 89;
const AV_CODEC_ID_TIFF = 97;
const AV_CODEC_ID_GIF = 98;
const AV_CODEC_ID_WEBP = 172;
const AV_CODEC_ID_APNG = 32782;
const AV_CODEC_ID_YUV4 = 32776;

/// audio codecs
const AV_CODEC_ID_MP2 = 86016;
const AV_CODEC_ID_DST = 88077;

class MediaInfo {
  String $id;
  int width;
  int height;
  double videoFrameRate;

  /// AV_CODEC_ID_H264 28; AV_CODEC_ID_H265/AV_CODEC_ID_HEVC 174;
  /// AV_CODEC_ID_MJPEG 8; AV_CODEC_ID_MJPEGB 9; AV_CODEC_ID_LJPEG 10; AV_CODEC_ID_JPEGLS 12;
  /// AV_CODEC_ID_PNG 62; AV_CODEC_ID_WEBP 172; AV_CODEC_ID_BMP 79; AV_CODEC_ID_JPEG2000 89;
  /// AV_CODEC_ID_TIFF 97; AV_CODEC_ID_GIF 98; AV_CODEC_ID_APNG 32782; AV_CODEC_ID_YUV4 32776;
  int videoCodecId;
  int audioCodecId;
  int duration;

  MediaInfo({
    this.$id = '',
    this.width = 0,
    this.height = 0,
    this.videoFrameRate = 0,
    this.videoCodecId = 0,
    this.audioCodecId = 0,
    this.duration = 0,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) => MediaInfo(
        $id: json['id'] as String? ?? '',
        width: json['width'] as int? ?? 0,
        height: json['height'] as int? ?? 0,
        videoFrameRate: json['videoFrameRate'] as double? ?? 0,
        videoCodecId: json['videoCodecId'] as int? ?? 0,
        audioCodecId: json['audioCodecId'] as int? ?? 0,
        duration: json['duration'] as int? ?? 0,
      );

  MediaType get type {
    if (videoCodecId != 0) {
      // if(videoCodecId == AV_CODEC_ID_MPEG4
      //     || videoCodecId == AV_CODEC_ID_H264
      //     || videoCodecId == AV_CODEC_ID_H265
      // ) {
      //   return MediaType.video;
      // } else
      if (videoCodecId == AV_CODEC_ID_MJPEG ||
          videoCodecId == AV_CODEC_ID_MJPEGB ||
          videoCodecId == AV_CODEC_ID_LJPEG ||
          videoCodecId == AV_CODEC_ID_JPEGLS ||
          videoCodecId == AV_CODEC_ID_PNG ||
          videoCodecId == AV_CODEC_ID_BMP ||
          videoCodecId == AV_CODEC_ID_JPEG2000 ||
          videoCodecId == AV_CODEC_ID_TIFF ||
          videoCodecId == AV_CODEC_ID_GIF ||
          videoCodecId == AV_CODEC_ID_WEBP ||
          videoCodecId == AV_CODEC_ID_APNG ||
          videoCodecId == AV_CODEC_ID_YUV4) {
        return MediaType.image;
      } else {
        return MediaType.video;
      }
    }
    if (audioCodecId != 0) {
      if (audioCodecId >= AV_CODEC_ID_MP2 && audioCodecId <= AV_CODEC_ID_DST) {
        return MediaType.audio;
      }
    }
    return MediaType.unknown;
  }

  @override
  String toString() {
    return '{width: $width, height: $height, videoFrameRate: $videoFrameRate,'
        ' videoCodecId: $videoCodecId, audioCodecId: $audioCodecId, duration: $duration}';
  }
}
