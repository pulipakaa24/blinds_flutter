import 'dart:convert';

import 'package:blind_master/BlindMasterResources/blind_control_widget.dart';
import 'package:blind_master/BlindMasterResources/blindmaster_progress_indicator.dart';
import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterScreens/schedules_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PeripheralScreen extends StatefulWidget {
  const PeripheralScreen({super.key, required this.peripheralId, required this.deviceId, required this.peripheralNum, required this.deviceName});
  final int peripheralId;
  final int peripheralNum;
  final int deviceId;
  final String deviceName;
  @override
  State<PeripheralScreen> createState() => _PeripheralScreenState();
}

class _PeripheralScreenState extends State<PeripheralScreen> {
  IO.Socket? socket;
  String imagePath = "";
  String peripheralName = "...";
  bool loaded = false;
  bool calibrated = false;
  bool calibrating = false;
  bool deviceConnected = true; // Track device connection status
  int calibrationStage = 0; // 0=not started, 1=tilt up, 2=tilt down
  double _blindPosition = 5.0;
  DateTime? lastSet;
  String lastSetMessage = "";

  final _peripheralRenameController = TextEditingController();

  void getImage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 10) {
      imagePath = 'assets/images/MorningSill.png';
    } else if (hour >= 10 && hour < 18) {
      imagePath = 'assets/images/NoonSill.png';
    } else if (hour >= 18 && hour < 22) {
      imagePath = 'assets/images/EveningSill.png';
    } else {
      imagePath = 'assets/images/NightSill.png';
    }
  }

  @override
  void initState() {
    super.initState();
    initAll();
    initSocket();
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  Future<void> initSocket() async {
    try {
      socket = await connectSocket();
      if (socket == null) throw Exception("Unsuccessful socket connection");
      
      // Handle rate limiting errors
      socket?.on("error", (data) async {
        if (data is Map<String, dynamic>) {
          if (data['code'] == 429) {
            // Rate limited - wait and reconnect
            print("Rate limited: ${data['message']}. Reconnecting in 1 second...");
            socket?.disconnect();
            socket?.dispose();
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              initSocket();
            }
          }
        }
      });
      
      socket?.on("success", (_) {
        socket?.on("device_connected", (data) {
          if (data is Map<String, dynamic>) {
            if (data['deviceID'] == widget.deviceId) {
              if (!mounted) return;
              setState(() {
                deviceConnected = true;
              });
            }
          }
        });
        
        socket?.on("device_disconnected", (data) {
          if (data is Map<String, dynamic>) {
            if (data['deviceID'] == widget.deviceId) {
              if (!mounted) return;
              setState(() {
                deviceConnected = false;
                // Reset calibration if it was in progress
                if (calibrating) {
                  calibrationStage = 0;
                }
              });
            }
          }
        });
        
        socket?.on("posUpdates", (list) {
          for (var update in list) {
            if (update is Map<String, dynamic>) {
              if (update['periphID'] == widget.peripheralId) {
                if (!mounted) return;
                setState(() {
                  _blindPosition = (update['pos'] as int).toDouble();
                });
              }
            }
          }
        });
        
        socket?.on("calib", (periphData) {
          if (periphData is Map<String, dynamic>) {
            if (periphData['periphID'] == widget.peripheralId) {
              if (!mounted) return;
              setState(() {
                calibrating = true;
                calibrated = false;
                calibrationStage = 0; // Waiting for device to be ready
              });
            }
          }
        });
        
        socket?.on("calib_error", (errorData) {
          if (errorData is Map<String, dynamic>) {
            if (errorData['periphID'] == widget.peripheralId) {
              if (!mounted) return;
              setState(() {
                calibrating = false;
                calibrationStage = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorData['message'] ?? 'Calibration error'),
                  backgroundColor: Colors.red,
                )
              );
            }
          }
        });
        
        socket?.on("calib_stage1_ready", (periphData) {
          if (periphData is Map<String, dynamic>) {
            if (periphData['periphID'] == widget.peripheralId) {
              if (!mounted) return;
              setState(() {
                calibrationStage = 1; // Device ready for tilt up
              });
            }
          }
        });
        
        socket?.on("calib_stage2_ready", (periphData) {
          if (periphData is Map<String, dynamic>) {
            if (periphData['periphID'] == widget.peripheralId) {
              if (!mounted) return;
              setState(() {
                calibrationStage = 2; // Device ready for tilt down
              });
            }
          }
        });
        
        socket?.on("calib_done", (periphData) {
          if (periphData is Map<String, dynamic>) {
            if (periphData['periphID'] == widget.peripheralId) {
              if (!mounted) return;
              setState(() {
                calibrating = false;
                calibrated = true;
                calibrationStage = 0;
              });
              // Fetch updated peripheral data after calibration completes
              fetchState();
            }
          }
        });
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future<void> calibrate() async {
    if (!deviceConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device must be connected to calibrate'),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }
    
    try {
      final payload = {
        'periphId': widget.peripheralId
      };

      final response = await securePost(payload, 'calib');
      
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 202) throw Exception("Server Error");
      calibrated = false;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future<void> cancelCalib() async {
    try {
      final payload = {
        'periphId': widget.peripheralId
      };

      final response = await securePost(payload, 'cancel_calib');
      
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 202) throw Exception("Server Error");
      
      // Only update state if cancel succeeded
      if (!mounted) return;
      setState(() {
        calibrated = false;
        calibrating = false;
        calibrationStage = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future<void> completeStage1() async {
    // User confirms they've tilted blinds all the way up
    // Tell device to proceed to stage 2
    socket?.emit("user_stage1_complete", {
      "periphID": widget.peripheralId,
      "periphNum": widget.peripheralNum,
      "deviceID": widget.deviceId
    });
    setState(() {
      calibrationStage = 0; // Wait for device acknowledgment
    });
  }

  Future<void> completeStage2() async {
    // User confirms they've tilted blinds all the way down
    // Tell device calibration is complete
    socket?.emit("user_stage2_complete", {
      "periphID": widget.peripheralId,
      "periphNum": widget.peripheralNum,
      "deviceID": widget.deviceId
    });
    setState(() {
      calibrationStage = 0; // Wait for device acknowledgment
    });
  }

  Future<void> getName() async {
    try {
      final payload = {
        'periphId': widget.peripheralId
      };
      final response = await secureGet('peripheral_name', queryParameters: payload);
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 200) throw Exception("Server Error");
      final body = json.decode(response.body);
      setState(() => peripheralName = body['name']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future<void> checkDeviceConnection() async {
    try {
      final payload = {
        'deviceId': widget.deviceId
      };
      final response = await secureGet('device_connection_status', queryParameters: payload);
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 200) throw Exception("Server Error");
      final body = json.decode(response.body);
      if (!mounted) return;
      setState(() => deviceConnected = body['connected']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future fetchState() async{
    try {
      final payload = {
        'periphId': widget.peripheralId
      };

      final response = await secureGet('peripheral_status', queryParameters: payload);
      if (response == null) throw Exception("auth error");
      if (response.statusCode != 200) {
        if (response.statusCode == 404) throw Exception("Device Not Found");
        throw Exception("Server Error");
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (!body['await_calib']){
        if (!body['calibrated']) {
          calibrated = false;
          calibrating = false;
        }
        else {
          getImage();
          
          if (body['last_set'] != null) {
            final nowUtc = DateTime.now().toUtc();
            final lastSetUtc = DateTime.parse(body['last_set']);
            final Duration difference = nowUtc.difference(lastSetUtc);
            if (!lastSetUtc.isUtc) throw Exception("Why isn't the server giving UTC?");
            final diffDays = difference.inDays > 0;
            final diffHours = difference.inHours > 0;
            final diffMins = difference.inMinutes > 0;
            lastSetMessage = "Last set ${diffDays ? '${difference.inDays.toString()} days' : diffHours ? '${difference.inHours.toString()} hours' : diffMins ? '${difference.inMinutes.toString()} minutes' : '${difference.inSeconds.toString()} seconds'} ago";
          } else {
            lastSetMessage = "Never set";
          }
          
          _blindPosition = (body['last_pos'] as int).toDouble();

          calibrated = true;
          calibrating = false;
        }
      }
      else {
        calibrating = true;
      }
      
      setState(() {loaded = true;});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future initAll() async{
    getName();
    checkDeviceConnection();
    fetchState();
  }

  void rename() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Rename Peripheral",
            style: GoogleFonts.aBeeZee(),
          ),
          content: BlindMasterMainInput("New Peripheral Name", controller: _peripheralRenameController,),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.red
                    ),
                  )
                ),
                ElevatedButton(
                  onPressed: () {
                    updatePeriphName(_peripheralRenameController.text, widget.peripheralId);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Confirm")
                )
              ],
            )
          ],
        );
      }
    );
  }

  Future updatePeriphName(String name, int id) async {
    try {
      if (name.isEmpty) throw Exception("New name cannot be empty!");
      final payload = {
        'periphId': id,
        'newName': name,
      };
      final response = await securePost(payload, 'rename_peripheral');
      if (response == null) throw Exception("Auth Error");
      if (response.statusCode != 204) {
        if (response.statusCode == 409) throw Exception("Choose a unique name!");
        throw Exception("Server Error");
      }
      getName();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  void recalibrate() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Recalibrate Peripheral",
            style: GoogleFonts.aBeeZee(),
          ),
          content: const Text(
            "This will take under a minute",
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.red
                    ),
                  )
                ),
                ElevatedButton(
                  onPressed: () {
                    calibrate();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Confirm")
                )
              ],
            )
          ],
        );
      }
    );
  }

  Future updateBlindPosition() async {
    try {
      final payload = {
        'periphId': widget.peripheralId,
        'periphNum': widget.peripheralNum,
        'deviceId': widget.deviceId,
        'newPos': _blindPosition.toInt(),
      };

      final response = await securePost(payload, 'manual_position_update');
      if (response == null) throw Exception("Auth Error");
      if (response.statusCode != 202) {
        throw Exception("Server Error");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.deviceName} - $peripheralName",
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
        bottom: !deviceConnected ? PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.orange.shade700,
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Device Disconnected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) : null,
      ),

      body: loaded 
      ? (calibrating
      ? RefreshIndicator(
        onRefresh: initAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      calibrationStage == 0
                        ? "Preparing device for calibration..."
                        : calibrationStage == 1
                          ? "Tilt the blinds ALL THE WAY UP"
                          : "Tilt the blinds ALL THE WAY DOWN",
                      style: GoogleFonts.aBeeZee(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (calibrationStage == 0)
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColorLight,
                    ),
                  SizedBox(height: 20),
                  if (calibrationStage == 1 || calibrationStage == 2)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: calibrationStage == 1 ? completeStage1 : completeStage2,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: const Text(
                            "Complete",
                            style: TextStyle(fontSize: 16),
                          )
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: cancelCalib,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontSize: 16),
                          )
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: cancelCalib,
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.red
                        ),
                      )
                    )
                ]
              )
            )
          )
        )
      )
      : (calibrated
      ? Column(
        children: [
          BlindControlWidget(
            imagePath: imagePath,
            blindPosition: _blindPosition,
            onPositionChanged: (value) {
              setState(() {
                _blindPosition = value;
                updateBlindPosition();
              });
            },
          ),
          Container(
            padding: EdgeInsets.all(25),
            child: Text(
              lastSetMessage
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SchedulesScreen(peripheralId: widget.peripheralId, periphName: peripheralName,
                    deviceId: widget.deviceId, peripheralNum: widget.peripheralNum, deviceName: widget.deviceName,)
                  )
                );
              },
              child: Text(
                "Set Schedules"
              )
            ),
          )
        ]
      )
      : SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Peripheral Not Calibrated"
                ),
              ),
              ElevatedButton(
                onPressed: deviceConnected ? calibrate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: deviceConnected ? null : Colors.grey,
                ),
                child: const Text("Calibrate")
              )
            ],
          )
        )
      )))
      : BlindmasterProgressIndicator(),
      floatingActionButton: Container(
        padding: EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: "rename",
              tooltip: "Rename Peripheral",
              onPressed: rename,
              foregroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).primaryColorDark,
              child: Icon(Icons.drive_file_rename_outline_sharp),
            ),
            FloatingActionButton(
              heroTag: "recalibrate",
              tooltip: "Recalibrate Peripheral",
              onPressed: (deviceConnected && calibrated) ? recalibrate : null,
              foregroundColor: (deviceConnected && calibrated) ? Theme.of(context).highlightColor : Colors.grey.shade400,
              backgroundColor: (deviceConnected && calibrated) ? Theme.of(context).primaryColorDark : Colors.grey.shade300,
              child: Icon(Icons.swap_vert),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}