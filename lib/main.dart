import 'package:flutter/material.dart';

void main() {
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

  // This stores all of the students currently in the directory.
  List<Profile> students = [];

  @override
  void initState() {
    super.initState();

    // As soon as this screen is created, start loading the students.
    loadStudents();
  }

  // This pretends to fetch the students from somewhere (like a
  // server) by waiting two seconds and then filling the list.
  void loadStudents() {
    setState(() {
      isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        students = [
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

        isLoading = false;
      });
    });
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
  }

  // This removes a student from the list completely.
  void deleteStudent(int index) {
    setState(() {
      students.removeAt(index);
    });
  }

  // This is called when the user taps on a student card.
  // It sends the tapped student over to the Student Details screen
  // by attaching it as "arguments" on the route.
  void openStudentDetails(Profile tappedStudent) async {
    // We use "await" here so that once the user comes back from the
    // Details screen (for example after editing something), we can
    // immediately refresh this screen to show the updated info.
    await Navigator.pushNamed(
      context,
      '/student-details',
      arguments: tappedStudent,
    );

    setState(() {
      // Nothing needs to change here manually because "students"
      // holds the same Profile objects that were edited on the
      // Details screen. Calling setState just repaints the screen
      // so the updated values show up.
    });
  }

  // This opens the Add Student screen when the person taps the
  // add-student button in the app bar.
  void openAddStudent() {
    Navigator.pushNamed(context, '/add-student');
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
                loadStudents();
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
                        ClipOval(
                          child: Image.network(
                            student.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
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
                    'Name: ' + student.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Course: ' + student.course,
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
          // Refresh button reloads the student list from scratch.
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

  @override
  Widget build(BuildContext context) {
    Profile student = widget.student;

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
                  ClipOval(
                    child: Image.network(
                      student.imageUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
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
              'Student ID: ' + student.studentId,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Course: ' + student.course,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Year Level: ' + student.yearLevel,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Age: ' + student.age.toString(),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Hobby: ' + student.hobby,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Email: ' + student.email,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Favorite Subject: ' + student.favoriteSubject,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// This is the Add Student screen.
// For now this screen does not have any input fields yet. It only
// exists as its own destination so that navigation between screens
// is already working. The actual form can be added later.
class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              'Add Student Form',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'The input fields for this screen will be added later.',
            ),
          ],
        ),
      ),
    );
  }
}