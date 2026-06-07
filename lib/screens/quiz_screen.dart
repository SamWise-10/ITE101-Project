import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchQuizzes();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<QuizProvider>().loadQuizHistory(authProvider.currentUser!['id']);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableQuizzesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableQuizzesTab() {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        if (quizProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (quizProvider.quizzes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No quizzes available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: quizProvider.quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizProvider.quizzes[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    Icons.quiz_outlined,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    quiz['question'] ?? 'Quiz Question',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    '${quiz['quiz_type'] ?? 'N/A'} - Course ID: ${(quiz['course_id'] ?? 'N/A').toString().substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  onTap: () {
                    _showQuizPreview(context, quiz);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        if (quizProvider.quizHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No quiz attempts yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: quizProvider.quizHistory.length,
          itemBuilder: (context, index) {
            final attempt = quizProvider.quizHistory[index];
            final isCorrect = attempt['is_correct'] == 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    isCorrect ? 'Correct' : 'Incorrect',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    'Your answer: ${attempt['user_answer'] ?? 'Not answered'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Text(
                    attempt['attempted_at']?.toString().split('T')[0] ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuizPreview(BuildContext context, Map<String, dynamic> quiz) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz Question',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                quiz['question'] ?? 'No question',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Type: ${quiz['quiz_type'] ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Correct Answer: ${quiz['correct_answer'] ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (quiz['reason'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Reason: ${quiz['reason']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startQuiz(context);
                },
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text('Start Quiz')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context) {
    // Navigate to quiz taking screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuizTakingScreen(),
      ),
    );
  }
}

class QuizTakingScreen extends StatefulWidget {
  const QuizTakingScreen({Key? key}) : super(key: key);

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  late TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text('Your progress will not be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Taking Quiz'),
        ),
        body: Consumer<QuizProvider>(
          builder: (context, quizProvider, _) {
            if (quizProvider.showResults) {
              return _buildResultsScreen(context, quizProvider);
            }

            if (quizProvider.quizzes.isEmpty) {
              return const Center(child: Text('No quizzes available'));
            }

            final quiz = quizProvider.quizzes[quizProvider.currentQuestionIndex];
            return _buildQuizQuestion(context, quizProvider, quiz);
          },
        ),
      ),
    );
  }

  Widget _buildQuizQuestion(BuildContext context, QuizProvider quizProvider, Map<String, dynamic> quiz) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (quizProvider.currentQuestionIndex + 1) / quizProvider.quizzes.length,
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${quizProvider.currentQuestionIndex + 1} of ${quizProvider.quizzes.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(
            quiz['question'] ?? 'No question',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              hintText: 'Enter your answer',
            ),
            onChanged: (value) {
              quizProvider.answerQuestion(
                quiz['quiz_id'] ?? quiz['id'] ?? '',
                value,
              );
            },
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: quizProvider.currentQuestionIndex > 0
                    ? () {
                        _answerController.clear();
                        quizProvider.previousQuestion();
                      }
                    : null,
                child: const Text('Previous'),
              ),
              if (quizProvider.currentQuestionIndex == quizProvider.quizzes.length - 1)
                ElevatedButton(
                  onPressed: () {
                    final authProvider = context.read<AuthProvider>();
                    quizProvider.submitQuiz(
                      authProvider.currentUser!['id'],
                      '',
                    );
                  },
                  child: const Text('Submit'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    _answerController.clear();
                    quizProvider.nextQuestion();
                  },
                  child: const Text('Next'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen(BuildContext context, QuizProvider quizProvider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: quizProvider.isPassed ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${quizProvider.quizScore.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            quizProvider.isPassed ? 'Passed!' : 'Failed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: quizProvider.isPassed ? Colors.green : Colors.red,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Passing score: 75%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              quizProvider.resetQuiz();
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
