import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;



class MyHomeToSocket extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomeToSocket> {
  RTCVideoRenderer? _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer? _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  IO.Socket? socket;

  bool isAudioEnabled = true;
  bool isVideoEnabled = true;
  bool isCalling = false;
  bool isReceivingCall = false;

  @override
  void initState() {
    super.initState();
    _localRenderer!.initialize();
    _remoteRenderer!.initialize();
    connect();
  }


  void connect() {

    socket = IO.io("http://210.4.64.216:3000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });
    socket!.connect();

    socket!.onConnect((data) {
      print("Connected");
      socket!.emit('offer',(offer){

      });

      socket!.on('recieveMessage', (msg) {

      });
    });



    print(socket!.connected);
    socket!.onDisconnect((_) => print('Connection Disconnection'));
    socket!.onConnectError((err) => print("onConnectError $err"));
    socket!.onError((err) => print("onError $err"));
    print(socket!.disconnected);

  }


  Future<void> _createPeerConnection() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ],
    };
    final pc = await createPeerConnection(configuration, {});
    pc.onIceCandidate = (candidate) {
      // Handle ICE candidate events
    };
    pc.onIceConnectionState = (state) {
      // Handle ICE connection state changes
    };
    pc.onAddStream = (stream) {
      // Handle remote stream, including video and audio
      _remoteRenderer!.srcObject = stream;
    };

    // Add local audio and video streams
    final mediaStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioEnabled,
      'video': isVideoEnabled,
    });
    mediaStream.getTracks().forEach((track) {
      pc.addTrack(track, mediaStream);
    });

    setState(() {
      _peerConnection = pc;
    });
  }

  void _startCall() {
    // Create a call, set isCalling to true, and initiate signaling
    _createPeerConnection().then((_) {
      // Implement signaling for call initiation
      setState(() {
        isCalling = true;
      });
    });
  }

  void _answerCall() {
    // Answer an incoming call, initiate signaling, and set isReceivingCall to false
    _createPeerConnection().then((_) {
      // Implement signaling to answer the call
      setState(() {
        isReceivingCall = false;
      });
    });
  }

  @override
  void dispose() {
    _localRenderer!.dispose();
    _remoteRenderer!.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Flutter WebRTC Video Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RTCVideoView(_remoteRenderer!),
            SizedBox(height: 20.0),
            if (isCalling)
              ElevatedButton(
                onPressed: () {
                  // Implement hang up logic
                },
                child: Text('End Call'),
              )
            else if (isReceivingCall)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      _answerCall();
                    },
                    child: Text('Answer Call'),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      _startCall();
                    },
                    child: Text('Call'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Toggle audio state
                      setState(() {
                        isAudioEnabled = !isAudioEnabled;
                      });
                    },
                    child: Text(isAudioEnabled ? 'Mute Audio' : 'Unmute Audio'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Toggle video state
                      setState(() {
                        isVideoEnabled = !isVideoEnabled;
                      });
                    },
                    child: Text(isVideoEnabled ? 'Disable Video' : 'Enable Video'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
