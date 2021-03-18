import 'dart:async';

import 'enums.dart';
import 'media_stream.dart';
import 'rtc_rtp_parameters.dart';
import 'rtc_rtp_receiver.dart';
import 'rtc_rtp_sender.dart';

List<RTCRtpEncoding> listToRtpEncodings(List<Map<String, dynamic>> list) {
  return list.map((e) => RTCRtpEncoding.fromMap(e)).toList();
}

class RTCRtpTransceiverInit {
  RTCRtpTransceiverInit({
    required this.direction,
    required this.streams,
    required this.sendEncodings,
  });
  TransceiverDirection direction;
  List<MediaStream> streams;
  List<RTCRtpEncoding> sendEncodings;
}

abstract class RTCRtpTransceiver {
  RTCRtpTransceiver();

  TransceiverDirection get currentDirection;

  String get mid;

  RTCRtpSender get sender;

  RTCRtpReceiver get receiver;

  bool get stopped;

  String get transceiverId;

  Future<void> setDirection(TransceiverDirection direction);

  Future<TransceiverDirection> getCurrentDirection();

  Future<void> stop();
}
