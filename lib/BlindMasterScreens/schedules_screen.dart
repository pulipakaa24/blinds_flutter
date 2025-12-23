import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterScreens/day_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key, required this.peripheralId, required this.deviceId,
  required this.peripheralNum, required this.deviceName, required this.periphName});
  final int peripheralId;
  final int peripheralNum;
  final int deviceId;
  final String deviceName;
  final String periphName;
  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  List<Map<String, dynamic>> schedules = [];
  Widget? scheduleList;

  @override
  void initState() {
    super.initState();
    getSchedules();
  }

  Future getSchedules() async {
    try{
      final payload = {
        "periphId": widget.deviceId
      };
      final response = await securePost(payload, 'periph_schedule_list');
      if (response == null) throw Exception("no response!");

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        List tempList = body['scheduledUpdates'] as List;
        schedules = tempList
        .whereType<Map<String, dynamic>>()
        .toList();
      }
    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackbar(e)
      );
    }

    setState(() {
      scheduleList = RefreshIndicator(
        onRefresh: getSchedules,
        child: schedules.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Text(
                      "No schedules found...\nAdd one using the '+' button",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: schedules.length,
                itemBuilder: (context, i) {
                  final schedule = schedules[i];
                  return Dismissible(
                    key: Key(schedule['id'].toString()),
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
                          title: const Text('Delete Schedule'),
                          content: const Text('Are you sure you want to delete this schedule?'),
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
                      // TODO Actually delete the schedule
                      // deleteDevice(device['id'], i);
                    },
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.blinds),
                        title: Text("${schedule['pos']} every ${schedule['schedule']['daysOfWeek']} at ${schedule['schedule']['hours']}:${schedule['schedule']['minutes']}"),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Placeholder(),
                              // TODO open popup for schedule setter.
                            ),
                          ).then((_) { getSchedules(); });
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

  Future<void> sendSchedule(TimeOfDay scheduleTime) async {
    return;
  }

  void addSchedule() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use dialogContext for navigation within the dialog
        return DayTimePicker(defaultTime: TimeOfDay(hour: 12, minute: 0), sendSchedule: sendSchedule);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Schedules: ${widget.deviceName} - ${widget.periphName}",
          style: GoogleFonts.aBeeZee(),
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
        foregroundColor: Colors.white,
      ),
      body: scheduleList ?? const Center(child: CircularProgressIndicator()),
      floatingActionButton: Container(
        padding: EdgeInsets.all(25),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColorDark,
          foregroundColor: Theme.of(context).highlightColor,
          heroTag: "add",
          onPressed: addSchedule,
          tooltip: "Add Schedule",
          child: Icon(Icons.add),
        )
      )
    );
  }
}