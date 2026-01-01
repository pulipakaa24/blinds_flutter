import 'dart:convert';

import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/BlindMasterScreens/day_time_picker.dart';
import 'package:blind_master/main.dart';
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

  String translate(int pos) {
    if (pos < 2) {
      return "Close (down)";
    } else if (pos < 5) {
      return "Open (down)";
    }
    else if (pos == 5) {
      return "Open";
    }
    else if (pos < 9) {
      return "Open (up)";
    }
    else {
      return "Close (up)";
    }
  }

  Future getSchedules() async {
    try{
      final payload = {
        "periphId": widget.peripheralId
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
                    onDismissed: (direction) async {
                      final scheduleId = schedule['id'].toString();
                      try {
                        final payload = {'jobId': scheduleId};
                        final response = await securePost(payload, 'delete_schedule');
                        
                        if (response == null) throw Exception("Auth Error");
                        if (response.statusCode != 200) {
                          throw Exception("Failed to delete schedule");
                        }
                        
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Schedule deleted successfully'),
                            backgroundColor: Colors.green,
                          )
                        );
                      } catch (e) {
                        if (mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
                      } finally {
                        // Refresh the list regardless of success/failure
                        if (mounted) getSchedules();
                      }
                    },
                    child: Card(
                      child: Builder(
                        builder: (context) {
                          final pos = translate(schedule['pos']);
                          final days = (schedule['schedule']['daysOfWeek'] as List)
                              .map((d) => DaysOfWeek.values[d].name)
                              .join(', ');
                          final hour24 = schedule['schedule']['hours'][0] as int;
                          final minute = schedule['schedule']['minutes'][0].toString().padLeft(2, '0');
                          final period = hour24 >= 12 ? 'PM' : 'AM';
                          final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
                          
                          return ListTile(
                            leading: const Icon(Icons.blinds),
                            title: Text("$pos at $hour12:$minute $period"),
                            subtitle: Text(days),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return DayTimePicker(
                                    defaultTime: TimeOfDay(hour: 12, minute: 0),
                                    sendSchedule: sendSchedule,
                                    peripheralId: widget.peripheralId,
                                    peripheralNum: widget.peripheralNum,
                                    deviceId: widget.deviceId,
                                    existingSchedule: schedule,
                                    scheduleId: schedule['id'].toString(),
                                  );
                                }
                              ).then((_) { getSchedules(); });
                            },
                          );
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
        return DayTimePicker(
          defaultTime: TimeOfDay(hour: 12, minute: 0),
          sendSchedule: sendSchedule,
          peripheralId: widget.peripheralId,
          peripheralNum: widget.peripheralNum,
          deviceId: widget.deviceId,
        );
      }
    ).then((_) { getSchedules(); });
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