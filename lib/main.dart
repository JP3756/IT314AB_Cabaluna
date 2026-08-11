import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, size: 56, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Icon(Icons.star, color: Colors.teal, size: 32),
                      const SizedBox(height: 8),
                      const Text('JP Cabaluna', style: TextStyle(color: Colors.teal)),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('BSIT-3', style: TextStyle(color: Colors.teal)),
                      const SizedBox(height: 12),
                      const Text(
                        'My First Flutter Application',
                        style: TextStyle(color: Colors.teal),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Chip(
                        label: Text('August 11, 2026'),
                        backgroundColor: Color(0xFFE0F2F1),
                      ),
                      const SizedBox(height: 12),
                      const Text('My Hobby'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('21', style: TextStyle(color: Colors.teal)),
                          SizedBox(width: 10),
                          Text('May 5, 2005', style: TextStyle(color: Colors.teal)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('My Favorites'),
                      SizedBox(height: 8),
                      Text('Favorite Game'),
                      Text('Favorite Food'),
                      Text('Favorite Movie'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Elevated Button'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
