import 'dart:async';
import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterScreens/home_screen.dart';
import 'package:blind_master/utils_from_FBPExample/extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class SetDeviceName extends StatefulWidget {
  const SetDeviceName({
    super.key, 
    required this.tokenEntryChar, 
    required this.authConfirmChar, 
    required this.device,
    required this.maxPorts,
  });
  final BluetoothCharacteristic tokenEntryChar;
  final BluetoothCharacteristic authConfirmChar;
  final BluetoothDevice device;
  final int maxPorts;

  @override
  State<SetDeviceName> createState() => _SetDeviceNameState();
}

class _SetDeviceNameState extends State<SetDeviceName> {
  final deviceNameController = TextEditingController();
  Widget? screen;
  StreamSubscription<List<int>>? _authSub;

  @override
  void initState() {
    initScreen();
    super.initState();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    deviceNameController.dispose();
    super.dispose();
  }

  void initScreen() {
    screen = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BlindMasterMainInput(
          "Device Name (Different from others)",
          controller: deviceNameController,
        ),
        ElevatedButton(
          onPressed: onPressed,
          child: Text(
            "Add to Account"
          )
        ),
      ],
    );
  }

  Future addDevice(String name) async {
    final payload = {
      'deviceName': name,
      'maxPorts': widget.maxPorts,
    };
    String? token;
    try {
      final tokenResponse = await securePost(payload, 'add_device');
      if (tokenResponse == null) return;
      if (tokenResponse.statusCode != 201) {
        if (tokenResponse.statusCode == 404) {throw Exception("Somehow the id of your device wasn't found??");}
        else if (tokenResponse.statusCode == 409) {throw Exception('Device Name in Use');}
        else {throw Exception('Server Error');}
      }
      final jsonResponse = json.decode(tokenResponse.body) as Map<String, dynamic>;
      final fetchedToken = jsonResponse['token'];
      if (fetchedToken == null || fetchedToken is! String) {
        throw Exception('Invalid token in response');
      }
      token = fetchedToken;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      return;
    }

    // Set up authentication confirmation listener
    try {
      await widget.authConfirmChar.setNotifyValue(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(Exception("Failed to set up authentication listener")));
      return;
    }

    _authSub = widget.authConfirmChar.onValueReceived.listen((List<int> authVal) async {
      try {
        final authResponse = utf8.decode(authVal);
        if (authResponse == "Authenticated") {
          if (!mounted) return;
          _authSub?.cancel();
          
          await widget.device.disconnectAndUpdateStream().catchError((e) {
            if(!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
          });

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        } else if (authResponse == "Error") {
          _authSub?.cancel();
          throw Exception("Authentication failed. Please try again.");
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
        setState(() {
          initScreen();
        });
        return;
      }
    });

    // Write the token
    try {
      try {
        await widget.tokenEntryChar.write(utf8.encode(token), withoutResponse: widget.tokenEntryChar.properties.writeWithoutResponse);
      } catch (e) {
        throw Exception("Token Write Error");
      }
    } catch (e){
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      _authSub?.cancel();
      setState(() {
        initScreen();
      });
      return;
    }
  }

  Future onPressed() async {
    setState(() {
      screen = null;
    });
    await(addDevice(deviceNameController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Name Your Device",
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: screen ?? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColorLight),
              SizedBox(height: 10),
              Text(
                "Authenticating device...",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      )
    );
  }
}