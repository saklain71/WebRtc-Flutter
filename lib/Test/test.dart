import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: MySnackBarAnimated(),
  ));
}

class MySnackBarAnimated extends StatefulWidget {
  @override
  _MySnackBarAnimatedState createState() => _MySnackBarAnimatedState();
}

class _MySnackBarAnimatedState extends State<MySnackBarAnimated>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isShowingSnackBar = false;

  @override
  void initState() {
    super.initState();

    // Create an AnimationController with your desired duration
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  void _showSnackBar() {
    if (!_isShowingSnackBar) {
      setState(() {
        _isShowingSnackBar = true;
      });

      // Slide in the SnackBar
      _controller.forward().then((_) {
        // After the SnackBar duration, slide it out
        Future.delayed(Duration(seconds: 10), () {
          _controller.reverse().then((_) {
            setState(() {
              _isShowingSnackBar = false;
            });
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animated SnackBar'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _showSnackBar,
          child: Text('Show SnackBar'),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _isShowingSnackBar
              ? SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
            ),
            child: SnackBar(
              duration: Duration(seconds: 10),
              backgroundColor: Colors.green,
              content: Text('Calling From ***'),
              action: SnackBarAction(
                label: 'Answer',
                onPressed: () {
                  // Handle action button press
                },
              ),
            ),
          )
              : Container(); // Hide the SnackBar when not showing
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
