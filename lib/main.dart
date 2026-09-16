import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// This stores one student's information
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

// This is the main app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Directory',
      home: const MyHomePage(),
    );
  }
}

// This is the student directory
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() {
    return MyHomePageState();
  }
}

// This controls the student directory
class MyHomePageState extends State<MyHomePage> {
  // This tells us if the app is loading
  bool isLoading = true;

  // This stores the students
  List<Profile> students = [];

  @override
  void initState() {
    super.initState();

    loadStudents();
  }

  // This creates the students
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

  // This changes Active to Inactive or Inactive to Active
  void changeStatus(int index) {
    setState(() {
      if (students[index].active == true) {
        students[index].active = false;
      } else {
        students[index].active = true;
      }
    });
  }

  // This changes Favorite on or off
  void changeFavorite(int index) {
    setState(() {
      if (students[index].favorite == true) {
        students[index].favorite = false;
      } else {
        students[index].favorite = true;
      }
    });
  }

  // This deletes a student
  void deleteStudent(int index) {
    setState(() {
      students.removeAt(index);
    });
  }

  // This edits the student's name
  void editStudent(int index) {
    TextEditingController nameController =
        TextEditingController();

    nameController.text = students[index].name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Student'),

          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Student Name',
              border: OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  students[index].name = nameController.text;
                });

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // This decides what screen should be shown
  Widget showBody() {
    // Flag 4: Show loading screen
    if (isLoading == true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),

            SizedBox(height: 15),

            Text(
              'Loading students...',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    // Flag 3: Show empty screen when there are no students
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
              child: const Text('Add Student'),
            ),
          ],
        ),
      );
    }

    // Flag 5: Show student list
    return ListView.builder(
      padding: const EdgeInsets.all(16),

      itemCount: students.length,

      itemBuilder: (context, index) {
        Profile student = students[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Student image
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

                      // Flag 2: Show star only when favorite
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

                // Student information
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

                Text(
                  'Year Level: ' + student.yearLevel,
                ),

                Text(
                  'Age: ' + student.age.toString(),
                ),

                Text(
                  'Hobby: ' + student.hobby,
                ),

                const SizedBox(height: 10),

                const Divider(),

                Text(
                  'Student ID: ' + student.studentId,
                ),

                Text(
                  'Email: ' + student.email,
                ),

                Text(
                  'Favorite Subject: ' +
                      student.favoriteSubject,
                ),

                const SizedBox(height: 10),

                // Flag 1: Show Active or Inactive
                if (student.active == true)
                  const Text(
                    'Status: Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                if (student.active == false)
                  const Text(
                    'Status: Inactive',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                // Flag 2: Show warning only when inactive
                if (student.active == false)
                  const Text(
                    'Warning: This student is inactive.',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),

                const SizedBox(height: 10),

                // Favorite button - NO TERNARY OPERATOR
                ElevatedButton(
                  onPressed: () {
                    changeFavorite(index);
                  },
                  child: Builder(
                    builder: (context) {
                      String favoriteText;

                      if (student.favorite == true) {
                        favoriteText = 'Unfavorite';
                      } else {
                        favoriteText = 'Favorite';
                      }

                      return Text(favoriteText);
                    },
                  ),
                ),

                // Change status button
                ElevatedButton(
                  onPressed: () {
                    changeStatus(index);
                  },
                  child: const Text(
                    'Toggle Status',
                  ),
                ),

                // Edit button
                ElevatedButton(
                  onPressed: () {
                    editStudent(index);
                  },
                  child: const Text(
                    'Edit',
                  ),
                ),

                // Flag 2: Delete only appears when active
                if (student.active == true)
                  ElevatedButton(
                    onPressed: () {
                      deleteStudent(index);
                    },
                    child: const Text(
                      'Delete',
                    ),
                  ),
              ],
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
        title: const Text(
          'Student Directory',
        ),

        // Refresh button
        actions: [
          IconButton(
            onPressed: () {
              loadStudents();
            },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // Show one of the three states
      body: showBody(),
    );
  }
}