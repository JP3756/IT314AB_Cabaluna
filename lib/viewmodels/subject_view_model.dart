import '../models/subject.dart';
import '../repositories/subject_repository.dart';
import 'base_view_model.dart';

class SubjectViewModel extends BaseViewModel {
  SubjectViewModel(this._repo);
  final SubjectRepository _repo;

  List<Subject> items = [];
  String search = '';

  Future<bool> load({String? search}) {
    if (search != null) this.search = search;
    return run(() async => items = await _repo.list(search: this.search));
  }

  Future<bool> save(Subject s) => run(() async {
        if (s.subject_id == null) {
          await _repo.create(s);
        } else {
          await _repo.update(s);
        }
        items = await _repo.list(search: search);
      });

  Future<bool> remove(int id) => run(() async {
        await _repo.delete(id);
        items = await _repo.list(search: search);
      });
}
