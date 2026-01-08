import 'dart:async';
import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterScreens/addingDevices/set_device_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';


enum authTypes {
  OPEN,
  WEP,
  WPA_PSK,
  WPA2_PSK,
  WPA_WPA2_PSK,
  WPA2_ENTERPRISE,
  WPA3_PSK,
  WPA2_WPA3_PSK,
  WAPI_PSK,
  OWE,
  WPA3_ENT_192,
  WPA3_EXT_PSK,
  WPA3_EXT_PSK_MIXED_MODE,
  DPP,
  WPA3_ENTERPRISE,
  WPA2_WPA3_ENTERPRISE,
  WPA_ENTERPRISE
}

const List<authTypes> enterprise = [
  authTypes.WPA_ENTERPRISE,authTypes.WPA2_ENTERPRISE,
  authTypes.WPA3_ENTERPRISE,authTypes.WPA2_WPA3_ENTERPRISE,
  authTypes.WPA3_ENT_192
];

class DeviceSetup extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceSetup({super.key, required this.device});

  @override
  State<DeviceSetup> createState() => _DeviceSetupState();
}

class _DeviceSetupState extends State<DeviceSetup> {
  bool refreshing = false;
  List<BluetoothService> _services = [];
  int maxPorts = 4; // Default to multi-port

  List<Map<String, dynamic>> networks = [];

  late StreamSubscription<List<int>> _ssidSub;
  StreamSubscription<List<int>>? _confirmSub;
  
  Widget? wifiList;
  String? message;

  final passControl = TextEditingController();
  final unameControl = TextEditingController();
  bool _obscureWifiPassword = true;

  @override void initState() {
    super.initState();
    // Detect device type from platform name
    final deviceName = widget.device.platformName;
    if (deviceName == "BlindMaster-C6") {
      maxPorts = 1;
    } else if (deviceName == "BlindMaster Device") {
      maxPorts = 4;
    }
    initSetup();
  }

  @override
  void dispose() {
    _ssidSub.cancel();
    _confirmSub?.cancel();
    passControl.dispose();
    super.dispose();
  }

  Future setRefreshListener(BluetoothCharacteristic ssidRefreshChar, BluetoothCharacteristic ssidListChar) async {
    await ssidRefreshChar.setNotifyValue(true);

    _ssidSub = ssidRefreshChar.onValueReceived.listen((List<int> value) async {
      try {
        final command = utf8.decode(value);
        if (command == "Ready") {
          // Device is ready, now read the WiFi list
          List<int> rawData = await ssidListChar.read();

          try {
            final val = utf8.decode(rawData);
            final decoded = json.decode(val) as List;
            networks = decoded.map((e) => e as Map<String, dynamic>).toList();
          } catch (e) {
            if(!mounted)return;
            ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
          }

          // Acknowledge completion
          try {
            await ssidRefreshChar.write(utf8.encode("Done"), withoutResponse: ssidRefreshChar.properties.writeWithoutResponse);
          } catch (e) {
            if(!mounted)return;
            ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(Exception("Failed to send Done")));
          }

          if(!mounted)return;
          setState(() {
            wifiList = networks.isEmpty
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
                  : ListView(
                      children: [
                        ...buildSSIDs()
                      ],
                    );
          });
          try {
            await ssidRefreshChar.write(utf8.encode("Done"), withoutResponse: ssidRefreshChar.properties.writeWithoutResponse);
          } catch (e) {
            throw Exception ("Handshake Termination Error. Restart setup process.");
          }
          refreshing = false;
        }
      } catch (e) {
        if(!mounted)return;
        ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      }
    });
  }

  List<Widget> buildSSIDs() {
    List<Widget> networkList = networks.map((s) {
      return Card(
        child: ListTile(
          leading: Icon((s["rssi"] as int < -70) ? Icons.wifi_1_bar : ((s["rssi"] as int < -50) ? Icons.wifi_2_bar: Icons.wifi)),
          title: Text(s["ssid"] as String),
          subtitle: Text(authTypes.values[s["auth"] as int].name),
          trailing: const Icon(Icons.arrow_forward_ios_rounded),
          onTap: () {
            authenticate(s);
          },
        ),
      );
    }).toList();
    return networkList;
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
    final ssidRefreshChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0004");
    await setRefreshListener(ssidRefreshChar, ssidListChar);
    refreshWifiList();
  }

  bool isEnterprise(Map<String, dynamic> network) {
    authTypes type = authTypes.values[network["auth"] as int];
    return enterprise.contains(type);
  }
  
  bool isOpen(Map<String, dynamic> network) {
    authTypes type = authTypes.values[network["auth"] as int];
    return type == authTypes.OPEN;
  }

  Future authenticate(Map<String, dynamic> network) async {
    bool ent = isEnterprise(network);
    bool open = isOpen(network);
    
    // Reset password visibility state for new dialog
    _obscureWifiPassword = true;
    
    Map<String, String> creds = await showDialog(
      context: context, 
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                network["ssid"],
                style: GoogleFonts.aBeeZee(),
              ),
              content: Form(
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (ent)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextFormField(
                            controller: unameControl,
                            decoration: const InputDecoration(hintText: "Enter your enterprise login"),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                            validator: (value) => (value == null || value.isEmpty) ? "Empty username!" : null,
                          ),
                          const SizedBox(height: 16),
                        ]
                      ),
                    if (!open)
                      TextFormField(
                        controller: passControl,
                        obscureText: _obscureWifiPassword,
                        decoration: InputDecoration(
                          hintText: "Enter password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureWifiPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureWifiPassword = !_obscureWifiPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => (value == null || value.length < 8) ? "Not long enough!" : null,
                        textInputAction: TextInputAction.send,
                        onFieldSubmitted: (value) {
                          if (Form.of(context).validate()) {
                            Navigator.pop(dialogContext, (ent ?
                              {"uname": unameControl.text, "password": passControl.text}
                              : (open ? {} : {"password": passControl.text})));
                          }
                        },
                      ),
                  ]
                )
                  
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    unameControl.clear();
                    passControl.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, (ent ?
                      {"uname": unameControl.text, "password": passControl.text}
                      : (open ? {} : {"password": passControl.text})));
                    passControl.clear();
                    unameControl.clear();
                  },
                  child: const Text("Connect"),
                ),
              ],
            );
          }
        );
      }
    );

    if (creds["password"] == null && !open) return;
    if (creds["uname"] == null && ent) return;
    await transmitWiFiDetails(network["ssid"], network["auth"], creds);
  }

  Future transmitWiFiDetails(String ssid, int auth, Map<String, String> creds) async {
    setState(() {
      wifiList = null;
      message = "Attempting Connection...";
    });

    final credsChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0001");
    Map<String, dynamic> credsJson = {
      "ssid": ssid,
      "auth": auth,
      ...creds,  // Spread operator adds all key-value pairs from creds
    };
    
    try {
      String jsonString = json.encode(credsJson);
      try {
        await credsChar.write(utf8.encode(jsonString), withoutResponse: credsChar.properties.writeWithoutResponse);
      } catch (e) {
        throw Exception("Credentials Write Error");
      }
    } catch (e){
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      refreshWifiList();
      return;
    }

    final connectConfirmChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0005");
    final tokenEntryChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0002");
    final authConfirmChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0003");
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
            builder: (context) => SetDeviceName(
              tokenEntryChar: tokenEntryChar, 
              authConfirmChar: authConfirmChar, 
              device: widget.device,
              maxPorts: maxPorts,
            ),
          )
        ).then((_) {
          if (widget.device.isConnected) {
            refreshWifiList();
          }
        });
      } else if (connectResponse == "Error") {
        _confirmSub?.cancel();
        throw Exception("SSID/Password Incorrect / Other credential error");
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
    if (refreshing) return;
    refreshing = true;
    final ssidRefreshChar = _services[0].characteristics.lastWhere((c) => c.uuid.str == "0004");
    setState(() {
      wifiList = null;
      message = null;
    });
    
    try {
      try {
        await ssidRefreshChar.write(utf8.encode("Start"), withoutResponse: ssidRefreshChar.properties.writeWithoutResponse);
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