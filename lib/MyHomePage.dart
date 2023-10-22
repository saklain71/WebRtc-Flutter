import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';



class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();
  final sdpController = TextEditingController();
  bool _offer = false;


  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  initRenderer() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();

  }

  _getUserMedia() async {

    // final Map<String, dynamic> mediaConstraints = {
    //   'audio': true,
      // 'video': {
      //   'facingMode': 'user',
      // }
    // };

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true,
    };

    MediaStream stream =
    await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localVideoRenderer.srcObject = stream;
    return stream;
  }

  _getUserMediaTwo() async{

    final Map<String, dynamic>  mediaConstraintsRemote  = {
      'audio':true,
      'video':true,
    };

    _localStream!.getTracks().forEach((track) {
        print("this is track $track");
        print("this is peerConnection before add $_peerConnection");
        //_peerConnection?.addTrack(track, _localStream!);
    });

    MediaStream streamRemote =
    await navigator.mediaDevices.getUserMedia(mediaConstraintsRemote);
    _remoteVideoRenderer.srcObject = streamRemote;
    return streamRemote;

  }



  _createPeerConnecion() async {

    // Map<String, dynamic> configuration = {
    //   "iceServers": [
    //     {"url": "stun:stun.l.google.com:19302"},
    //   ]
    // };

    Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();


    //_remoteStream = await _getUserMediaTwo();


    RTCPeerConnection pc =
    await createPeerConnection(configuration, offerSdpConstraints);

    // pc.addStream(_localStream!);

    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

   // pc.addStream(_remoteStream!);

    pc.onIceCandidate = (e) {
      print('onIceCandidate');
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      print('onIceConnectionState $e');
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteVideoRenderer.srcObject = stream;
    };

    return pc;
  }



  void _createOffer() async {
    RTCSessionDescription description =
    await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print('session $session');
    //print(json.encode(session));
    var jsonSession = json.encode(session);
    print('createOffer ${jsonSession}');
    _offer = true;
    _peerConnection!.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
    await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print('createAnswer description.sdp $session');
    var jsonSession = json.encode(session);
    print(jsonSession);
    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print('_setRemoteDescription $session');
    String sdp = write(session, null);
    print('_setRemoteDescription sdp  $sdp');
    RTCSessionDescription description =
    RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print('_setRemoteDescription ${description.toMap()}');
    await _peerConnection!.setRemoteDescription(description);
  }

  void _addCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print('addCandidate $session');
    print(session['candidate'][0]);
    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
     await _peerConnection!.addCandidate(candidate);
  }

   void _cutCall() async{
     await _peerConnection!.close();
     await _localVideoRenderer.dispose();
     await _localStream!.dispose();
     // Navigator.pop(context);
  }

  @override
  void initState() {
    initRenderer();
    _createPeerConnecion().then((pc) {
      _peerConnection = pc;
    });
    // _getUserMedia();
    super.initState();
  }

  @override
  void dispose() async {
    await _localVideoRenderer.dispose();
    await _remoteVideoRenderer.dispose();
    _peerConnection!.close();
    sdpController.dispose();
    super.dispose();
  }

  SizedBox videoRenderers() => SizedBox(
    height: 300,
    child: Stack(children: [
      Container(
        width: MediaQuery.of(context).size.width,
        key: const Key('local'),
        margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
        decoration: const BoxDecoration(color: Colors.black),
        child: RTCVideoView(_localVideoRenderer),
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: Container(
          height: 100,
          width: 100,
          key: const Key('remote'),
          margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
          decoration: const BoxDecoration(color: Colors.white),
          child: RTCVideoView(_remoteVideoRenderer),
        ),
      ),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              videoRenderers(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: TextField(
                    controller: sdpController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    maxLength: TextField.noMaxLength,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: _createOffer,
                child: const Text("Offer"),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: _createAnswer,
                child: const Text("Answer"),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: _setRemoteDescription,
                child: const Text("Set Remote Description"),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: _addCandidate,
                child: const Text("Set Candidate"),
              ),
              ElevatedButton(
                onPressed: _cutCall,
                child: const Text("Bye"),
              ),


              // Row(
              //   children: [
              //     // Padding(
              //     //   padding: const EdgeInsets.all(16.0),
              //     //   child: SizedBox(
              //     //     width: MediaQuery.of(context).size.width * 0.5,
              //     //     child: TextField(
              //     //       controller: sdpController,
              //     //       keyboardType: TextInputType.multiline,
              //     //       maxLines: 4,
              //     //       maxLength: TextField.noMaxLength,
              //     //     ),
              //     //   ),
              //     // ),
              //
              //
              //     // Column(
              //     //   crossAxisAlignment: CrossAxisAlignment.center,
              //     //   children: [
              //     //
              //     //     Padding(
              //     //       padding: const EdgeInsets.all(16.0),
              //     //       child: SizedBox(
              //     //         width: MediaQuery.of(context).size.width * 0.5,
              //     //         child: TextField(
              //     //           controller: sdpController,
              //     //           keyboardType: TextInputType.multiline,
              //     //           maxLines: 4,
              //     //           maxLength: TextField.noMaxLength,
              //     //         ),
              //     //       ),
              //     //     ),
              //     //
              //     //     ElevatedButton(
              //     //       onPressed: _createOffer,
              //     //       child: const Text("Offer"),
              //     //     ),
              //     //     const SizedBox(
              //     //       height: 10,
              //     //     ),
              //     //     ElevatedButton(
              //     //       onPressed: _createAnswer,
              //     //       child: const Text("Answer"),
              //     //     ),
              //     //     const SizedBox(
              //     //       height: 10,
              //     //     ),
              //     //     ElevatedButton(
              //     //       onPressed: _setRemoteDescription,
              //     //       child: const Text("Set Remote Description"),
              //     //     ),
              //     //     const SizedBox(
              //     //       height: 10,
              //     //     ),
              //     //     ElevatedButton(
              //     //       onPressed: _addCandidate,
              //     //       child: const Text("Set Candidate"),
              //     //     ),
              //     //     // ElevatedButton(
              //     //     //   onPressed: () async{
              //     //     //     // Assuming _localVideoRenderer is an RTCVideoRenderer
              //     //     //     await _localVideoRenderer.dispose();
              //     //     //     await _localVideoRenderer.initialize();
              //     //     //     setState(() {
              //     //     //
              //     //     //     });
              //     //     //   },
              //     //     //   child: const Text("Refresh local"),
              //     //     // ),
              //     //     // ElevatedButton(
              //     //     //   onPressed: () async{
              //     //     //     // Assuming _localVideoRenderer is an RTCVideoRenderer
              //     //     //     await _remoteVideoRenderer.dispose();
              //     //     //     await _remoteVideoRenderer.initialize();
              //     //     //     setState(() {
              //     //     //
              //     //     //     });
              //     //     //   },
              //     //     //   child: const Text("Refresh Remote"),
              //     //     // ),
              //     //
              //     //   ],
              //     // )
              //
              //   ],
              // ),
            ],
          ),
        ));
  }
}