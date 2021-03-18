import 'dart:async';
import 'dart:html' as html;

import 'package:logging/logging.dart';

import '../interface/media_stream.dart';
import '../interface/media_stream_track.dart';
import 'media_stream_track_impl.dart';

class MediaStreamWeb extends MediaStream {
  MediaStreamWeb(this.jsStream, String ownerTag)
      : super(jsStream?.id ?? '', ownerTag);

  var log = Logger('MediaStreamWeb');
  final html.MediaStream? jsStream;

  @override
  Future<void> getMediaTracks() {
    return Future.value();
  }

  @override
  Future<void> addTrack(MediaStreamTrack track, {bool addToNative = true}) {
    if (addToNative) {
      var _native = track as MediaStreamTrackWeb;
      if (_native.jsTrack != null) {
        jsStream?.addTrack(_native.jsTrack!);
      } else {
        log.warning('addTrack failed as native.jsTrack is null');
      }
    }
    return Future.value();
  }

  @override
  Future<void> removeTrack(MediaStreamTrack track,
      {bool removeFromNative = true}) async {
    if (removeFromNative) {
      var _native = track as MediaStreamTrackWeb;
      if (_native.jsTrack != null) {
        jsStream?.removeTrack(_native.jsTrack!);
      } else {
        log.warning('removeTrack failed as native.jsTrack is null');
      }
    }
  }

  @override
  List<MediaStreamTrack> getAudioTracks() {
    var audioTracks = <MediaStreamTrack>[];
    jsStream
        ?.getAudioTracks()
        .forEach((jsTrack) => audioTracks.add(MediaStreamTrackWeb(jsTrack)));
    return audioTracks;
  }

  @override
  List<MediaStreamTrack> getVideoTracks() {
    var audioTracks = <MediaStreamTrack>[];
    jsStream
        ?.getVideoTracks()
        .forEach((jsTrack) => audioTracks.add(MediaStreamTrackWeb(jsTrack)));
    return audioTracks;
  }

  @override
  Future<void> dispose() async {
    getTracks().forEach((element) {
      element.stop();
    });
    return super.dispose();
  }

  @override
  List<MediaStreamTrack> getTracks() {
    return <MediaStreamTrack>[...getAudioTracks(), ...getVideoTracks()];
  }

  @override
  bool? get active => jsStream?.active ?? false;

  @override
  MediaStream clone() {
    return MediaStreamWeb(jsStream?.clone(), ownerTag);
  }
}
