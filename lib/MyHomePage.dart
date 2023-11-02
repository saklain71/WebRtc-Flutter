import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:webrtc_flutter/test_page.dart';



class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();
  final sdpController = TextEditingController();
  bool _offer = false;
  bool _server = false;

  //final audioPlayer = AudioPlayer();


  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  // AnimationController? _controller;


  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  IO.Socket? socket;
  int? id;
  int? sourchId = 1;
  int? targetId = 2;


  List<Map<String, dynamic>>? jsonCandidate = [];
  List<Map<String, dynamic>> candidateList =[];
  dynamic value;


  initRenderer() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();

    // Create an AnimationController with your desired duration
    // _controller = AnimationController(
    //   vsync: this,
    //   duration: Duration(seconds: 10),
    // );

    // _controller?.forward().then((_) {
    //   // After the SnackBar duration, slide it out
    //   Future.delayed(Duration(seconds: 10), () {
    //     _controller?.reverse().then((_) {
    //     });
    //   });
    // });
  }
  void connect() {
    id = Random().nextInt(100);
    // MessageModel messageModel = MessageModel(sourceId: widget.sourceChat.id.toString(),targetId: );
    socket = IO.io("http://210.4.64.216:5000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });
    socket!.connect();
    socket!.onConnect((data) {

      print("Connected");
      socket!.emit('getSdp', {'id':'$id', 'targetId': '$targetId', 'sourchId':'$sourchId'});

      socket!.on('answerSdp', (answerSdp) async {
        if(answerSdp != null){
           // var data = answerSdp.toString();
          // dynamic jsonString = await json.decode(data);
          // print("answerSdp $answerSdp");
          dynamic jsonString = json.encode(answerSdp);
          print('answerSdp encode $jsonString');
          await setRemoteDescriptionFuncRecieved(jsonString);
        }
      });

      socket!.on('getAnswerCandidate', (getAnswerCandidate) async {
        if(getAnswerCandidate != null){
          // dynamic jsonString = await json.decode(data);
          // print("getAnswerCandidate $getAnswerCandidate");
          // print("getAnswerCandidate ${getAnswerCandidate['candidate']}");
          //jsonCandidate!.add(value);
          await addCandidate(getAnswerCandidate);
        }
      });
      socket!.on('candidate', (candidate)async{
        print('candidate recieved $candidate');
        addCandidate(candidate);
      });

      socket!.on('bye', (dropCall) async {
        print('cut the call recieved $dropCall');
        if(dropCall != null) {
          // _cutCall();
          // cutCall();


          // await  _peerConnection!.close();
          //   _peerConnection = null;
           // _localStream!.dispose();
           // _localVideoRenderer.dispose();
          //  await _localVideoRenderer.dispose();
          //  await _localStream!.dispose();
           // RtcPeerConnection.removeStreamEvent;

           socket!.disconnect();
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const TestPage()));
        }
      });

      socket!.on('disconnectError', (disconnect)async{
        if(disconnect != null){
          _server = false;
        }
      });

    });

    socket!.on("sdpOffer", (data) {
      print("message from server  sdpOffer $data");
      if(data != null){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 10),
              backgroundColor: Colors.green,
              content: const Text('Calling From ***'),
              action: SnackBarAction(
                label: 'Answer',
                onPressed: () async{
                  setRemoteDescriptionFunc(data);
                },
              ),
            ),
        );
        // AnimatedBuilder(
        //   animation: _controller!,
        //   builder: (context, child) {
        //     return  SlideTransition(
        //       position: Tween<Offset>(
        //         begin: Offset(0, 1),
        //         end: Offset.zero,
        //       ).animate(
        //         CurvedAnimation(
        //           parent: _controller!,
        //           curve: Curves.easeOut,
        //         ),
        //       ),
        //       child: SnackBar(
        //         // duration: Duration(seconds: 10),
        //         backgroundColor: Colors.green,
        //         content: Text('Calling From ***'),
        //         action: SnackBarAction(
        //           label: 'Answer',
        //           onPressed: () {
        //             // Handle action button press
        //             // setRemoteDescriptionFunc(data.toString());
        //           },
        //         ),
        //       ),
        //     ); // Hide the SnackBar when not showing
        //   },
        // );
      }
    });

    print(socket!.connected);
    socket!.onDisconnect(
        (_){
          setState(() {
            _server = false;
          });
          print('Connection Disconnection');
        }
            // (_) => print('Connection Disconnection')
    );
    socket!.onConnectError((err) => print("onConnectError $err"));
    socket!.onError((err) => print("onError $err"));
    print(socket!.disconnected);
  }


  _getUserMedia() async {

    // final Map<String, dynamic> mediaConstraints = {
    //   'audio': true,
    //   'video': {
    //     'facingMode': 'user',
    //   }
    // };

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true,
    };

    //  MediaStream? stream = await navigator.mediaDevices.getUserMedia(mediaConstraints)
    //     .then((stream){
    //       print('this is stream $stream');
    // })
    //     .catchError((onError){
    //       print('this is error $onError');
    // });

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localVideoRenderer.srcObject = stream;

    final audioTrack = stream.getAudioTracks().first;
    audioTrack.onUnMute;
    audioTrack.muted;
    audioTrack.enabled;
    audioTrack.getConstraints();


    print('audioTrack  ${audioTrack.onUnMute} ${audioTrack.muted} ${audioTrack.enabled}');

    // _peerConnection?.addTrack(audioTrack, stream);

    // Timer.periodic(const Duration(seconds: 1), (Timer timer) {
    //   bool audioLevel = audioTrack.enabled;
    //   print('Audio level: $audioLevel');
    // });

    // setState(() { });
    return stream;
  }


  _createPeerConnecion() async {

    // Map<String, dynamic> configuration = {
    //   "iceServers": [
    //     {
    //     "url": "stun:stun.l.google.com:19302"
    //     },
    //   ]
    // };
    // if(mounted){
    //   setState(() { });
    // }

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

    RTCPeerConnection pc =
    await createPeerConnection(configuration, offerSdpConstraints);

    // pc.addStream(_localStream!);

    _localStream?.getTracks().forEach((track) {
      //pc.addTrack(track, _localStream!);
      pc.addStream(_localStream!);
      print('local audioi track $track');
      print('local audioi pc $pc');
      print('local track.enabled   ${track.enabled}');
      print('local track.muted   ${track.muted == true}');
      print('local track.onMute   ${track.onMute}');
      print('local track.onUnMute   ${track.onUnMute}');

    });

    // _remoteStream?.getTracks().forEach((track) {
    //   pc.addTrack(track, _remoteStream!);
    // });



    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        // print('candidate');
        // print(json.encode({
        //   'candidate': e.candidate.toString(),
        //   'sdpMid': e.sdpMid.toString(),
        //   'sdpMlineIndex': e.sdpMLineIndex,
        // }));
         value = json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
        });

         candidateList.add(json.decode(value));

        print('candidate $value}');
        print('candidateList $candidateList}');
      }
    };


    pc.onIceConnectionState = (e) {
      print('onIceConnectionState $e');
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      final remoteAudioStream = stream.getAudioTracks();
      print('remoteAudioStream ${remoteAudioStream[0].muted}');

       _remoteVideoRenderer.srcObject = stream;


       bool? mutedValue = remoteAudioStream[0].muted;
       print('mutedValue $mutedValue');
       print('remoteAudioStream  src ${_remoteVideoRenderer.srcObject}');



      // _remoteVideoRenderer.srcObject = stream.getAudioTracks();

      // print('value  $value');
      // socket!.emit('candidate', value);
    };

    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description =
    await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
     var jsonSession = json.encode(session);
     print(jsonSession);
    _offer = true;
    _peerConnection!.setLocalDescription(description);
     socket!.emit('sdpOffer', jsonSession);
  }

    createOffer() async {
    RTCSessionDescription description =
    await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
     var jsonSession = json.encode(session);
     print(jsonSession);
    _offer = true;
    _peerConnection!.setLocalDescription(description);
     socket!.emit('sdpOffer', jsonSession);
  }

  void _createAnswer() async {
    print('called creatanswer');
    RTCSessionDescription description =
    await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print('createAnswer description.sdp $session');
    var jsonSession = json.encode(session);
    print(jsonSession);
    _peerConnection!.setLocalDescription(description);
    print('_createAnswer >>>>>>>>>>>>>>>>>>>>>');
  }


   createAnswerFunc() async {
    print('called creatanswer');
    RTCSessionDescription description =
    await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print('createAnswer description.sdp $session');
    var jsonSession = json.encode(session);
    print("createAnswerFunc $jsonSession");
    _peerConnection!.setLocalDescription(description);
    print('_createAnswer >>>>>>>>>>>>>>>>>>>>>');
    socket!.emit('answerSdp', session);
    print('candidate createAnswerFunc ===============  $value');

    Future.delayed(const Duration(milliseconds: 500), () {
      print('candidate 500 ===============  $value ======');
      if(candidateList.isNotEmpty){
        socket!.emit('candidate', candidateList[0]);
      }
    });
  }

  // get other user sdp to set setRemoteDescription
   setRemoteDescriptionFuncRecieved(String getSdp) async {
    //parse(getSdp.toString());
    //String jsonString = sdpController.text;
     //  Map<String, dynamic> jsonString = getSdp;
    // jsonString = parse(getSdp.sdp.toString());


    print('getSdp >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
    print('getSdp $getSdp');
      dynamic jsonString = await json.decode(getSdp);
     // dynamic jsonStringEncode = json.encode(jsonString);
     // String session = parse(jsonStringEncode.sdp.toString());
      print('session >>>>>>>>>>>>>  $jsonString');
     String sdp = write(jsonString, null);
     print('_setRemoteDescription sdp  $sdp');
    RTCSessionDescription description =
    RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print('_setRemoteDescription ${description.toMap()}');
    _peerConnection!.setRemoteDescription(description);
    print('set>>>>>>>>>>>>>>>>>>>>>');

    //socket.emit('getAnswerCandidate', value);
    //createAnswerFunc();
  }

  // answer the call to set setRemoteDescription
   setRemoteDescriptionFunc(String getSdp) async {
    //parse(getSdp.toString());
    //String jsonString = sdpController.text;
     //  Map<String, dynamic> jsonString = getSdp;
    // jsonString = parse(getSdp.sdp.toString());
    print('getSdp >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
    print('getSdp $getSdp');
      dynamic jsonString = await json.decode(getSdp);
     // dynamic jsonStringEncode = json.encode(jsonString);
     // String session = parse(jsonStringEncode.sdp.toString());
      print('session >>>>>>>>>>>>>  $jsonString');
     String sdp = write(jsonString, null);
     print('_setRemoteDescription sdp  $sdp');
    RTCSessionDescription description =
    RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print('_setRemoteDescription ${description.toMap()}');
     _peerConnection!.setRemoteDescription(description);
    print('set>>>>>>>>>>>>>>>>>>>>>');
    await createAnswerFunc();
    print('candidate >>>>>>>>>>>>>>>>>>> $value');
  }

   addCandidate(getCandidate) async {
    print('addcandidate >>>>>> $getCandidate');
      //dynamic session1 =  json.encode(getSdp);
      //print('addcandidate $session1');

      dynamic session = getCandidate;
    // dynamic session =  json.decode(jsonString);
    // print('addcandidate >>>>>> $session');
     // dynamic session =  json.decode(getCandidate);
    // print('addcandidate >>>>>> $session');
      //dynamic session2 =  json.decode(jsonString);
    print('addcandidate $session');
    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'].toString(), session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
    print('Successful peering');
  }


  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    print('jsonString $jsonString');
    dynamic session = await jsonDecode(jsonString);
    print('session $session');
    String sdp = write(session, null);

    RTCSessionDescription description =
    RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print(description.toMap());
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
     socket!.disconnect();
     socket!.emit('bye', 'cutCall');
     //Navigator.pop(context, MaterialPageRoute(builder: (context)=> TestPage()));
     Navigator.pop(context);
  }

  cutCall() async{



    //   _peerConnection = null;

     // await _peerConnection!.close();
     // await _localStream!.dispose();
     // await _localVideoRenderer.dispose();

    // await _localVideoRenderer.dispose();
    // await _localStream!.dispose();



    socket!.emit('bye', 'cutCall');
    socket!.disconnect();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const TestPage()));
    //Navigator.pop(context);
  }

  @override
  void initState() {
    connect();
    initRenderer();
    _createPeerConnecion().then((pc) {
      _peerConnection = pc;
    });

    // _getUserMedia();
    super.initState();
  }

  @override
  void dispose()  {
    _localVideoRenderer.dispose();
    _localVideoRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.dispose();

    // await _localVideoRenderer.dispose();
    // // _peerConnection!.close();
    // sdpController.dispose();
    // //_controller!.dispose();
    // if (_peerConnection != null) {
    //   _peerConnection!.close();
    // }
    if(mounted){
      setState(() {

      });
    }
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
      key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              children: [
                videoRenderers(),

                // Padding(
                //   padding: const EdgeInsets.all(16.0),
                //   child: SizedBox(
                //     width: MediaQuery.of(context).size.width * 0.5,
                //     child: TextField(
                //       controller: sdpController,
                //       keyboardType: TextInputType.multiline,
                //       maxLines: 4,
                //       maxLength: TextField.noMaxLength,
                //     ),
                //   ),
                // ),

                    const SizedBox(
                          height: 20,
                        ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      // onPressed: _createOffer,
                      onPressed: () {
                        if(socket!.connected == true){
                          // (_) => _createOffer;
                           createOffer();
                        }else{
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              // duration: const Duration(seconds: 1),
                              backgroundColor: Colors.red,
                              content: const Text('Server Error ***'),
                            ),
                          );
                        }
                      },
                      child: const Text("Call",
                        style: TextStyle(
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 100,),
                    ElevatedButton(
                      onPressed: cutCall,
                      child: const Text("Bye",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                )
                // const SizedBox(
                //   height: 10,
                // ),
                // ElevatedButton(
                //   onPressed: _createAnswer,
                //   child: const Text("Answer"),
                // ),
                // const SizedBox(
                //   height: 10,
                // ),
                // ElevatedButton(
                //   onPressed: _setRemoteDescription,
                //   // onPressed: (){
                //   //   //_setRemoteDescription('abcd');
                //   // },
                //   child: const Text("Set Remote Description"),
                // ),
                // const SizedBox(
                //   height: 10,
                // ),
                // ElevatedButton(
                //   onPressed: _addCandidate,
                //   child: const Text("Set Candidate"),
                // ),
                // ElevatedButton(
                //   onPressed: _cutCall,
                //   child: const Text("Bye"),
                // ),


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
          ),
        ));
  }
}