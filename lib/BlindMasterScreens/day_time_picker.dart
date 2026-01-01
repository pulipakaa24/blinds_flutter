import 'package:blind_master/BlindMasterResources/error_snackbar.dart';
import 'package:blind_master/BlindMasterResources/secure_transmissions.dart';
import 'package:blind_master/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DayTimePicker extends StatefulWidget {
  const DayTimePicker({
    super.key,
    required this.defaultTime,
    required this.sendSchedule,
    required this.peripheralId,
    required this.peripheralNum,
    required this.deviceId,
    this.existingSchedule,
    this.scheduleId,
  });

  final TimeOfDay defaultTime;
  final void Function(TimeOfDay) sendSchedule;
  final int peripheralId;
  final int peripheralNum;
  final int deviceId;
  final Map<String, dynamic>? existingSchedule;
  final String? scheduleId;
  
  bool get isEditing => existingSchedule != null && scheduleId != null;
  
  @override
  State<DayTimePicker> createState() => _DayTimePickerState();
}

class _DayTimePickerState extends State<DayTimePicker> {
  TimeOfDay? scheduleTime;
  double _blindPosition = 0;
  String imagePath = "";
  Set<DaysOfWeek> days = <DaysOfWeek>{};
  bool showError = false;

  @override
  void initState() {
    super.initState();
    
    // If editing, pre-populate with existing schedule data
    if (widget.isEditing && widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      final hour = schedule['schedule']['hours'][0] as int;
      final minute = schedule['schedule']['minutes'][0] as int;
      scheduleTime = TimeOfDay(hour: hour, minute: minute);
      _blindPosition = (schedule['pos'] as int).toDouble();
      
      // Pre-populate days
      final daysOfWeek = schedule['schedule']['daysOfWeek'] as List;
      days = daysOfWeek.map((d) => DaysOfWeek.values[d as int]).toSet();
    }
    
    updateBackground();
  }

  Future selectTime() async {
    scheduleTime = await showTimePicker(
      context: context,
      initialTime: scheduleTime ?? widget.defaultTime,
    ) ?? (scheduleTime ?? widget.defaultTime);
    setState(() {
      updateBackground();
    });
  }

  void updateBackground() {
    final hour = scheduleTime?.hour ?? widget.defaultTime.hour;
  
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'New Schedule',
        style: GoogleFonts.aBeeZee(),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Keep column compact
        children: <Widget>[
          Text(
            "Move to position"
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.11,
                  ),
                  Stack(
                    children: [
                      // Background image
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          imagePath,
                          // fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.45,
                        ),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: Builder(
                          builder: (context) {
                            final containerHeight = MediaQuery.of(context).size.width * 0.43;
                            final maxSlatHeight = containerHeight / 10;
                            final slatHeight = _blindPosition < 5 
                              ? maxSlatHeight * (5 - _blindPosition) / 5
                              : maxSlatHeight * (_blindPosition - 5) / 5;
                            
                            return Container(
                              margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.05),
                              height: containerHeight,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(10, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: slatHeight,
                                    width: MediaQuery.of(context).size.width * 0.40,
                                    color: const Color.fromARGB(255, 121, 85, 72),
                                  );
                                }),
                              ),
                            );
                          }
                        )
                      ),
                    ],
                  ),
                  // Slider on the side
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.10,
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Slider(
                        value: _blindPosition,
                        activeColor: Theme.of(context).primaryColorDark,
                        thumbColor: Theme.of(context).primaryColorLight,
                        inactiveColor: Theme.of(context).primaryColorDark,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _blindPosition = value;
                          });
                        },
                      ),
                    ),
                  )
                ],
              ),
            )
          ),
          Text(
            "At"
          ),
          Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                hourMinuteColor: Theme.of(context).primaryColorDark,
                dialBackgroundColor: Theme.of(context).primaryColorDark,
              )
            ),
            child: ElevatedButton(
              onPressed: selectTime,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Theme.of(context).highlightColor
              ),
              child: Text(scheduleTime?.format(context) ?? widget.defaultTime.format(context)),
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Text(
              "Every"
            ),
          ),
          Wrap(
            spacing: 5.0,
            alignment: WrapAlignment.center,
            children: DaysOfWeek.values.map((DaysOfWeek day) {
              return FilterChip(
                showCheckmark: false,
                label: Text(day.name),
                selected: days.contains(day),
                selectedColor: Theme.of(context).primaryColorDark,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      days.add(day);
                      showError = false;
                    } else {
                      days.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (showError)
            Container(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Please select at least one day',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.red
                ),
              )
            ),
            ElevatedButton(
              onPressed: () async {
                if (days.isEmpty) {
                  setState(() {
                    showError = true;
                  });
                  return;
                }
                
                try {
                  // Convert DaysOfWeek enum to day numbers (0=Sunday, 1=Monday, etc.)
                  final daysOfWeek = days.map((day) => day.index).toList();
                  
                  final timeToUse = scheduleTime ?? widget.defaultTime;
                  
                  final payload = {
                    'periphId': widget.peripheralId,
                    'periphNum': widget.peripheralNum,
                    'deviceId': widget.deviceId,
                    'newPos': _blindPosition.toInt(),
                    'time': {
                      'hour': timeToUse.hour,
                      'minute': timeToUse.minute,
                    },
                    'daysOfWeek': daysOfWeek,
                  };
                  
                  // Add jobId if editing
                  if (widget.isEditing) {
                    payload['jobId'] = widget.scheduleId!;
                  }
                  
                  final endpoint = widget.isEditing ? 'update_schedule' : 'add_schedule';
                  final response = await securePost(payload, endpoint);
                  
                  if (response == null) throw Exception("Auth Error");
                  
                  // Handle duplicate schedule (409 Conflict)
                  if (response.statusCode == 409) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'A schedule already exists at this time for this blind',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      )
                    );
                    return;
                  }
                  
                  if (response.statusCode != 201 && response.statusCode != 200) {
                    throw Exception("Server Error");
                  }
                  
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.isEditing ? 'Schedule updated successfully' : 'Schedule added successfully',
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: Colors.green,
                    )
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(errorSnackbar(e));
                }
              },
              child: Text(widget.isEditing ? "Update" : "Add")
            )
          ]
        )
      ],
    );
  }
}