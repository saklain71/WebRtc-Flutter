import 'package:flutter/material.dart';
import 'package:webrtc_flutter/test_page.dart';
import 'MyHomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page',),
      home:  const TestPage(),
    );
  }
}




// import 'dart:core';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webrtc_flutter/webAndSocket/Src/call_sample/call_sample.dart';
// import 'package:webrtc_flutter/webAndSocket/Src/call_sample/data_channel_sample.dart';
// import 'package:webrtc_flutter/webAndSocket/Src/route_item.dart';


// void main() => runApp(MyApp());
//
// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => new _MyAppState();
// }
//
// enum DialogDemoAction {
//   cancel,
//   connect,
// }
//
// class _MyAppState extends State<MyApp> {
//   List<RouteItem> items = [];
//   String _server = '';
//   late SharedPreferences _prefs;
//
//   bool _datachannel = false;
//   @override
//   initState() {
//     super.initState();
//     _initData();
//     _initItems();
//   }
//
//   _buildRow(context, item) {
//     return ListBody(children: <Widget>[
//       ListTile(
//         title: Text(item.title),
//         onTap: () => item.push(context),
//         trailing: Icon(Icons.arrow_right),
//       ),
//       Divider()
//     ]);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//           appBar: AppBar(
//             title: Text('Flutter-WebRTC example'),
//           ),
//           body: ListView.builder(
//               shrinkWrap: true,
//               padding: const EdgeInsets.all(0.0),
//               itemCount: items.length,
//               itemBuilder: (context, i) {
//                 return _buildRow(context, items[i]);
//               })),
//     );
//   }
//
//   _initData() async {
//     _prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _server = _prefs.getString('server') ?? 'http://210.4.64.216:';
//     });
//   }
//
//   void showDemoDialog<T>(
//       {required BuildContext context, required Widget child}) {
//     showDialog<T>(
//       context: context,
//       builder: (BuildContext context) => child,
//     ).then<void>((T? value) {
//       // The value passed to Navigator.pop() or null.
//       if (value != null) {
//         if (value == DialogDemoAction.connect) {
//           _prefs.setString('server', _server);
//           Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (BuildContext context) => _datachannel
//                       ? DataChannelSample(host: _server)
//                       : CallSample(host: _server)));
//         }
//       }
//     });
//   }
//
//   _showAddressDialog(context) {
//     showDemoDialog<DialogDemoAction>(
//         context: context,
//         child: AlertDialog(
//             title: const Text('Enter server address:'),
//             content: TextField(
//               onChanged: (String text) {
//                 setState(() {
//                   _server = text;
//                 });
//               },
//               decoration: InputDecoration(
//                 hintText: _server,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             actions: <Widget>[
//               TextButton(
//                   child: const Text('CANCEL'),
//                   onPressed: () {
//                     Navigator.pop(context, DialogDemoAction.cancel);
//                   }),
//               TextButton(
//                   child: const Text('CONNECT'),
//                   onPressed: () {
//                     Navigator.pop(context, DialogDemoAction.connect);
//                   })
//             ]));
//   }
//
//   _initItems() {
//     items = <RouteItem>[
//       RouteItem(
//           title: 'P2P Call Sample',
//           subtitle: 'P2P Call Sample.',
//           push: (BuildContext context) {
//             _datachannel = false;
//             _showAddressDialog(context);
//           }),
//       RouteItem(
//           title: 'Data Channel Sample',
//           subtitle: 'P2P Data Channel.',
//           push: (BuildContext context) {
//             _datachannel = true;
//             _showAddressDialog(context);
//           }),
//     ];
//   }
// }
