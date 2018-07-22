import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
// import 'package:qr_reader/qr_reader.dart';
import 'package:zxing/zxing.dart';


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text("WebScoket Demo"),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            GestureDetector(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Icon(Icons.person, size: 64.0),
                  Text('person')
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return Person();
                  }
                ));
              },
            ),
            GestureDetector(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Icon(Icons.shop, size: 64.0),
                  Text('merchant')
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) => Merchant()
                ));
              },
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


class Status {
  static get start => 'start';
  static get scan => 'scan';
  static get confirm => 'confirm';
  static get finish => 'finish';
}


class Person extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PersonState();
}

class _PersonState extends State<Person> {

  WebSocket _webSocket;
  String status;
  String amount;

  Map<String, String> _info = <String, String>{
    'code': '1234567890'
  };

  @override
  void initState() {
    super.initState();
    initWebSocket();
  }

  void initWebSocket() {
    // change uri here
    WebSocket.connect("ws://192.168.1.108:8080/ws")
        .then((WebSocket webSocket) {
          _webSocket = webSocket;

          // on open
          status = Status.start;
          setState(() {

          });
          webSocket.add(json.encode({
            "type": "subscribe",
            "status": status,
            "key": _info['code'],
            "binding": {
              "a": 10
            }
          }));

          webSocket.listen((data) {
            Map<String, dynamic> result = json.decode(data);
            List<dynamic> status = result['status'].last;
            this.status = status[0];
            if (status[0] == Status.scan) {
              amount = status[1]['amount'];
              setState(() {

              });
            }
          });

          webSocket.handleError(() {
            Future.delayed(Duration(seconds: 1), () {
              initWebSocket();
            });
          });
        });

  }

  @override
  void dispose() {
    _webSocket.add(json.encode({
      "type": "updateStatus",
      "key": _info['code'],
      "status": Status.finish,
      "isLastStatus": true
    }));
    _webSocket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Person'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            QrImage(
              data: json.encode(_info),
              size: 200.0,
            ),
            _buildStatus(),
          ],
        )
      ),
    );
  }

  Widget _buildStatus() {
    if (status == Status.start) {
      return Text('amount: wait merchant to scan');
    }

    if (status == Status.scan) {
      return Text('amount: $amount');
    }

    return Container();
  }
}


class Merchant extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MerchantState();
}

class _MerchantState extends State<Merchant> {

  TextEditingController textEditingController = TextEditingController();
  WebSocket _webSocket;
  Map<String, dynamic> _info;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merchant'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
              child: TextFormField(
                autovalidate: true,
                controller: textEditingController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter amount",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      //String result = await QRCodeReader().setForceAutoFocus(true).scan();
                      List<String> result = await Zxing.scan(isBeep: false, isContinuous: false);
                      if (result != null && result.isNotEmpty) {
                        _info = json.decode(result[0]);
                        initWebSocket();
                      }
                    }),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void initWebSocket() {
    WebSocket.connect("ws://192.168.1.108:8080/ws")
      .then((WebSocket webSocket) {
        _webSocket = webSocket;
        webSocket.add(json.encode({
          "type": "subscribe",
          "key": _info["code"]
        }));

        webSocket.listen((data) {
          Map<String, dynamic> result = json.decode(data);
          List<dynamic> status = result['status'].last;
          if (status[0] == Status.start) {
            webSocket.add(json.encode({
              "key": _info['code'],
              "type": "updateStatus",
              "status": Status.scan,
              "binding": {
                "amount": textEditingController.text,
                "account": "pay_me"
              }
            }));
          }
        });

        webSocket.handleError(() {
          Future.delayed(Duration(seconds: 2), () {
            initWebSocket();
          });
        });
      });
  }
}
