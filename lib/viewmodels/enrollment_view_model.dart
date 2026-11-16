import '../models/enrollment.dart';
import '../repositories/enrollment_repository.dart';
import 'base_view_model.dart';

class EnrollmentViewModel extends BaseViewModel {
  EnrollmentViewModel(this._repo);
  final EnrollmentRepository _repo;

  List<EnrollmentDetail> items = [];
  int? studentFilter;

  List<EnrollmentDetail> get active => items.where((e) => e.enrollment.isEnrolled).toList();

  // units of the enrolled subjects
  int get totalUnits => active.fold(0, (sum, e) => sum + e.units);

  Future<bool> load({int? studentId, bool keepFilter = false}) {
    if (!keepFilter) studentFilter = studentId;
    return run(() async => items = await _repo.list(studentId: studentFilter));
  }

  Future<bool> enroll({required int studentId, required int subjectId, required int scheduleId}) =>
      run(() async {
        await _repo.enroll(studentId: studentId, subjectId: subjectId, scheduleId: scheduleId);
        items = await _repo.list(studentId: studentFilter);
      });

  Future<bool> drop(int enrollmentId) => run(() async {
        await _repo.drop(enrollmentId);
        items = await _repo.list(studentId: studentFilter);
      });
}
