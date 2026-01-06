import 'dart:convert';

import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditGroupDialog extends StatefulWidget {
  const EditGroupDialog({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentPeripheralIds,
  });

  final int groupId;
  final String groupName;
  final List<int> currentPeripheralIds;

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  List<Map<String, dynamic>> devices = [];
  Map<int, List<Map<String, dynamic>>> devicePeripherals = {};
  Set<int> selectedPeripheralIds = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    selectedPeripheralIds = widget.currentPeripheralIds.toSet();
    _loadDevicesAndPeripherals();
  }

  Future<void> _loadDevicesAndPeripherals() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch devices
      final devicesResponse = await secureGet('device_list');
      if (devicesResponse == null || devicesResponse.statusCode != 200) {
        throw Exception('Failed to load devices');
      }

      final devicesBody = jsonDecode(devicesResponse.body);
      final deviceIds = List<int>.from(devicesBody['device_ids']);
      final deviceNames = List<String>.from(devicesBody['devices']);

      devices = List.generate(deviceIds.length, (i) => {
        'id': deviceIds[i],
        'name': deviceNames[i],
      });

      // Fetch peripherals for each device
      for (var device in devices) {
        final periphResponse = await secureGet(
          'peripheral_list',
          queryParameters: {'deviceId': device['id'].toString()}
        );
        
        if (periphResponse != null && periphResponse.statusCode == 200) {
          final periphBody = jsonDecode(periphResponse.body);
          final periphIds = List<int>.from(periphBody['peripheral_ids']);
          final periphNames = List<String>.from(periphBody['peripheral_names']);
          
          devicePeripherals[device['id']] = List.generate(periphIds.length, (i) => {
            'id': periphIds[i],
            'name': periphNames[i],
          });
        } else {
          devicePeripherals[device['id']] = [];
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading devices: ${e.toString()}';
      });
    }
  }

  Future<void> _updateGroup() async {
    if (selectedPeripheralIds.length < 2) {
      setState(() {
        errorMessage = 'Please select at least 2 blinds';
      });
      return;
    }

    try {
      final response = await securePost(
        {
          'groupId': widget.groupId,
          'peripheral_ids': selectedPeripheralIds.toList(),
        },
        'update_group'
      );

      if (response != null && response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else if (response != null && response.statusCode == 409) {
        final errorBody = jsonDecode(response.body);
        setState(() {
          errorMessage = errorBody['error'] ?? 'This combination of blinds already exists';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to update group';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error updating group: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit "${widget.groupName}"',
        style: GoogleFonts.aBeeZee(),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selectedPeripheralIds.length >= 2
                      ? Theme.of(context).primaryColorLight.withValues(alpha: 0.5) 
                      : Colors.orange.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${selectedPeripheralIds.length} blind${selectedPeripheralIds.length != 1 ? 's' : ''} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                    ),
                  ),
                Flexible(
                  child: devices.isEmpty
                    ? const Text('No devices found')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, i) {
                          final device = devices[i];
                          final peripherals = devicePeripherals[device['id']] ?? [];
                          
                          if (peripherals.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return ExpansionTile(
                            title: Text(
                              device['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${peripherals.length} blind${peripherals.length != 1 ? 's' : ''}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: peripherals.map((peripheral) {
                                    final isSelected = selectedPeripheralIds.contains(peripheral['id']);
                                    return FilterChip(
                                      showCheckmark: false,
                                      label: Text(peripheral['name']),
                                      selected: isSelected,
                                      selectedColor: Theme.of(context).primaryColorDark,
                                      labelStyle: TextStyle(
                                        color: isSelected 
                                          ? Theme.of(context).highlightColor 
                                          : null,
                                      ),
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedPeripheralIds.add(peripheral['id']);
                                          } else {
                                            selectedPeripheralIds.remove(peripheral['id']);
                                          }
                                          if (errorMessage != null) {
                                            errorMessage = null;
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ),
              ],
            ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.red
                ),
              )
            ),
            ElevatedButton(
              onPressed: isLoading ? null : _updateGroup,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Theme.of(context).highlightColor,
              ),
              child: const Text("Update")
            )
          ]
        )
      ],
    );
  }
}
