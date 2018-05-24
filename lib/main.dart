import 'dart:async';
import 'dart:convert' show utf8, json;
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:gps_coordinates/gps_coordinates.dart';
import 'package:device_info/device_info.dart';
import 'package:qr_flutter/qr_flutter.dart';


import 'plot_qr.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
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
                new Container(
                  child: new MaterialButton(
                      onPressed: _pushSaved, child: new Text("Generate QR")),
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

  // navigate to qrcode Generator page
  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) => new QrGenerator()),
    );
  }
}

class QrGenerator extends StatefulWidget {
  @override
  _QrGeneratorState createState() => new _QrGeneratorState();
}
class _QrGeneratorState extends State<QrGenerator> {
  String payment;
  String max_scan;
  DateTime _dateTime = new DateTime.now();
  var _rndm = new Random().nextInt(1000);

  @override
  void postData(encodedData) {
    Map headers = {
      "Content-type": "application/json",
      "Accept": "application/json"
    };
    var url = "http://localhost:3000/qr";

    http.Response response = await http.post(
        Uri.encodeFull(url),
        body: encodedData,
        headers: headers
    );

    // catch the response message
    // String responseMessage = response.body;
    // print('$responseMessage');
    // setState(() => this.responseMessage = responseMessage);
  }
  void generateQR(payment, max_scan, date) {
    String encodedData = json.encode({
      "payment": payment,
      "max_scan": max_scan,
      "date": date.toString(),
      "rndm": _rndm
    });
    postData(encodedData);
    Navigator.push(
        context,
        new MaterialPageRoute(builder: (context) => new PlotQr(payment, max_scan, date)),
      );
  }

  TextEditingController _paymentController;
  TextEditingController _maxScanNumberController;
  TextEditingController _datePickerController;

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Generate QRCode')
      ),

      body: new Container(
        padding: const EdgeInsets.fromLTRB(8.0, 10.0, 8.0, 8.0),
        child: new Column(
          children: <Widget>[
            new ListTile(
	            leading: new Icon(Icons.euro_symbol),
	            title: new TextField(
		            controller:  _paymentController,
		            decoration: new InputDecoration(
			            labelText: 'Payment',
			            hintText: 'Enter your Payment',
		            ),
                keyboardType: TextInputType.number,
		            autocorrect: true,
		            autofocus: true,
		           	onChanged: (value) => payment = value,
	            ),
            ),
            new ListTile(
              leading: new Icon(Icons.title),
              title: new TextField(
                controller: _maxScanNumberController,
                decoration: new InputDecoration(
                  labelText: 'Max Scan',
                  hintText: 'Max Scan'
                ),
                keyboardType: TextInputType.number,
                autocorrect: true,
                autofocus: true,
                onChanged: (value) => max_scan = value,
              ),
            ),
            new ListTile(
              leading: new Icon(Icons.today),
              title: new DateTimeItem(
                dateTime: _dateTime,
                onChanged: (dateTime) => setState(() => _dateTime = dateTime),
              ),
            ),
            new RaisedButton(
               onPressed: () {
                 generateQR(this.payment, this.max_scan, this._dateTime);},
                 color: Colors.blue,
                 textColor: Colors.white,
                 child: new Text("Save")
             ),
          ]
        )
      ),
    );
  }
}

class DateTimeItem extends StatelessWidget {
  DateTimeItem({Key key, DateTime dateTime, @required this.onChanged})
      : assert(onChanged != null),
        date = dateTime == null
            ? new DateTime.now()
            : new DateTime(dateTime.year, dateTime.month, dateTime.day),
        time = dateTime == null
            ? new DateTime.now()
            : new TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        super(key: key);

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;


  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Expanded(
          child: new InkWell(
            onTap: (() => _showDatePicker(context)),
            child: new Padding(
                padding: new EdgeInsets.symmetric(vertical: 8.0),
                child: new Text(new DateFormat.yMMMd().format(date))),
          ),
        ),
        new InkWell(
          onTap: (() => _showTimePicker(context)),
          child: new Padding(
              padding: new EdgeInsets.symmetric(vertical: 8.0),
              child: new Text(time.format(context)),
          ),
        ),
      ],
    );
  }

  Future _showDatePicker(BuildContext context) async {
    DateTime dateTimePicked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(hours: 1)),
        lastDate: new DateTime.now().add(const Duration(days: 200000))
    );


    if (dateTimePicked != null) {
      onChanged(new DateTime(
          dateTimePicked.year,
          dateTimePicked.month,
          dateTimePicked.day,
          time.hour,
          time.minute)
      );
    }
  }

  Future _showTimePicker(BuildContext context) async {
    TimeOfDay timeOfDay = await showTimePicker(context: context, initialTime: time);
    if (timeOfDay != null) {
      onChanged(new DateTime(
          date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute));
    }
  }
}
