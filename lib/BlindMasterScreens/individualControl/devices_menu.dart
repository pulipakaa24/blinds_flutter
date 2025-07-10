import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterScreens/addingDevices/add_device.dart';
import 'package:blind_master/BlindMasterScreens/individualControl/device_screen.dart';
import 'package:flutter/material.dart';

class DevicesMenu extends StatefulWidget {
  const DevicesMenu({super.key});

  @override
  State<DevicesMenu> createState() => _DevicesMenuState();
}

class _DevicesMenuState extends State<DevicesMenu> {
  List<Map<String, dynamic>> devices = [];
  Widget? deviceList;
  
  @override
  void initState() {
    super.initState();
    getDevices();
  }

  Future getDevices() async {
    try{
      final response = await secureGet('device_list');
      if (response == null) throw Exception("no response!");

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final names = body['devices'] as List;
        final ids = body['device_ids'] as List;
        devices = List.generate(names.length, (i) => {
          'id': ids[i],
          'name': names[i],
        });
      }
    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
    }

    setState(() {
      deviceList = RefreshIndicator(
        onRefresh: getDevices,
        child: devices.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Text(
                      "No hubs found...\nAdd one using the '+' button",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, i) {
                  final device = devices[i];
                  return Dismissible(
                    key: Key(device['id'].toString()),
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
                          title: const Text('Delete Hub'),
                          content: const Text('Are you sure you want to delete this hub?'),
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
                    onDismissed: (direction) {
                      // Actually delete the device
                      deleteDevice(device['id'], i);
                    },
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.blinds),
                        title: Text(device['name']),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceScreen(deviceId: device['id']),
                            ),
                          ).then((_) { getDevices(); });
                        },
                      ),
                    ),
                  );
                },
              ),
      );
    });
    return Future.delayed(Duration(milliseconds: 500));
  }

  Future deleteDevice(int id, int i) async {
    setState(() {
      devices.removeAt(i);
      deviceList = null;
    });
    print("deleting");
    final payload = { 
      'deviceId': id,
    };
    try {
      final response = await securePost(payload, 'delete_device');
      if (response == null) return;
      if (response.statusCode != 204) {
        if (response.statusCode == 404) {throw Exception('Device Not Found');}
        else if (response.statusCode == 500) {throw Exception('Server Error');}
      }
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
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

    getDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: deviceList ?? const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDevice()),
          );
        },
        foregroundColor: Theme.of(context).highlightColor,
        backgroundColor: Theme.of(context).primaryColorDark,
        child: Icon(Icons.add),
      ),
    );
  }
}