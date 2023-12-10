import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import "../utils/snackbar.dart";

import "descriptor_tile.dart";

class CharacteristicTile extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;

  const CharacteristicTile({Key? key, required this.characteristic, required this.descriptorTiles}) : super(key: key);

  @override
  State<CharacteristicTile> createState() => _CharacteristicTileState();
}

class _CharacteristicTileState extends State<CharacteristicTile> {
  List<int> _value = [];

  late StreamSubscription<List<int>> _lastValueSubscription;

  @override
  void initState() {
    super.initState();
    _lastValueSubscription = widget.characteristic.lastValueStream.listen((value) {
      _value = value;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _lastValueSubscription.cancel();
    super.dispose();
  }

  BluetoothCharacteristic get c => widget.characteristic;

  List<int> registerWifiToDevice() {
    // Burada ssid ve passwordleriyle wifi bilgilerini cihaza gönderiyoruz.
    // Json olarak data yaratılacak ve stringe ardından byte a çevrilip cihaza gönderilecek.
    // Max limit 512 karakter.
    String foo = '[{"ssid":"AndroidAP02C3","password":"nrvt6181"},{"ssid":"Aykut\u2019s iPhone","password":"abc13579"},{"ssid":"SUPERONLINE_Wi-Fi_5628","password":"AQ6Xf5kkN5d4"},{"ssid":"SUPERONLINE_Wi-Fi_2346","password":"2GYeDhNYudSy"}]';
    List<int> bytes = utf8.encode(foo);
    return bytes;
  }

  Future onReadPressed() async {
    try {
      await c.read();
      Snackbar.show(ABC.c, "Read: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Read Error:", e), success: false);
    }
  }

  Future onWritePressed() async {
    try {
      await c.write(registerWifiToDevice(), withoutResponse: c.properties.writeWithoutResponse);
      Snackbar.show(ABC.c, "Write: Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
    }
  }

  Future onSubscribePressed() async {
    try {
      String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
      await c.setNotifyValue(c.isNotifying == false);
      Snackbar.show(ABC.c, "$op : Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
      setState(() {});
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Subscribe Error:", e), success: false);
    }
  }

  Widget buildUuid(BuildContext context) {
    String uuid = '0x${widget.characteristic.uuid.str.toUpperCase()}';
    return Text(uuid, style: TextStyle(fontSize: 13));
  }

  Widget buildValue(BuildContext context) {
    // Burada gelen byte datayı stringe çeviriyoruz.
    String data = utf8.decode(_value);
    return Text(data, style: TextStyle(fontSize: 13, color: Colors.grey));
  }

  Widget buildReadButton(BuildContext context) {
    return TextButton(
        child: Text("Read"),
        onPressed: () async {
          await onReadPressed();
          setState(() {});
        });
  }

  Widget buildWriteButton(BuildContext context) {
    bool withoutResp = widget.characteristic.properties.writeWithoutResponse;
    return TextButton(
        child: Text(withoutResp ? "WriteNoResp" : "Write"),
        onPressed: () async {
          await onWritePressed();
          setState(() {});
        });
  }

  Widget buildSubscribeButton(BuildContext context) {
    bool isNotifying = widget.characteristic.isNotifying;
    return TextButton(
        child: Text(isNotifying ? "Unsubscribe" : "Subscribe"),
        onPressed: () async {
          await onSubscribePressed();
          setState(() {});
        });
  }

  Widget buildButtonRow(BuildContext context) {
    bool read = widget.characteristic.properties.read;
    bool write = widget.characteristic.properties.write;
    bool notify = widget.characteristic.properties.notify;
    bool indicate = widget.characteristic.properties.indicate;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (read) buildReadButton(context),
        if (write) buildWriteButton(context),
        if (notify || indicate) buildSubscribeButton(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: ListTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Characteristic'),
            buildUuid(context),
            buildValue(context),
          ],
        ),
        subtitle: buildButtonRow(context),
        contentPadding: const EdgeInsets.all(0.0),
      ),
      children: widget.descriptorTiles,
    );
  }
}
