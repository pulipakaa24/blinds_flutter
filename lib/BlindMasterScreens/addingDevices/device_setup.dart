import 'dart:async';
import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterScreens/addingDevices/set_device_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceSetup extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceSetup({super.key, required this.device});

  @override
  State<DeviceSetup> createState() => _DeviceSetupState();
}

class _DeviceSetupState extends State<DeviceSetup> {
  List<BluetoothService> _services = [];

  List<String> openNetworks = [];
  List<String> pskNetworks = [];

  late StreamSubscription<List<int>> _ssidSub;
  StreamSubscription<List<int>>? _confirmSub;
  
  Widget? wifiList;
  String? message;
  String? password;

  final passControl = TextEditingController();

  @override void initState() {
    super.initState();
    initSetup();
  }

  @override
  void dispose() {
    _ssidSub.cancel();
    _confirmSub?.cancel();
    passControl.dispose();
    super.dispose();
  }

  Future setWifiListListener(BluetoothCharacteristic ssidListChar) async {
    setState(() {
      wifiList = null;
    });
    await ssidListChar.setNotifyValue(true);

    _ssidSub = ssidListChar.onValueReceived.listen((List<int> value) {
      List<String> ssidList = [];
      bool noNetworks = false;

      try {
        final val = utf8.decode(value);
        if (val == ';') noNetworks = true;
        ssidList = val
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
        openNetworks = ssidList
          .where((s) => s.split(',')[1] == "OPEN")
          .map((s) => s.split(',')[0])
          .toList();
        pskNetworks = ssidList
          .where((s) => s.split(',')[1] == "SECURED")
          .map((s) => s.split(',')[0])
          .toList();
      } catch (e) {
        if(!mounted)return;
        ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      }

      setState(() {
        wifiList = noNetworks
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(
                      child: Text(
                        "No networks found...",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                )
              : ssidList.isNotEmpty
              ? ListView(
                  children: [
                    ...buildSSIDs()
                  ],
                )
              : null;
      });
    });
  }

  List<Widget> buildSSIDs() {
    List<Widget> open = openNetworks.map((s) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.wifi),
          title: Text(s),
          trailing: const Icon(Icons.arrow_forward_ios_rounded),
          onTap: () {
            openConnect(s);
          },
        ),
      );
    }).toList();
    List<Widget> secure = pskNetworks.map((s) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.wifi_password),
          title: Text(s),
          trailing: const Icon(Icons.arrow_forward_ios_rounded),
          onTap: () {
            setPassword(s);
          },
        ),
      );
    }).toList();
    return open + secure;
  }

  Future openConnect(String ssid) async {
    await transmitWiFiDetails(ssid, "");
  }

  Future discoverServices() async{
    try {
      _services = await widget.device.discoverServices();
    } catch (e) {
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
      return;
    }

    try {
      _services = _services.where((s) => s.uuid.str.toUpperCase() == "181C").toList();
      if (_services.length != 1) throw Exception("Invalid Bluetooth Broadcast");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      return;
    }
  }

  Future initSetup() async {
    await discoverServices();
    final ssidListChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0000");
    await setWifiListListener(ssidListChar);
    refreshWifiList();
  }

  Future setPassword(String ssid) async {
    String? password = await showDialog(
      context: context, 
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            ssid,
            style: GoogleFonts.aBeeZee(),
          ),
          content: Form(
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: TextFormField(
              controller: passControl,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Enter password"),
              validator: (value) {
                if (value == null) return "null input";
                if (value.length < 8) return "not long enough!";
                return null;
              },
              textInputAction: TextInputAction.send,
              onFieldSubmitted: (value) => Navigator.pop(dialogContext, passControl.text),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                passControl.clear();
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, passControl.text);
                passControl.clear();
              },
              child: const Text("Connect"),
            ),
          ],
        );
      }
    );

    await transmitWiFiDetails(ssid, password);
  }

  Future transmitWiFiDetails(String ssid, String? password) async {
    if (password == null) return;

    setState(() {
      wifiList = null;
      message = "Attempting Connection...";
    });

    final ssidEntryChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0001");
    try {
      try {
        await ssidEntryChar.write(utf8.encode(ssid), withoutResponse: ssidEntryChar.properties.writeWithoutResponse);
      } catch (e) {
        throw Exception("SSID Write Error");
      }
    } catch (e){
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      refreshWifiList();
      return;
    }

    final passEntryChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0002");
    try {
      try {
        await passEntryChar.write(utf8.encode(password), withoutResponse: passEntryChar.properties.writeWithoutResponse);
      } catch (e) {
        throw Exception("Password Write Error");
      }
    } catch (e){
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      refreshWifiList();
      return;
    }

    final connectConfirmChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0005");
    final tokenEntryChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0003");
    await connectConfirmChar.setNotifyValue(true);
    _confirmSub = connectConfirmChar.onValueReceived.listen((List<int> connectVal) {
      try {
      final connectResponse = utf8.decode(connectVal);
      if (connectResponse == "Connected") {
        if (!mounted) return;
        _confirmSub?.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetDeviceName(tokenEntryChar: tokenEntryChar, device: widget.device),
          )
        ).then((_) {
          if (widget.device.isConnected) {
            refreshWifiList();
          }
        });
      } else if (connectResponse == "Error") {
        _confirmSub?.cancel();
        throw Exception("SSID/Password Incorrect");
      }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
        refreshWifiList();
        return;
      }
    });
  }

  Future refreshWifiList() async{
    final ssidRefreshChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0004");
    setState(() {
      message = null;
    });
    
    try {
      try {
        await ssidRefreshChar.write(utf8.encode("refresh"), withoutResponse: ssidRefreshChar.properties.writeWithoutResponse);
      } catch (e) {
        throw Exception ("Refresh Error");
      }
    } catch (e) {
      if (!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select WiFi Network",
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: RefreshIndicator(
        onRefresh: refreshWifiList,
        child: wifiList ?? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColorLight,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                message ?? "Fetching Networks...",
                textAlign: TextAlign.center,
              )
            ]
          ),
        )
      ),
    );
  }
}