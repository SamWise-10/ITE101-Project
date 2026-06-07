import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navigationItems = [
    {'icon': Icons.home, 'label': 'Home', 'route': 'home'},
    {'icon': Icons.book, 'label': 'Books', 'route': 'books'},
    {'icon': Icons.quiz, 'label': 'Quizzes', 'route': 'quizzes'},
    {'icon': Icons.person, 'label': 'Profile', 'route': 'profile'},
    {'icon': Icons.settings, 'label': 'Settings', 'route': 'settings'},
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final route = _navigationItems[index]['route'];
    Navigator.of(context).pushNamed('/$route');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TDLF-Educ'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.currentUser;
                  return Text(
                    'Welcome, ${user?['username'] ?? 'User'}',
                    style: Theme.of(context).textTheme.displayMedium,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Continue your learning journey',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _buildDashboardCards(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navigationItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item['icon']),
                  label: item['label'],
                ))
            .toList(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    return Column(
      children: [
        _buildCard(
          context,
          icon: Icons.book_outlined,
          title: 'Download Books',
          description: 'Browse and download educational books',
          onTap: () => Navigator.of(context).pushNamed('/books'),
        ),
        const SizedBox(height: 16),
        _buildCard(
          context,
          icon: Icons.quiz_outlined,
          title: 'Take Quizzes',
          description: 'Test your knowledge with quizzes',
          onTap: () => Navigator.of(context).pushNamed('/quizzes'),
        ),
        const SizedBox(height: 16),
        _buildCard(
          context,
          icon: Icons.bar_chart_outlined,
          title: 'Your Progress',
          description: 'View your quiz history and scores',
          onTap: () => Navigator.of(context).pushNamed('/profile'),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
