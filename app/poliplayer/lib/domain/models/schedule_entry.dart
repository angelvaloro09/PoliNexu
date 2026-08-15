class ScheduleSession {
  final String day;
  final String startTime;
  final String endTime;
  final String? building;
  final String? classroom;

  const ScheduleSession({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.building,
    this.classroom,
  });
}

class ScheduleEntry {
  final String group;
  final String subject;
  final String teachers;
  final List<ScheduleSession> sessions;

  const ScheduleEntry({
    required this.group,
    required this.subject,
    required this.teachers,
    required this.sessions,
  });
}
