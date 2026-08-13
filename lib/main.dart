import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}


class Profile {
  final String? imageUrl;
  final String? name;
  final String? course;
  final String? section;
  final int? age;
  final String? hobby;
  final double? height;
  final bool? isEnrolled;

  const Profile({
    this.imageUrl,
    this.name,
    this.course,
    this.section,
    this.age,
    this.hobby,
    this.height,
    this.isEnrolled,
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Flutter Demo Home Page',
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final Profile profile;

  const ProfileCard({
    super.key,
    required this.profile,
  });

  String textOrFallback(
    String? value, {
    String fallback = 'Not provided',
  }) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value;
  }

  String ageText() {
    return profile.age?.toString() ?? 'Not provided';
  }

  String heightText() {
    return profile.height != null
        ? profile.height.toString()
        : 'Not provided';
  }

  String enrolledText() {
    if (profile.isEnrolled == null) {
      return 'Not provided';
    }

    return profile.isEnrolled! ? 'YES' : 'NO';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: ClipOval(
                child: profile.imageUrl == null ||
                        profile.imageUrl!.trim().isEmpty
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
                        profile.imageUrl!,
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

            const Text(
              'My Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Name: ${textOrFallback(
                profile.name,
                fallback: 'Unknown',
              )}',
            ),

            Text(
              'Age: ${ageText()}',
            ),

            Text(
              'Height: ${heightText()}',
            ),

            Text(
              'Enrolled: ${enrolledText()}',
            ),

            Text(
              'Hobby: ${textOrFallback(profile.hobby)}',
            ),

            Text(
              'Course: ${textOrFallback(
                profile.course,
                fallback: 'Unknown',
              )}',
            ),

            Text(
              'Section: ${textOrFallback(profile.section)}',
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  static const List<Profile> profiles = [

    Profile(
      imageUrl:
          'https://static.vecteezy.com/system/resources/thumbnails/023/009/485/small2x/abstract-animal-owl-portrait-with-colorful-double-exposure-paint-with-generative-ai-free-photo.jpeg',
      name: 'JP',
      age: 21,
      height: 5.7,
      isEnrolled: true,
      hobby: 'Sleeping',
      course: 'BSIT',
      section: '1',
    ),

    Profile(
      imageUrl:
          'https://tse3.mm.bing.net/th/id/OIP.eyW6lqVewBfhIsQ1II-43wHaEo?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
      name: 'PJ',
      age: 20,
      height: 7.11,
      isEnrolled: true,
      hobby: 'Eating',
      course: 'IOT',
      section: '5',
    ),

    Profile(
      imageUrl:
          'https://www.bing.com/th/id/OIP.oaOiUTjgdNluepJElGfnBQHaE8?w=206&h=128&c=8&rs=1&qlt=90&o=6&pid=ImgAns&rm=2',
      name: 'Jess',
      age: 20,
      height: 7.11,
      isEnrolled: false,
      hobby: 'Eating bugs',
      course: 'Coding',
      section: '10',
    ),

    Profile(
      imageUrl:
          'https://www.bing.com/th/id/OIP.9VGPmrFwv5efx2jWmABMHgHaEO?w=241&h=128&c=8&rs=1&qlt=90&o=6&pid=ImgAns&rm=2',
      name: 'LIAM',
      age: 20,
      height: 7.11,
      isEnrolled: false,
      hobby: 'Thinking',
      course: 'Philosophy',
      section: '5',
    ),

    
    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1552053831-71594a27632d?w=500',
      name: 'SPIKEY',
      age: 20,
      height: 7.11,
      isEnrolled: true,
      hobby: 'Kung Fu',
      course: 'Karate',
      section: '5',
    ),

    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
      name: 'Maria',
      age: 20,
      height: 5.4,
      isEnrolled: true,
      hobby: null,
      course: 'BSIT',
      section: '1',
    ),

    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
      name: 'Juan',
      age: 21,
      height: 5.8,
      isEnrolled: true,
      hobby: 'Gaming',
      course: null,
      section: '2',
    ),

    Profile(
      imageUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
      name: null,
      age: null,
      height: null,
      isEnrolled: null,
      hobby: 'Drawing',
      course: 'MMA',
      section: '3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              for (final profile in profiles)
                ProfileCard(
                  profile: profile,
                ),
            ],
          ),
        ),
      ),
    );
  }
}