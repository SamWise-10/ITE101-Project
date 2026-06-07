import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class QuizProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _quizHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {};
  double _quizScore = 0.0;
  bool _showResults = false;

  List<Map<String, dynamic>> get quizzes => _quizzes;
  List<Map<String, dynamic>> get quizHistory => _quizHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<String, String> get userAnswers => _userAnswers;
  double get quizScore => _quizScore;
  bool get showResults => _showResults;
  bool get isPassed => _quizScore >= AppConfig.passingScore;

  Future<void> fetchQuizzes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedQuizzes = await _apiService.getQuizzes();
      final db = await _dbService.database;

      for (var quiz in fetchedQuizzes) {
        await db.insert(
          'quizzes',
          {
            'id': quiz['quiz_id'] ?? const Uuid().v4(),
            'question': quiz['question'] ?? '',
            'quiz_type': quiz['quiz_type'] ?? '',
            'correct_answer': quiz['correct_answer'] ?? '',
            'reason': quiz['reason'] ?? '',
            'course_id': quiz['course_id'] ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      _quizzes = fetchedQuizzes;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching quizzes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuizHistory(String userId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'quiz_attempts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'attempted_at DESC',
      );
      _quizHistory = result;
      notifyListeners();
    } catch (e) {
      print('Error loading quiz history: $e');
    }
  }

  void resetQuiz() {
    _currentQuestionIndex = 0;
    _userAnswers = {};
    _quizScore = 0.0;
    _showResults = false;
    notifyListeners();
  }

  void answerQuestion(String quizId, String answer) {
    _userAnswers[quizId] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _quizzes.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<void> submitQuiz(String userId, String courseId) async {
    try {
      int correctAnswers = 0;
      final db = await _dbService.database;

      for (var quiz in _quizzes) {
        final quizId = quiz['quiz_id'] ?? quiz['id'];
        final userAnswer = _userAnswers[quizId] ?? '';
        final isCorrect = userAnswer == (quiz['correct_answer'] ?? '');

        if (isCorrect) {
          correctAnswers++;
        }

        await db.insert('quiz_attempts', {
          'id': const Uuid().v4(),
          'quiz_id': quizId,
          'user_id': userId,
          'user_answer': userAnswer,
          'is_correct': isCorrect ? 1 : 0,
          'attempted_at': DateTime.now().toIso8601String(),
        });
      }

      _quizScore = (correctAnswers / _quizzes.length) * 100;
      _showResults = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error submitting quiz: $e';
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getQuizzesByCourse(String courseId) {
    return _quizzes
        .where((quiz) => (quiz['course_id'] ?? '') == courseId)
        .toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
