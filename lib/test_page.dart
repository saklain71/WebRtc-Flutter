import 'package:flutter/material.dart';

import 'MyHomePage.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: InkWell(
          onTap: (){
            Navigator.push(context, MaterialPageRoute(
                builder: (context)=> const MyHomePage(title: "Flutter Demo Home Page")
            ));
          },
          child:  const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Calling Page")
            ],
          ),
        ),
      ),
    );
  }
}
