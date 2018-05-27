import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PlotQr extends StatefulWidget {
  String payment;
  String max_scan;
  DateTime date;
  String rndm;

  PlotQr(String payment, String max_scan, DateTime date, String rndm){
    this.payment = payment;
    this.max_scan = max_scan;
    this.date = date;
    this.rndm = rndm;
  }

  @override
  _PlotQrState createState() => new _PlotQrState(this.payment, this.max_scan, this.date);
}

class _PlotQrState extends State<PlotQr> {
  String payment;
  String max_scan;
  DateTime date;


  _PlotQrState(String payment, String max_scan, DateTime date){
    this.payment = payment;
    this.max_scan = max_scan;
    this.date = date;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('QrCode'),
          ),
          body: new Center(
            child: new QrImage(
              data: this.payment + this.max_scan + this.date.toString(),
              size: 200.0,
            ),
          )
        ),
    );
  }
}
