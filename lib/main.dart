import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The app starts here. We load the saved students BEFORE the app
// opens, so the very first screen already has the saved records.
// "async" and "await" are needed because reading local storage
// takes a moment.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedStudents();
  runApp(const MyApp());
}

// This stores one student's information.
// We use this same class everywhere in the app so every screen
// is looking at and editing the exact same student data.
class Profile {
  String imageUrl;
  String name;
  String course;
  String yearLevel;
  int age;
  String hobby;
  String studentId;
  String email;
  String favoriteSubject;

  bool active;
  bool favorite;

  Profile({
    required this.imageUrl,
    required this.name,
    required this.course,
    required this.yearLevel,
    required this.age,
    required this.hobby,
    required this.studentId,
    required this.email,
    required this.favoriteSubject,
    required this.active,
    required this.favorite,
  });

  // Turns a student into a Map so it can be saved as JSON text.
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'name': name,
      'course': course,
      'yearLevel': yearLevel,
      'age': age,
      'hobby': hobby,
      'studentId': studentId,
      'email': email,
      'favoriteSubject': favoriteSubject,
      'active': active,
      'favorite': favorite,
    };
  }

  // Turns a saved Map back into a student. The "??" gives a safe
  // default if a value is missing from the saved data.
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      imageUrl: (map['imageUrl'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      course: (map['course'] ?? '') as String,
      yearLevel: (map['yearLevel'] ?? '') as String,
      age: (map['age'] ?? 0) as int,
      hobby: (map['hobby'] ?? '') as String,
      studentId: (map['studentId'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      favoriteSubject: (map['favoriteSubject'] ?? '') as String,
      active: (map['active'] ?? true) as bool,
      favorite: (map['favorite'] ?? false) as bool,
    );
  }
}

// ---------------------------------------------------------------
// SHARED STUDENT DATA + LOCAL STORAGE
// ---------------------------------------------------------------

// This is the ONE list of students used by the whole app. The Student
// List screen shows it, the Add Student screen adds to it and checks
// it for duplicate IDs, and the Details screen edits its students.
List<Profile> allStudents = [];

// This is the name (key) the student list is saved under inside
// the phone's local storage (SharedPreferences).
const String storageKey = 'saved_students';

// These are the starting students. They are only used the very first
// time the app opens (when nothing has been saved yet).
List<Profile> createSampleStudents() {
  return [
    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
      name: 'Maria',
      course: 'BSIT',
      yearLevel: '3rd Year',
      age: 20,
      hobby: 'Reading',
      studentId: '2023-0001',
      email: 'maria@example.com',
      favoriteSubject: 'Programming',
      active: true,
      favorite: false,
    ),
    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
      name: 'John',
      course: 'BSIT',
      yearLevel: '3rd Year',
      age: 21,
      hobby: 'Gaming',
      studentId: '2023-0002',
      email: 'john@example.com',
      favoriteSubject: 'Database Systems',
      active: false,
      favorite: false,
    ),
    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
      name: 'Aaron',
      course: 'BSIT',
      yearLevel: '2nd Year',
      age: 20,
      hobby: 'Chess',
      studentId: '2024-0003',
      email: 'aaron@example.com',
      favoriteSubject: 'Data Structures',
      active: true,
      favorite: false,
    ),
    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1552053831-71594a27632d?w=500',
      name: 'Juan',
      course: 'BSIT',
      yearLevel: '3rd Year',
      age: 21,
      hobby: 'Basketball',
      studentId: '2023-0004',
      email: 'juan@example.com',
      favoriteSubject: 'Networking',
      active: false,
      favorite: false,
    ),
    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
      name: 'Sophia',
      course: 'BSIT',
      yearLevel: '2nd Year',
      age: 20,
      hobby: 'Drawing',
      studentId: '2024-0005',
      email: 'sophia@example.com',
      favoriteSubject: 'Web Development',
      active: true,
      favorite: false,
    ),
    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
      name: 'David',
      course: 'BSIT',
      yearLevel: '3rd Year',
      age: 22,
      hobby: 'Music',
      studentId: '2023-0006',
      email: 'david@example.com',
      favoriteSubject: 'Software Engineering',
      active: true,
      favorite: false,
    ),
  ];
}

// SAVE: turns the whole list into JSON text and stores it locally.
// Every time a student is added, edited, or deleted, we call this
// so the saved data always matches what is on the screen.
Future<void> saveStudents() async {
  final prefs = await SharedPreferences.getInstance();

  final List<Map<String, dynamic>> data = [];
  for (final student in allStudents) {
    data.add(student.toMap());
  }

  await prefs.setString(storageKey, jsonEncode(data));
}

// LOAD: reads the saved JSON text and rebuilds the student list.
Future<void> loadSavedStudents() async {
  final prefs = await SharedPreferences.getInstance();
  final String? savedText = prefs.getString(storageKey);

  // Nothing has been saved yet (first time the app is opened), so we
  // start with the sample students and save them.
  if (savedText == null) {
    allStudents = createSampleStudents();
    await saveStudents();
    return;
  }

  try {
    final List<dynamic> decoded = jsonDecode(savedText) as List<dynamic>;
    final List<Profile> loaded = [];

    for (final item in decoded) {
      loaded.add(Profile.fromMap(item as Map<String, dynamic>));
    }

    // If the saved list is empty (everyone was deleted), it stays
    // empty. Deleted students do NOT come back after a restart.
    allStudents = loaded;
  } catch (_) {
    // The saved data was damaged, so we fall back to the samples
    // instead of crashing the app.
    allStudents = createSampleStudents();
    await saveStudents();
  }
}

// Turns a year number into the same text style the sample students
// use, for example 3 becomes "3rd Year".
String yearLevelLabel(int year) {
  if (year == 1) {
    return '1st Year';
  }
  if (year == 2) {
    return '2nd Year';
  }
  if (year == 3) {
    return '3rd Year';
  }
  return '${year}th Year';
}

// Shows the student's picture. New students are enrolled without a
// picture, and a picture can also fail to load (no internet), so in
// both cases we show a simple person icon instead of crashing.
Widget buildAvatar(String imageUrl, double size) {
  final Widget placeholder = CircleAvatar(
    radius: size / 2,
    child: Icon(Icons.person, size: size * 0.6),
  );

  if (imageUrl.isEmpty) {
    return placeholder;
  }

  return ClipOval(
    child: Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return placeholder;
      },
    ),
  );
}

// This is the main app.
// It tells Flutter which screen to open first, and it also
// tells Flutter the "named routes" for the app, which is basically
// a list of named addresses that point to a screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Directory',

      // This tells the app which screen should show up first
      // when the app opens.
      initialRoute: '/student-list',

      // These are the simple routes. A simple route does not need
      // any extra information to open, it just opens the screen.
      routes: {
        '/student-list': (context) => const StudentListScreen(),
        '/add-student': (context) => const AddStudentScreen(),
      },

      // The Student Details screen is a bit different because it
      // needs to know WHICH student was tapped before it can open.
      // Because of that, we cannot put it in the simple routes list
      // above. Instead we catch it here and manually read the
      // student that was passed in.
      onGenerateRoute: (settings) {
        if (settings.name == '/student-details') {
          // settings.arguments holds whatever data was sent when
          // this route was opened. We expect it to be a Profile.
          final selectedStudent = settings.arguments as Profile;

          return MaterialPageRoute(
            builder: (context) {
              return StudentDetailsScreen(student: selectedStudent);
            },
          );
        }

        // If the route name does not match anything we know,
        // we return null and Flutter will handle the error itself.
        return null;
      },
    );
  }
}

// This is the Student List screen.
// This screen shows every student as a card. Tapping a card opens
// that student's Details screen.
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() {
    return StudentListScreenState();
  }
}

// This controls everything happening on the Student List screen.
class StudentListScreenState extends State<StudentListScreen> {
  // This tells us if the student data is still loading.
  bool isLoading = true;

  // The students shown on this screen are the shared allStudents
  // list. Using the same list as the Add Student screen is what lets
  // a newly enrolled student show up here.
  List<Profile> get students {
    return allStudents;
  }

  @override
  void initState() {
    super.initState();

    // As soon as this screen is created, start loading the students.
    loadStudents();
  }

  // This shows the loading spinner for two seconds, then reads the
  // saved students from local storage and shows them.
  Future<void> loadStudents() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    await loadSavedStudents();

    // If the screen was closed while we were waiting, stop here.
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });
  }

  // Used by the "Reload Students" button when the list is empty.
  // It puts the sample students back and saves them.
  Future<void> restoreSampleStudents() async {
    allStudents = createSampleStudents();
    await saveStudents();
    await loadStudents();
  }

  // This flips a student's status from Active to Inactive, or from
  // Inactive back to Active.
  void changeStatus(int index) {
    setState(() {
      if (students[index].active == true) {
        students[index].active = false;
      } else {
        students[index].active = true;
      }
    });

    // Save the change so it is still there after a restart.
    saveStudents();
  }

  // This flips a student's favorite on or off.
  void changeFavorite(int index) {
    setState(() {
      if (students[index].favorite == true) {
        students[index].favorite = false;
      } else {
        students[index].favorite = true;
      }
    });

    saveStudents();
  }

  // This removes a student from the list completely.
  void deleteStudent(int index) {
    setState(() {
      students.removeAt(index);
    });

    // Save the shorter list so the deleted student stays deleted
    // after a restart.
    saveStudents();
  }

  // This is called when the user taps on a student card.
  // It sends the tapped student over to the Student Details screen
  // by attaching it as "arguments" on the route.
  Future<void> openStudentDetails(Profile tappedStudent) async {
    // We use "await" here so that once the user comes back from the
    // Details screen (for example after editing something), we can
    // immediately refresh this screen to show the updated info.
    await Navigator.pushNamed(
      context,
      '/student-details',
      arguments: tappedStudent,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      // Nothing needs to change here manually because "students"
      // holds the same Profile objects that were edited on the
      // Details screen. Calling setState just repaints the screen
      // so the updated values show up.
    });
  }

  // This opens the Add Student screen when the person taps the
  // add-student button in the app bar. When the Add Student screen
  // closes (after a successful enrollment), we refresh this screen
  // so the new student appears in the list.
  Future<void> openAddStudent() async {
    await Navigator.pushNamed(context, '/add-student');

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // This decides what should be shown in the middle of the screen:
  // a loading spinner, an empty state, or the actual student list.
  Widget showBody() {
    // While the students are still loading, show a spinner.
    if (isLoading == true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text(
              'Loading students...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    // If loading finished but there are no students, show a
    // friendly empty state instead of a blank screen.
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 15),
            const Text(
              'No students found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'There are no students in the directory.',
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                restoreSampleStudents();
              },
              child: const Text('Reload Students'),
            ),
          ],
        ),
      );
    }

    // Otherwise, we have students to show, so build a scrolling
    // list of student cards.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        Profile student = students[index];

        // Wrapping the Card in an InkWell lets the whole card react
        // to taps, so tapping anywhere on the card opens the
        // Student Details screen for that student.
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              openStudentDetails(student);
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student picture, with a star on top if the
                  // student is marked as a favorite.
                  Center(
                    child: Stack(
                      children: [
                        buildAvatar(student.imageUrl, 100),
                        if (student.favorite == true)
                          const Positioned(
                            right: 0,
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Name: ${student.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Course: ${student.course}',
                  ),

                  const SizedBox(height: 10),

                  // Show Active in green, or Inactive in red.
                  if (student.active == true)
                    const Text(
                      'Status: Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  if (student.active == false)
                    const Text(
                      'Status: Inactive',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // A small hint so the user knows they can tap the
                  // card to see more information.
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tap the card to view full details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            changeFavorite(index);
                          },
                          child: Builder(
                            builder: (context) {
                              // We avoid the "? :" conditional
                              // expression on purpose and use a
                              // plain if/else with a normal String
                              // variable instead.
                              String favoriteButtonText;

                              if (student.favorite == true) {
                                favoriteButtonText = 'Unfavorite';
                              } else {
                                favoriteButtonText = 'Favorite';
                              }

                              return Text(favoriteButtonText);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            changeStatus(index);
                          },
                          child: const Text('Toggle Status'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Only active students can be deleted. This is
                  // the same "show or hide" idea from the earlier
                  // CTF, just reused here.
                  if (student.active == true)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          deleteStudent(index);
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Directory'),
        actions: [
          // Refresh button reloads the student list from local
          // storage.
          IconButton(
            onPressed: () {
              loadStudents();
            },
            icon: const Icon(Icons.refresh),
          ),

          // Add Student button opens the Add Student screen.
          IconButton(
            onPressed: openAddStudent,
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: showBody(),
    );
  }
}

// This is the Student Details screen.
// It receives one student (passed in through the constructor) and
// shows that student's full information. It also lets the admin
// open an Edit modal to change the student's name and course.
class StudentDetailsScreen extends StatefulWidget {
  // This is the student whose details we are showing. It is passed
  // in from the Student List screen when the card was tapped.
  final Profile student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() {
    return StudentDetailsScreenState();
  }
}

class StudentDetailsScreenState extends State<StudentDetailsScreen> {
  // This opens a bottom sheet (a panel that slides up from the
  // bottom of the screen) with a small form for editing the
  // student's name and course.
  void openEditModal() {
    TextEditingController nameController = TextEditingController();
    nameController.text = widget.student.name;

    TextEditingController courseController = TextEditingController();
    courseController.text = widget.student.course;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          // This padding pushes the form up above the on-screen
          // keyboard so the text fields are never hidden behind it.
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Student',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Closes the modal without saving anything.
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.student.name = nameController.text;
                          widget.student.course = courseController.text;
                        });

                        // Save the edited student to local storage
                        // so the change survives a restart.
                        saveStudents();

                        // Closes the modal after saving.
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Shows "Not provided" for details that were not collected on the
  // enrollment form (age, hobby, favorite subject).
  String showOrNotProvided(String value) {
    if (value.trim().isEmpty) {
      return 'Not provided';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    Profile student = widget.student;

    String ageText;
    if (student.age == 0) {
      ageText = 'Not provided';
    } else {
      ageText = student.age.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: [
          // Tapping this pencil icon opens the Edit modal.
          IconButton(
            onPressed: openEditModal,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  buildAvatar(student.imageUrl, 140),
                  if (student.favorite == true)
                    const Positioned(
                      right: 0,
                      child: Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 34,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                student.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 5),

            if (student.active == true)
              const Center(
                child: Text(
                  'Status: Active',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (student.active == false)
              const Center(
                child: Text(
                  'Status: Inactive',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 10),

            Text(
              'Student ID: ${student.studentId}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Course: ${student.course}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Year Level: ${student.yearLevel}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Age: $ageText',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Hobby: ${showOrNotProvided(student.hobby)}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Email: ${student.email}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Favorite Subject: ${showOrNotProvided(student.favoriteSubject)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// This is the Add Student screen.
// It is now a real enrollment form. It has to be a StatefulWidget
// because it owns text controllers and needs to remember things
// while the administrator types.
class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() {
    return AddStudentScreenState();
  }
}

class AddStudentScreenState extends State<AddStudentScreen> {
  // The Form key lets us ask the whole form "is everything valid?"
  // when the Enroll button is pressed.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // One controller per input field. A controller lets us read what
  // was typed (and clear it after a successful enrollment).
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController yearLevelController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Stops the button from being pressed twice while saving.
  bool isSaving = false;

  // Controllers must be cleaned up when the screen closes.
  @override
  void dispose() {
    studentIdController.dispose();
    nameController.dispose();
    courseController.dispose();
    yearLevelController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ---------------- VALIDATORS ----------------
  // A validator returns a message (String) when the value is bad,
  // or null when the value is fine. Flutter shows the message in
  // red under the field.

  String? validateStudentId(String? value) {
    final String text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Student ID is required';
    }

    // Duplicate check: compare with every existing student's ID,
    // ignoring capital letters and extra spaces.
    for (final student in allStudents) {
      if (student.studentId.trim().toLowerCase() == text.toLowerCase()) {
        return 'This Student ID already exists';
      }
    }

    return null;
  }

  String? validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? validateCourse(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Course is required';
    }
    return null;
  }

  String? validateYearLevel(String? value) {
    final String text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Year level is required';
    }

    // int.tryParse returns null if the text is not a whole number.
    final int? year = int.tryParse(text);

    if (year == null || year < 1 || year > 5) {
      return 'Enter a year level from 1 to 5';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final String text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Email address is required';
    }

    // A simple email pattern: something, an @, something, a dot,
    // something, with no spaces.
    final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(text)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ---------------- SUBMIT ----------------
  Future<void> submitForm() async {
    // validate() runs every validator. If even one field is bad, it
    // shows the error messages and returns false, so we stop here
    // and NO student is created.
    final bool formIsValid = formKey.currentState!.validate();

    if (formIsValid == false) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    // Create the new student from what was typed.
    final int year = int.parse(yearLevelController.text.trim());

    final Profile newStudent = Profile(
      imageUrl: '',
      name: nameController.text.trim(),
      course: courseController.text.trim(),
      yearLevel: yearLevelLabel(year),
      age: 0,
      hobby: '',
      studentId: studentIdController.text.trim(),
      email: emailController.text.trim(),
      favoriteSubject: '',
      active: true,
      favorite: false,
    );

    // Put the new student at the top of the shared list.
    allStudents.insert(0, newStudent);

    // Clear the form fields after a successful enrollment. Calling
    // reset() right after also clears any old error messages, so
    // the form is completely fresh.
    studentIdController.clear();
    nameController.clear();
    courseController.clear();
    yearLevelController.clear();
    emailController.clear();
    formKey.currentState!.reset();

    // Save the updated list to local storage.
    await saveStudents();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newStudent.name} was enrolled successfully')),
    );

    // Go back to the Student List. The list screen refreshes itself
    // when we return, so the new student is displayed.
    Navigator.pop(context, newStudent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          // After the first time a field is touched, its error
          // message updates live as the person fixes it.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enroll a New Student',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: studentIdController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'e.g. 2026-0007',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: validateStudentId,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: courseController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  hintText: 'e.g. BSIT',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                validator: validateCourse,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: yearLevelController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Year Level',
                  hintText: '1 to 5',
                  prefixIcon: Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(),
                ),
                validator: validateYearLevel,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'name@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: validateEmail,
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (isSaving == false) {
                      submitForm();
                    }
                  },
                  child: const Text('Enroll Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}