import '../models/student.dart';
import '../repositories/student_repository.dart';
import 'base_view_model.dart';

class StudentViewModel extends BaseViewModel {
  StudentViewModel(this._repo);
  final StudentRepository _repo;

  List<Student> items = [];
  String search = '';

  Future<bool> load({String? search}) {
    if (search != null) this.search = search;
    return run(() async => items = await _repo.list(search: this.search));
  }

  Future<bool> save(Student s) => run(() async {
        if (s.student_id == null) {
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
