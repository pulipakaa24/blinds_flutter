import 'dart:async';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterScreens/addingDevices/device_setup.dart';
import 'package:blind_master/utils_from_FBPExample/extra.dart';
import 'package:blind_master/utils_from_FBPExample/scan_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class AddDevice extends StatefulWidget {
  const AddDevice({super.key});

  @override
  State<AddDevice> createState() => _AddDeviceState();
}

class _AddDeviceState extends State<AddDevice> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  bool _isConnecting = false;
  
  @override
  void initState() {
    super.initState();
    initBluetoothandStartScan();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [
          Guid("181C"),
        ],
        webOptionalServices: [
          Guid("181C"), // user input
        ],
      );
    } catch (e, backtrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      print("backtrace: $backtrace");
    }
    setState(() {});
  }


  Future<void> initBluetoothandStartScan() async {

    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() => _adapterState = state);
        if (state == BluetoothAdapterState.on) {
          _startScan();
        }
      }
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() => _scanResults = results);
        // setState(() => _scanResults = results.where((r) => r.device.platformName == "BlindMaster").toList());
      }
    }, onError: (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() => _isScanning = state);
      }
    });
  }

  Future onConnectPressed(BluetoothDevice device) async {
    if (_isConnecting) return;
    _isConnecting = true;
    
    await device.connectAndUpdateStream().catchError((e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    });
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceSetup(device: device))
    ).then((_) {
      device.disconnectAndUpdateStream().catchError((e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
      });
      _isConnecting = false;
    });
  }

  Future onRefresh() async {
    if (_isScanning == false) {
      await _startScan();
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget _buildScanResultTiles() {
    // final res = _scanResults.where((r) => r.advertisementData.advName == "BlindMaster Device" && r.rssi > -55);
    final res = _scanResults.where((r) => r.advertisementData.advName == "BlindMaster-C6");
    return (res.isNotEmpty) 
    ? ListView(
        children: [
          ...res.map((r) => ScanResultTile(result: r, onTap: () => onConnectPressed(r.device)))
        ],
      )
    : _isScanning ? Center(
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
            "Nothing Yet...",
          )
        ]
      ),
    )
    : SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(
          child: Text(
            "No BlindMaster devices found nearby",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add a Device",
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      body:  _adapterState != BluetoothAdapterState.on
        ? SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Text(
                "Bluetooth is off.\nPlease turn it on to scan for devices.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          )
        : RefreshIndicator(
          onRefresh: onRefresh,
          child: _buildScanResultTiles()
        ),
    );
  }
}