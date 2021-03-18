abstract class RTCOfferOptions {
  RTCOfferOptions({
    required bool iceRestart,
    required bool offerToReceiveAudio,
    required bool offerToReceiveVideo,
    required bool voiceActivityDetection,
  });
  bool get iceRestart;
  bool get offerToReceiveAudio;
  bool get offerToReceiveVideo;
  bool get voiceActivityDetection;
}

abstract class RTCAnswerOptions {
  RTCAnswerOptions({required bool voiceActivityDetection});
  bool get voiceActivityDetection;
}

abstract class RTCConfiguration {
  RTCConfiguration({
    required List<RTCIceServer> iceServers,
    required String rtcpMuxPolicy,
    required String iceTransportPolicy,
    required String bundlePolicy,
    required String peerIdentity,
    required int iceCandidatePoolSize,
  });
  List<RTCIceServer> get iceServers;

  ///Optional: 'negotiate' or 'require'
  String get rtcpMuxPolicy;

  ///Optional: 'relay' or 'all'
  String get iceTransportPolicy;

  /// A DOMString which specifies the target peer identity for the
  /// RTCPeerConnection. If this value is set (it defaults to null),
  /// the RTCPeerConnection will not connect to a remote peer unless
  ///  it can successfully authenticate with the given name.
  String get peerIdentity;

  int get iceCandidatePoolSize;

  ///Optional: 'balanced' | 'max-compat' | 'max-bundle'
  String get bundlePolicy;
}

abstract class RTCIceServer {
  RTCIceServer({required String urls, required String username, required String credential});
  // String or List<String>
  dynamic get urls;
  String get username;
  String get credential;
}
