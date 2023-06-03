import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TargetDateBar extends StatelessWidget {
  final DateTime targetDate;
  final String period;
  final int duration;
  final bool isDone;

  TargetDateBar(
      {required this.targetDate,
      required this.period,
      required this.duration,
      required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 300),
      padding: EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: this.isDone == false && this.period != 'Past'
            ? Colors.blue
            : Colors.grey,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 16.0,
            color: Colors.white,
          ),
          SizedBox(width: 4.0),
          Text(
            '${DateFormat('dd-MM-yyyy – kk:mm').format(this.targetDate.toLocal())} / ${this.period} x${this.duration}',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}