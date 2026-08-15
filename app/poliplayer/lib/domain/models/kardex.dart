class KardexSubject {
  final String key;
  final String subject;
  final String date;
  final String period;
  final String examType;
  final String grade;

  const KardexSubject({
    required this.key,
    required this.subject,
    required this.date,
    required this.period,
    required this.examType,
    required this.grade,
  });
}

class KardexSemester {
  final String label;
  final List<KardexSubject> subjects;

  const KardexSemester({required this.label, required this.subjects});
}

class Kardex {
  final String career;
  final String studyPlan;
  final String average;
  final List<KardexSemester> semesters;

  const Kardex({
    required this.career,
    required this.studyPlan,
    required this.average,
    required this.semesters,
  });
}
