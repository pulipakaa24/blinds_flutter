import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterResources/text_inputs.dart';
import 'package:blind_master/BlindMasterScreens/individualControl/peripheral_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceScreen extends StatefulWidget {
  final int deviceId;
  const DeviceScreen({super.key, required this.deviceId});


  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool enabled = false;
  final _newPeripheralNameController = TextEditingController();
  final _hubRenameController = TextEditingController();
  List<Map<String, dynamic>> peripherals = [];
  List occports = [];
  Widget? peripheralList;
  String deviceName = "...";

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future initAll() async {
    await getDeviceName();
    await populatePeripherals();
  }

  Future getDeviceName() async {
    try {
      final payload = {
        "deviceId": widget.deviceId
      };
      final response = await secureGet('device_name', queryParameters: payload);
      if (response == null) throw Exception("no response!");

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          deviceName = body['device_name'];
        }); 
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future populatePeripherals() async {
    setState(() {
      peripheralList = null;
    });
    try {
      final payload = {
        "deviceId": widget.deviceId
      };
      final response = await secureGet('peripheral_list', queryParameters: payload);
      if (response == null) throw Exception("no response!");

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final names = body['peripheral_names'] as List;
        final ids = body['peripheral_ids'] as List;
        occports = body['port_nums'] as List;
        peripherals = List.generate(names.length, (i) => {
          'id': ids[i],
          'name': names[i],
          'port': occports[i]
        });
        peripherals.sort((a, b) => (a['port'] as int).compareTo(b['port'] as int));
        enabled = peripherals.length < 4;
      }

      setState(() {
        peripheralList = RefreshIndicator(
          onRefresh: populatePeripherals,
          child: peripherals.isEmpty ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Center(
                child: Text(
                  "No peripherals found...\nAdd one using the '+' button",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ) : ListView.builder(
            itemCount: peripherals.length,
            itemBuilder: (context, i) {
              final peripheral = peripherals[i];
              return Dismissible(
                key: Key(peripheral['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  // Ask for confirmation (optional)
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Peripheral'),
                      content: const Text('Are you sure you want to delete this peripheral?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) => deletePeripheral(peripheral['id'], i),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.blinds),
                    title: Text(peripheral['name']),
                    subtitle: Text("Port #${peripheral['port']}"),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PeripheralScreen(deviceName: deviceName, peripheralId: peripheral['id'], 
                            peripheralNum: peripheral['port'], deviceId: widget.deviceId,),
                        ),
                      ).then((_) { populatePeripherals(); });
                    },
                  ),
                ),
              );
            },
          ),
        );
      });
      return Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  Future deletePeripheral(int id, int i) async {
    setState(() {
      peripherals.removeAt(i);
      peripheralList = null;
    });
    final payload = {
      'periphId': id,
    };
    try {
      final response = await securePost(payload, 'delete_peripheral');
      if (response == null) return;
      if (response.statusCode != 204) {
        if (response.statusCode == 404) {throw Exception('Device Not Found');}
        else if (response.statusCode == 500) {throw Exception('Server Error');}
      }
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Deleted',
              textAlign: TextAlign.center,
            )
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }

    populatePeripherals();
  }

  void addPeripheral() {
    var freePorts = <int>{};
    for (int i = 1; i < 5; i++) {
      freePorts.add(i);
    }
    freePorts = freePorts.difference(occports.toSet());
    int? port = freePorts.firstOrNull;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use dialogContext for navigation within the dialog
        return AlertDialog(
          title: Text(
            'New Peripheral',
            style: GoogleFonts.aBeeZee(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Keep column compact
            children: <Widget>[
              TextFormField(
                controller: _newPeripheralNameController,
                decoration: const InputDecoration(
                  labelText: 'Peripheral Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: port,
                decoration: const InputDecoration(
                  labelText: 'Hub Port',
                  border: OutlineInputBorder(),
                ),
                items: freePorts.map((int number) {
                  return DropdownMenuItem<int>(
                    value: number,
                    child: Text('$number'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    port = newValue;
                  });
                },
              ),
            ],
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
                    uploadPeriphData(_newPeripheralNameController.text, port);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Add"),
                ),
              ]
            )
          ],
        );
      }
    );
  }

  Future uploadPeriphData(String name, int? port) async {
    try {
      if (name.isEmpty || port == null) {
        throw Exception("Name and Port Required");
      }
      final payload = {
        'device_id': widget.deviceId,
        'port_num': port,
        'peripheral_name': name
      };

      final response = await securePost(payload, 'add_peripheral');
      if (response == null) throw Exception("Auth Error");
      if (response.statusCode != 201) {
        if (response.statusCode == 409) throw Exception("Choose a unique name!");
        throw Exception("Server Error");
      }
      
      populatePeripherals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
    }
  }

  void rename() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Rename Hub",
            style: GoogleFonts.aBeeZee(),
          ),
          content: BlindMasterMainInput("New Hub Name", controller: _hubRenameController,),
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
                    updateHubName(_hubRenameController.text, widget.deviceId);
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

  Future updateHubName(String name, int id) async {
    try {
      if (name.isEmpty) throw Exception("New name cannot be empty!");
      final payload = {
        'deviceId': id,
        'newName': name,
      };
      final response = await securePost(payload, 'rename_device');
      if (response == null) throw Exception("Auth Error");
      if (response.statusCode != 204) {
        if (response.statusCode == 409) throw Exception("Choose a unique name!");
        throw Exception("Server Error");
      }
      getDeviceName();
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
          deviceName,
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
      ),
      body: peripheralList ?? SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).primaryColorLight,
          ),
        )
      ),
      floatingActionButton: Container(
        padding: EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColorDark,
              foregroundColor: Theme.of(context).highlightColor,
              heroTag: "rename",
              onPressed: rename,
              tooltip: "Rename Hub",
              child: Icon(Icons.drive_file_rename_outline_sharp),
            ),
            FloatingActionButton(
              backgroundColor: enabled
                ? Theme.of(context).primaryColorDark
                : Theme.of(context).disabledColor,
              foregroundColor: Theme.of(context).highlightColor,
              heroTag: "add",
              onPressed: enabled ? addPeripheral : null,
              tooltip: "Add Peripheral",
              child: Icon(Icons.add),
            )
          ],
        )
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}