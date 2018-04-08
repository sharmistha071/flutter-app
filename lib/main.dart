import 'dart:async';
import 'dart:convert' show utf8, json;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gps_coordinates/gps_coordinates.dart';
import 'package:device_info/device_info.dart';

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
  int _counter = 0;
  String barcode = "";
  String encodedData = '';
  // post response message
	String responseMessage = "";
  // device info
  static final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  // for geolocation
  Map<String, double> _coordinates = new Map();

  void initState() {
    super.initState();
    initPlatformState();
    _getCoordinates();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Barcode Scanner Example'),
          ),
          body: new Center(
            child: new Column(
              children: <Widget>[
                new Container(
                  child: new MaterialButton(
                      onPressed: scan, child: new Text("Scan")),
                  padding: const EdgeInsets.all(8.0),
                ),
                //new Text(barcode),
                new Text(responseMessage),
              ],
            ),
          )),
    );
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() => this.barcode = barcode);
      postTest();
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException{
      setState(() => this.barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }

  _getCoordinates() async {
    Map<String, double> coordinates;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      coordinates = await GpsCoordinates.gpsCoordinates;
    } on PlatformException {
      Map<String, double> placeholdCoordinates = new Map();
      placeholdCoordinates["lat"] = 0.0;
      placeholdCoordinates["long"] = 0.0;
      coordinates = placeholdCoordinates;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted)
      return;

    setState(() {
      _coordinates = coordinates;
    });
    print(_coordinates["lat"]);
    print(_coordinates["long"]);
}

  Future<Null> initPlatformState() async {
   Map<String, dynamic> deviceData;

   try {
     if (Platform.isAndroid) {
       deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
     } else if (Platform.isIOS) {
       deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
     }
   } on PlatformException {
     deviceData = <String, dynamic>{
       'Error:': 'Failed to get platform version.'
     };
   }

   if (!mounted) return;

   setState(() {
     _deviceData = deviceData;
   });
   print(_deviceData);
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'brand': build.brand,
      'model': build.model,
    };
  }
  void postTest() async {
    String encodedData = json.encode({
      "barcode": barcode,
      "metadata": _deviceData,
      "lat": _coordinates["lat"],
      "long": _coordinates["long"],
    });
    Map headers = {
			"Content-type": "application/json",
			"Accept": "application/json"
		};
    print(encodedData);
    var url = "http://192.168.1.201:8989/validate/qr-code/";

    http.Response response = await http.post(
				Uri.encodeFull(url),
				body: encodedData,
        headers: headers
		);
    // catch the response message
		String responseMessage = response.body;
		setState(() => this.responseMessage = responseMessage);
  }
}
