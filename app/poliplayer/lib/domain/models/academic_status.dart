class AcademicStatusSubject {
  final String code;
  final String subject;
  final String period;
  final String times;

  const AcademicStatusSubject({
    required this.code,
    required this.subject,
    required this.period,
    required this.times,
  });
}

class AcademicStatus {
  final List<AcademicStatusSubject> failed;
  final List<AcademicStatusSubject> notTaken;
  final List<AcademicStatusSubject> outOfSequence;

  const AcademicStatus({
    required this.failed,
    required this.notTaken,
    required this.outOfSequence,
  });
}
