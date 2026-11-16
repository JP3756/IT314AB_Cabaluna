import '../models/schedule.dart';
import '../repositories/schedule_repository.dart';
import 'base_view_model.dart';

class ScheduleViewModel extends BaseViewModel {
  ScheduleViewModel(this._repo);
  final ScheduleRepository _repo;

  List<ScheduleDetail> items = [];
  int? subjectFilter;

  Future<bool> load({int? subjectId, bool keepFilter = false}) {
    if (!keepFilter) subjectFilter = subjectId;
    return run(() async => items = await _repo.list(subjectId: subjectFilter));
  }

  Future<bool> save(Schedule s) => run(() async {
        if (s.schedule_id == null) {
          await _repo.create(s);
        } else {
          await _repo.update(s);
        }
        items = await _repo.list(subjectId: subjectFilter);
      });

  Future<bool> remove(int id) => run(() async {
        await _repo.delete(id);
        items = await _repo.list(subjectId: subjectFilter);
      });
}
