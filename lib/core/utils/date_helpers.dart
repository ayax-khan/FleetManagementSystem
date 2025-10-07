// lib/core/utils/date_helpers.dart
import 'package:intl/intl.dart';

class DateHelpers {
  // Common date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MMM yyyy';
  static const String dayMonthFormat = 'dd MMM';

  // Format date to string
  static String formatDate(DateTime date, {String format = dateFormat}) {
    return DateFormat(format).format(date);
  }

  // Parse string to date
  static DateTime? parseDate(String dateString, {String format = dateFormat}) {
    try {
      return DateFormat(format).parseStrict(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get today's date at start of day (00:00:00)
  static DateTime startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Get today's date at end of day (23:59:59)
  static DateTime endOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  // Get start of week (Monday)
  static DateTime startOfWeek([DateTime? date]) {
    final current = date ?? DateTime.now();
    return current.subtract(Duration(days: current.weekday - 1));
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek([DateTime? date]) {
    final current = date ?? DateTime.now();
    return current.add(Duration(days: DateTime.daysPerWeek - current.weekday));
  }

  // Get start of month
  static DateTime startOfMonth([DateTime? date]) {
    final current = date ?? DateTime.now();
    return DateTime(current.year, current.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth([DateTime? date]) {
    final current = date ?? DateTime.now();
    return DateTime(current.year, current.month + 1, 0, 23, 59, 59);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // Get age from birth date
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Get difference in days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Get readable time difference (e.g., "2 hours ago")
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Get business days between two dates (excluding weekends)
  static int businessDaysBetween(DateTime from, DateTime to) {
    int businessDays = 0;
    DateTime current = from;

    while (current.isBefore(to) || current.isAtSameMomentAs(to)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return businessDays;
  }

  // Check if date is a weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Add business days to a date
  static DateTime addBusinessDays(DateTime date, int days) {
    DateTime result = date;
    int added = 0;

    while (added < days) {
      result = result.add(const Duration(days: 1));
      if (!isWeekend(result)) {
        added++;
      }
    }

    return result;
  }

  // Get fiscal year for a date
  static int getFiscalYear(DateTime date, {int fiscalStartMonth = 7}) {
    return date.month >= fiscalStartMonth ? date.year + 1 : date.year;
  }

  // Get quarter for a date
  static int getQuarter(DateTime date) {
    return ((date.month - 1) / 3).floor() + 1;
  }

  // Format duration to readable string
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Get list of dates in a range
  static List<DateTime> getDatesInRange(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  // Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get week number of the year
  static int getWeekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final days = date.difference(firstDay).inDays;
    return ((days + firstDay.weekday) / 7).ceil();
  }

  // Convert 12-hour time to 24-hour format
  static String convertTo24Hour(String time12Hour) {
    try {
      final format = DateFormat('h:mm a');
      final date = format.parse(time12Hour);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return time12Hour;
    }
  }

  // Convert 24-hour time to 12-hour format
  static String convertTo12Hour(String time24Hour) {
    try {
      final format = DateFormat('HH:mm');
      final date = format.parse(time24Hour);
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return time24Hour;
    }
  }
}
