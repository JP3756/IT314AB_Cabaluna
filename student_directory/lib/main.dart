import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Profile {
  final String? imageUrl;
  final String? name;
  final String? course;
  final String? yearLevel;
  final int? age;
  final String? hobby;
  final String? studentId;
  final String? email;
  final String? favoriteSubject;

  const Profile({
    this.imageUrl,
    this.name,
    this.course,
    this.yearLevel,
    this.age,
    this.hobby,
    this.studentId,
    this.email,
    this.favoriteSubject,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Directory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Student Directory',
      ),
    );
  }
}

class ProfileCard extends StatefulWidget {
  final Profile profile;
  final VoidCallback onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onDelete,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool isFavorite = false;

  // FLAG 6 - EDIT TRIGGER
  void showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Student',
          ),
          content: Text(
            'You selected ${widget.profile.name}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Edit action selected for '
                      '${widget.profile.name}',
                    ),
                  ),
                );
              },
              child: const Text(
                'Edit',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      // FLAG 4 - CHANGE CARD APPEARANCE
      color: isFavorite ? Colors.teal.shade100 : null,

      child: InkWell(
        // FLAG 2 - TAP ANYWHERE ON CARD
        onTap: () {
          print(
            'Student card tapped: ${widget.profile.name}',
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipOval(
                  child: widget.profile.imageUrl == null ||
                          widget.profile.imageUrl!.trim().isEmpty
                      ? Container(
                          width: 104,
                          height: 104,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.person,
                            size: 50,
                          ),
                        )
                      : Image.network(
                          widget.profile.imageUrl!,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              width: 104,
                              height: 104,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.person,
                                size: 50,
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // NAME + FAVORITE HEART
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Name: ${widget.profile.name ?? 'Not provided'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // FLAG 4
                  if (isFavorite)
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 30,
                    ),
                ],
              ),

              Text(
                'Course: '
                '${widget.profile.course ?? 'Not provided'}',
              ),

              Text(
                'Year Level: '
                '${widget.profile.yearLevel ?? 'Not provided'}',
              ),

              Text(
                'Age: '
                '${widget.profile.age?.toString() ?? 'Not provided'}',
              ),

              Text(
                'Hobby: '
                '${widget.profile.hobby ?? 'Not provided'}',
              ),

              const SizedBox(height: 10),

              const Divider(),

              Text(
                'Student ID: '
                '${widget.profile.studentId ?? 'Not provided'}',
              ),

              Text(
                'Email: '
                '${widget.profile.email ?? 'Not provided'}',
              ),

              Text(
                'Favorite Subject: '
                '${widget.profile.favoriteSubject ?? 'Not provided'}',
              ),

              const SizedBox(height: 15),

              // FLAG 4 - FAVORITE
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isFavorite = !isFavorite;
                  });

                  print(
                    'Favorite button pressed for '
                    '${widget.profile.name}',
                  );
                },
                icon: Icon(
                  isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                label: Text(
                  isFavorite
                      ? 'FAVORITED'
                      : 'Favorite',
                ),
              ),

              const SizedBox(height: 8),

              // FLAG 6 - EDIT
              ElevatedButton.icon(
                onPressed: showEditDialog,
                icon: const Icon(
                  Icons.edit,
                ),
                label: const Text(
                  'Edit',
                ),
              ),

              const SizedBox(height: 8),

              // FLAG 5 - DELETE
              ElevatedButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete,
                ),
                label: const Text(
                  'Delete',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Profile> profiles = [
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
    ),
  ];

  // FLAG 5 - DELETE STUDENT
  void deleteStudent(Profile profile) {
    setState(() {
      profiles.remove(profile);
    });

    print(
      'Student deleted: ${profile.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedProfiles = List<Profile>.from(profiles)
      ..sort(
        (a, b) => a.name!.compareTo(b.name!),
      );

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: sortedProfiles.isEmpty
          ? const Center(
              child: Text(
                'No students found.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: sortedProfiles.length,

              itemBuilder: (context, index) {
                return ProfileCard(
                  profile: sortedProfiles[index],

                  onDelete: () {
                    deleteStudent(
                      sortedProfiles[index],
                    );
                  },
                );
              },
            ),
    );
  }
}