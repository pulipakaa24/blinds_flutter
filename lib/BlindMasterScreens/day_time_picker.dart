import 'package:blind_master/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DayTimePicker extends StatefulWidget {
  const DayTimePicker({super.key, required this.defaultTime, required this.sendSchedule});

  final TimeOfDay defaultTime;
  final void Function(TimeOfDay) sendSchedule;
  @override
  State<DayTimePicker> createState() => _DayTimePickerState();
}

class _DayTimePickerState extends State<DayTimePicker> {
  TimeOfDay? scheduleTime;
  double _blindPosition = 0;
  String imagePath = "";
  Set<DaysOfWeek> days = <DaysOfWeek>{};

  @override
  void initState() {
    super.initState();
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
                        child: Container(
                          margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.05),
                          height: MediaQuery.of(context).size.width * 0.43,
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(10, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: _blindPosition < 5 ? 
                                  3.65 * (5 - _blindPosition)
                                  : 3.65 * (_blindPosition - 5),
                                width: MediaQuery.of(context).size.width * 0.40, // example
                                color: const Color.fromARGB(255, 121, 85, 72),
                              );
                            }),
                          ),
                        )
                      ),
                    ],
                  ),
                  // Slider on the side
                  Align(
                    alignment: Alignment.centerRight,
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
                    } else {
                      days.remove(day);
                    }
                  });
                },
              );
            }).toList(),
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
          ]
        )
      ],
    );
  }
}