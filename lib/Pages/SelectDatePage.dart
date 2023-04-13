import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date and time

class SelectDatePage extends StatefulWidget {
  @override
  _SelectDatePageState createState() => _SelectDatePageState();
}

class _SelectDatePageState extends State<SelectDatePage> {
  DateTime _selectedDate = DateTime.now(); // Default selected date
  TimeOfDay _selectedTime =
      TimeOfDay.fromDateTime(DateTime.now()); // Default selected time

  // On date selected function
  void _onDateSelected(DateTime selected) {
    setState(() {
      _selectedDate = selected;
    });
  }

  // On time selected function
  void _onTimeSelected(TimeOfDay selected) {
    setState(() {
      _selectedTime = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Date formatter for displaying the selected date
    final dateFormatter = DateFormat('dd/MM/yyyy');
    // Time formatter for displaying the selected time
    final timeFormatter = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Date and Time'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20), // Spacer
          Text(
              'Selected Date: ${dateFormatter.format(_selectedDate)}', // Display selected date
              style: TextStyle(fontSize: 20)),
          SizedBox(height: 20), // Spacer
          Text(
            'Selected Time: ${timeFormatter.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20), // Spacer
          ElevatedButton(
            child: Text('Select Date'),
            onPressed: () async {
              final DateTime? selected = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (selected != null) {
                _onDateSelected(selected);
              }
            },
          ),
          ElevatedButton(
            child: Text('Select Time'),
            onPressed: () async {
              final TimeOfDay? selected = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (selected != null) {
                _onTimeSelected(selected);
              }
            },
          ),
        ],
      ),
    );
  }
}
