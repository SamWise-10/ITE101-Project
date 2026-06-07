class AppConfig {
  static const String appName = 'TDLF-Educ';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost
  
  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String signupEndpoint = '/signup';
  static const String booksEndpoint = '/books';
  static const String quizzesEndpoint = '/quizzes';
  static const String coursesEndpoint = '/courses';
  static const String usersEndpoint = '/users';
  
  // User Roles
  static const List<String> userRoles = ['Student', 'Teacher', 'Guest'];
  static const String developerRole = 'Developer';
  
  // Quiz Settings
  static const double passingScore = 75.0;
  
  // Database
  static const String databaseName = 'tdlf_educ.db';
  static const int databaseVersion = 1;
}
