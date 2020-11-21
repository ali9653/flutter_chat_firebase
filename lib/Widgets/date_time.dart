import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ConvertDateTime {
  Timestamp timestamp;

  ConvertDateTime({
    @required this.timestamp,
  });
  DateTime nextMeetingDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000)
        .toLocal();
  }

  String nextMeetingDateString() {
    DateTime dateTime = nextMeetingDateTime();
    return '${returnMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
  }

  String nextMeetingTimeString() {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute}';
  }

  static int correctMonthNumber(int monthNumber, int subNumber) {
    if (monthNumber > subNumber) {
      return monthNumber - subNumber;
    } else {
      return 12 + monthNumber - subNumber;
    }
  }

  static String returnMonthName(int monthNumber) {
    switch (monthNumber) {
      case 1:
        {
          return 'Jan';
        }
        break;

      case 2:
        {
          return 'Feb';
        }
        break;
      case 3:
        {
          return 'March';
        }
        break;
      case 4:
        {
          return 'April';
        }
        break;
      case 5:
        {
          return 'May';
        }
        break;
      case 6:
        {
          return 'June';
        }
        break;
      case 7:
        {
          return 'July';
        }
        break;
      case 8:
        {
          return 'August';
        }
        break;
      case 9:
        {
          return 'Sept';
        }
        break;
      case 10:
        {
          return 'Oct';
        }
        break;
      case 11:
        {
          return 'Nov';
        }
        break;
      case 12:
        {
          return 'Dec';
        }
        break;
      default:
        {
          return '';
        }
    }
  }

  static int _getNumberOfMonths(DateTime d1) {
    int _daysDifference = DateTime.now().difference(d1).inDays;
    return _daysDifference ~/ 30;
  }

  static int _getNumberOfYears(DateTime d1) {
    int _daysDifference = DateTime.now().difference(d1).inDays;
    return _daysDifference ~/ 365;
  }

  static String durationFromEvent(Timestamp timestampOfEvent) {
    DateTime _date =
    DateTime.fromMillisecondsSinceEpoch(timestampOfEvent.seconds * 1000);
    int _dateYearDifference = _getNumberOfYears(_date);
    int _dateMonthDifference = _getNumberOfMonths(_date);
    int _dateDaysDifference = DateTime.now().difference(_date).inDays;
    int _dateHoursDifference = DateTime.now().difference(_date).inHours;
    int _dateMinutesDifference = DateTime.now().difference(_date).inMinutes;
    if (_dateYearDifference <= 0 &&
        _dateMonthDifference <= 0 &&
        _dateDaysDifference <= 0 &&
        _dateHoursDifference <= 0 &&
        _dateMinutesDifference < 1) {
      return 'Just Now';
    } else if (_dateYearDifference <= 0 &&
        _dateMonthDifference <= 0 &&
        _dateDaysDifference <= 0 &&
        _dateHoursDifference < 1) {
      return '$_dateMinutesDifference mins ago';
    } else if (_dateYearDifference <= 0 &&
        _dateMonthDifference <= 0 &&
        _dateDaysDifference < 1) {
      return '$_dateHoursDifference hrs ago';
    } else if (_dateYearDifference <= 0 && _dateMonthDifference <= 0) {
      return '$_dateDaysDifference days ago';
    } else if (_dateYearDifference <= 0) {
      return '$_dateMonthDifference months ago';
    } else {
      return '$_dateYearDifference year ago';
    }
  }
}
