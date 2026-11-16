import '../models/grades.dart';
import '../repositories/grades_repository.dart';
import 'base_view_model.dart';

class GradesViewModel extends BaseViewModel {
  GradesViewModel(this._repo);
  final GradesRepository _repo;

  List<GradeDetail> items = [];
  int? studentFilter;

  // average weighted by units, null if no grades
  double? get weightedAverage {
    final units = items.fold<int>(0, (s, g) => s + g.units);
    if (units == 0) return null;
    return items.fold<double>(0, (s, g) => s + g.grade.grade_value * g.units) / units;
  }

  Future<bool> load({int? studentId, bool keepFilter = false}) {
    if (!keepFilter) studentFilter = studentId;
    return run(() async => items = await _repo.list(studentId: studentFilter));
  }

  Future<bool> save(Grades g) => run(() async {
        if (g.grade_id == null) {
          await _repo.add(g);
        } else {
          await _repo.update(g);
        }
        items = await _repo.list(studentId: studentFilter);
      });

  Future<bool> remove(int gradeId) => run(() async {
        await _repo.delete(gradeId);
        items = await _repo.list(studentId: studentFilter);
      });
}
