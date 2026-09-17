import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social UI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1114),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFE4D4D),
          brightness: Brightness.dark,
        ),
      ),
      home: const SocialScreen(),
    );
  }
}

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Friends', 'Messages', 'Requests'];

    final friends = [
      const Friend(
        name: 'MissYouLikeKrazy',
        status: 'Online - VALORANT',
        isOnline: true,
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
      ),
      const Friend(
        name: 'bread',
        status: 'Playing - VALORANT',
        isOnline: true,
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      ),
      const Friend(
        name: 'The14th',
        status: 'Playing - VALORANT',
        isOnline: true,
        avatarUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      ),
    ];

    final onlineFriends = [
      const Friend(
        name: 'Carlvendish',
        status: 'Away - Riot Mobile',
        isOnline: true,
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      ),
      const Friend(
        name: 'D1yah',
        status: 'Away - Riot Mobile',
        isOnline: true,
        avatarUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=300&q=80',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SizedBox(height: 10),
              const Text(
                'Social',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(tabs.length, (index) {
                  final selected = index == 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 3,
                            width: selected ? 80 : 0,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFE4D4D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2D30),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Color(0xFFBEC3CA),
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Search',
                      style: TextStyle(
                        color: Color(0xFFBEC3CA),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4D5A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'VALORANT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '3',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...friends.map(
                (friend) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: FriendRow(friend: friend),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 18),
                child: Text(
                  'Online 4',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              ...onlineFriends.map(
                (friend) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: FriendRow(friend: friend),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Friend {
  const Friend({
    required this.name,
    required this.status,
    required this.isOnline,
    required this.avatarUrl,
  });

  final String name;
  final String status;
  final bool isOnline;
  final String avatarUrl;
}

class FriendRow extends StatelessWidget {
  const FriendRow({super.key, required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(friend.avatarUrl),
            ),
            if (friend.isOnline)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3BE27B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F1114),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (friend.status.contains('Online'))
                    const Icon(
                      Icons.circle,
                      size: 9,
                      color: Color(0xFF3BE27B),
                    )
                  else
                    const Icon(
                      Icons.not_interested_rounded,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    friend.status,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
