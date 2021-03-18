import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as jsutil;

import 'package:flutter_webrtc/src/interface/rtc_track_event.dart';
import 'package:flutter_webrtc/src/web/rtc_rtp_transceiver_impl.dart';

import '../interface/enums.dart';
import '../interface/media_stream.dart';
import '../interface/media_stream_track.dart';
import '../interface/rtc_data_channel.dart';
import '../interface/rtc_dtmf_sender.dart';
import '../interface/rtc_ice_candidate.dart';
import '../interface/rtc_peerconnection.dart';
import '../interface/rtc_rtp_receiver.dart';
import '../interface/rtc_rtp_sender.dart';
import '../interface/rtc_rtp_transceiver.dart';
import '../interface/rtc_session_description.dart';
import '../interface/rtc_stats_report.dart';
import 'media_stream_impl.dart';
import 'media_stream_track_impl.dart';
import 'rtc_data_channel_impl.dart';
import 'rtc_dtmf_sender_impl.dart';
import 'rtc_rtp_receiver_impl.dart';
import 'rtc_rtp_sender_impl.dart';

import 'package:logging/logging.dart';

/*
 *  PeerConnection
 */
class RTCPeerConnectionWeb extends RTCPeerConnection {
  RTCPeerConnectionWeb(this._peerConnectionId, this._jsPc) {
    _jsPc.onAddStream.listen((mediaStreamEvent) {
      final jsStream = mediaStreamEvent.stream;
      final _remoteStream = _remoteStreams.putIfAbsent(jsStream?.id ?? '',
          () => MediaStreamWeb(jsStream, _peerConnectionId));

      onAddStream?.call(_remoteStream);

      jsStream?.onAddTrack.listen((mediaStreamTrackEvent) {
        final jsTrack =
            (mediaStreamTrackEvent as html.MediaStreamTrackEvent).track;
        if (jsTrack == null) {
          log.warning('Track not added to remote stream as jsTrack is null');
        } else {
          final track = MediaStreamTrackWeb(jsTrack);
          _remoteStream.addTrack(track, addToNative: false).then((_) {
            onAddTrack?.call(_remoteStream, track);
          });
        }
      });

      if (jsStream == null) {
        log.warning('onRemoveTrack listener not started as jsStream is null');
      } else {
        jsStream.onRemoveTrack.listen((mediaStreamTrackEvent) {
          final jsTrack =
              (mediaStreamTrackEvent as html.MediaStreamTrackEvent).track;
          if (jsTrack == null) {
            log.warning('Track not removed as jsTrack is null');
          } else {
            final track = MediaStreamTrackWeb(jsTrack);
            _remoteStream.removeTrack(track, removeFromNative: false).then((_) {
              onRemoveTrack?.call(_remoteStream, track);
            });
          }
        });
      }
    });

    _jsPc.onDataChannel.listen((dataChannelEvent) {
      if (dataChannelEvent.channel != null) {
        onDataChannel?.call(RTCDataChannelWeb(dataChannelEvent.channel!));
      } else {
        log.warning('onDataChannel not called as channel is null');
      }
    });

    _jsPc.onIceCandidate.listen((iceEvent) {
      if (iceEvent.candidate != null) {
        onIceCandidate?.call(_iceFromJs(iceEvent.candidate!));
      }
    });

    _jsPc.onIceConnectionStateChange.listen((_) {
      if (_jsPc.iceConnectionState != null) {
        _iceConnectionState =
            iceConnectionStateForString(_jsPc.iceConnectionState!);
        if (_iceConnectionState != null) {
          onIceConnectionState?.call(_iceConnectionState!);
        }
      }
    });

    jsutil.setProperty(_jsPc, 'onicegatheringstatechange', js.allowInterop((_) {
      _iceGatheringState = iceGatheringStateforString(_jsPc.iceGatheringState!);
      onIceGatheringState?.call(_iceGatheringState!);
    }));

    _jsPc.onRemoveStream.listen((mediaStreamEvent) {
      var mediaStream = mediaStreamEvent.stream;
      if (mediaStream != null) {
        final _remoteStream = _remoteStreams.remove(mediaStream.id);
        if (_remoteStream != null) {
          onRemoveStream?.call(_remoteStream);
        }
      }
    });

    _jsPc.onSignalingStateChange.listen((_) {
      if (_jsPc.signalingState != null) {
        _signalingState = signalingStateForString(_jsPc.signalingState!);
        if (_signalingState != null) {
          onSignalingState?.call(_signalingState!);
        }
      }
    });

    _jsPc.onIceConnectionStateChange.listen((_) {
      if (_jsPc.iceConnectionState != null) {
        _connectionState =
            peerConnectionStateForString(_jsPc.iceConnectionState!);
        if (_connectionState != null) {
          onConnectionState?.call(_connectionState!);
        }
      }
    });

    _jsPc.onNegotiationNeeded.listen((_) {
      onRenegotiationNeeded?.call();
    });

    _jsPc.onTrack.listen((trackEvent) {
      onTrack?.call(RTCTrackEvent(
          track: MediaStreamTrackWeb(trackEvent.track),
          receiver: RTCRtpReceiverWeb(trackEvent.receiver),
          transceiver: RTCRtpTransceiverWeb.fromJsObject(
              jsutil.getProperty(trackEvent, 'transceiver'),
              peerConnectionId: _peerConnectionId),
          streams: trackEvent.streams
              .map((e) => MediaStreamWeb(e, _peerConnectionId))
              .toList()));
    });
  }

  static final log = Logger('RTCPeerConnectionWeb');

  final String _peerConnectionId;
  final html.RtcPeerConnection _jsPc;
  final _localStreams = <String, MediaStream>{};
  final _remoteStreams = <String, MediaStream>{};
  final _configuration = <String, dynamic>{};

  RTCSignalingState? _signalingState;
  RTCIceGatheringState? _iceGatheringState;
  RTCIceConnectionState? _iceConnectionState;
  RTCPeerConnectionState? _connectionState;

  @override
  RTCSignalingState? get signalingState => _signalingState;

  @override
  RTCIceGatheringState? get iceGatheringState => _iceGatheringState;

  @override
  RTCIceConnectionState? get iceConnectionState => _iceConnectionState;

  @override
  RTCPeerConnectionState? get connectionState => _connectionState;

  @override
  Future<void> dispose() {
    _jsPc.close();
    return Future.value();
  }

  @override
  Map<String, dynamic> get getConfiguration => _configuration;

  @override
  Future<void> setConfiguration(Map<String, dynamic> configuration) {
    _configuration.addAll(configuration);

    _jsPc.setConfiguration(configuration);
    return Future.value();
  }

  @override
  Future<RTCSessionDescription> createOffer(
      [Map<String, dynamic> constraints]) async {
    final offer = await _jsPc.createOffer(constraints);
    return _sessionFromJs(offer);
  }

  @override
  Future<RTCSessionDescription> createAnswer(
      [Map<String, dynamic> constraints]) async {
    final answer = await _jsPc.createAnswer(constraints);
    return _sessionFromJs(answer);
  }

  @override
  Future<void> addStream(MediaStream stream) {
    var _native = stream as MediaStreamWeb;
    _localStreams.putIfAbsent(
        stream.id, () => MediaStreamWeb(_native.jsStream, _peerConnectionId));
    _jsPc.addStream(_native.jsStream);
    return Future.value();
  }

  @override
  Future<void> removeStream(MediaStream stream) async {
    var _native = stream as MediaStreamWeb;
    _localStreams.remove(stream.id);
    _jsPc.removeStream(_native.jsStream);
    return Future.value();
  }

  @override
  Future<void> setLocalDescription(RTCSessionDescription description) async {
    await _jsPc.setLocalDescription(description.toMap());
  }

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _jsPc.setRemoteDescription(description.toMap());
  }

  @override
  Future<RTCSessionDescription> getLocalDescription() async {
    return _sessionFromJs(_jsPc.localDescription);
  }

  @override
  Future<RTCSessionDescription> getRemoteDescription() async {
    return _sessionFromJs(_jsPc.remoteDescription);
  }

  @override
  Future<void> addCandidate(RTCIceCandidate candidate) async {
    try {
      Completer completer = Completer<void>();
      var success = js.allowInterop(() => completer.complete());
      var failure = js.allowInterop((e) => completer.completeError(e));
      jsutil.callMethod(
          _jsPc, 'addIceCandidate', [_iceToJs(candidate), success, failure]);

      return completer.future;
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Future<List<StatsReport>> getStats([MediaStreamTrack? track]) async {
    var stats;
    if (track != null) {
      var jsTrack = (track as MediaStreamTrackWeb).jsTrack;
      stats = await jsutil.promiseToFuture<dynamic>(
          jsutil.callMethod(_jsPc, 'getStats', [jsTrack]));
    } else {
      stats = await _jsPc.getStats();
    }

    var report = <StatsReport>[];
    stats.forEach((key, value) {
      report.add(
          StatsReport(value['id'], value['type'], value['timestamp'], value));
    });
    return report;
  }

  @override
  List<MediaStream> getLocalStreams() {
    var map =
        _jsPc.getLocalStreams().map((jsStream) => _localStreams[jsStream.id]);

    var streams = <MediaStream>[];
    for (var stream in map) {
      if (stream != null) {
        streams.add(stream);
      }
    }
    return streams;
  }

  @override
  List<MediaStream> getRemoteStreams() {
    var map =
        _jsPc.getRemoteStreams().map((jsStream) => _remoteStreams[jsStream.id]);

    var streams = <MediaStream>[];
    for (var stream in map) {
      if (stream != null) {
        streams.add(stream);
      }
    }
    return streams;
  }

  @override
  Future<RTCDataChannel> createDataChannel(
      String label, RTCDataChannelInit dataChannelDict) {
    final map = dataChannelDict.toMap();
    if (dataChannelDict.binaryType == 'binary') {
      map['binaryType'] = 'arraybuffer'; // Avoid Blob in data channel
    }

    final jsDc = _jsPc.createDataChannel(label, map);
    return Future.value(RTCDataChannelWeb(jsDc));
  }

  @override
  Future<void> close() async {
    _jsPc.close();
    return Future.value();
  }

  @override
  RTCDTMFSender createDtmfSender(MediaStreamTrack track) {
    var _native = track as MediaStreamTrackWeb;
    var jsDtmfSender = _jsPc.createDtmfSender(_native.jsTrack);
    return RTCDTMFSenderWeb(jsDtmfSender);
  }

  //
  // utility section
  //

  RTCIceCandidate _iceFromJs(html.RtcIceCandidate candidate) => RTCIceCandidate(
        candidate.candidate,
        candidate.sdpMid,
        candidate.sdpMLineIndex,
      );

  html.RtcIceCandidate _iceToJs(RTCIceCandidate c) =>
      html.RtcIceCandidate(c.toMap());

  RTCSessionDescription _sessionFromJs(html.RtcSessionDescription sd) =>
      RTCSessionDescription(sd.sdp, sd.type);

  @override
  Future<RTCRtpSender> addTrack(MediaStreamTrack track,
      [MediaStream? stream]) async {
    var jStream = (stream as MediaStreamWeb).jsStream;
    var jsTrack = (track as MediaStreamTrackWeb).jsTrack;
    if (jStream == null) {
      throw 'addTrack failed as jStream is null';
    }
    var sender = _jsPc.addTrack(jsTrack, jStream);
    return RTCRtpSenderWeb.fromJsSender(sender);
  }

  @override
  Future<bool> removeTrack(RTCRtpSender sender) async {
    var nativeSender = sender as RTCRtpSenderWeb;
    var nativeTrack = nativeSender.track as MediaStreamTrackWeb;
    return jsutil.callMethod(_jsPc, 'removeTrack', [nativeTrack.jsTrack]);
  }

  @override
  Future<List<RTCRtpSender>> getSenders() async {
    var senders = jsutil.callMethod(_jsPc, 'getSenders', []);
    var list = <RTCRtpSender>[];
    senders.forEach((e) {
      list.add(RTCRtpSenderWeb.fromJsSender(e));
    });
    return list;
  }

  @override
  Future<List<RTCRtpReceiver>> getReceivers() async {
    var receivers = jsutil.callMethod(_jsPc, 'getReceivers', []);

    var list = <RTCRtpReceiver>[];
    receivers.forEach((e) {
      list.add(RTCRtpReceiverWeb(e));
    });

    return list;
  }

  @override
  Future<List<RTCRtpTransceiver>> getTransceivers() async {
    var transceivers = jsutil.callMethod(_jsPc, 'getTransceivers', []);

    var list = <RTCRtpTransceiver>[];
    transceivers.forEach((e) {
      list.add(RTCRtpTransceiverWeb.fromJsObject(e));
    });

    return list;
  }

  //'audio|video', { 'direction': 'recvonly|sendonly|sendrecv' }
  @override
  Future<RTCRtpTransceiver> addTransceiver(
      {required MediaStreamTrack track,
      RTCRtpMediaType? kind,
      RTCRtpTransceiverInit? init}) async {
    var kindLabel = kind != null ? typeRTCRtpMediaTypetoString[kind] : null;
    var kindOrTrack = kindLabel ?? (track as MediaStreamTrackWeb).jsTrack;
    final jsOptions = jsutil
        .jsify(init != null ? RTCRtpTransceiverInitWeb.initToMap(init) : {});
    var transceiver =
        jsutil.callMethod(_jsPc, 'addTransceiver', [kindOrTrack, jsOptions]);
    return RTCRtpTransceiverWeb.fromJsObject(transceiver,
        peerConnectionId: _peerConnectionId);
  }
}
