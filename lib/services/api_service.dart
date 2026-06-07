import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    try {
      final response = await _dio.get(AppConfig.booksEndpoint);
      if (response.statusCode == 200) {
        final data = response.data as List;
        if (data.isNotEmpty) {
          final books = (data[0]['data'] as List).cast<Map<String, dynamic>>();
          return books;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching books: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getQuizzes() async {
    try {
      final response = await _dio.get(AppConfig.quizzesEndpoint);
      if (response.statusCode == 200) {
        final data = response.data as List;
        if (data.isNotEmpty) {
          final quizzes = (data[0]['data'] as List).cast<Map<String, dynamic>>();
          return quizzes;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching quizzes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final response = await _dio.get(AppConfig.coursesEndpoint);
      if (response.statusCode == 200) {
        final data = response.data as List;
        if (data.isNotEmpty) {
          final courses = (data[0]['data'] as List).cast<Map<String, dynamic>>();
          return courses;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  Future<bool> downloadBook(String url) async {
    try {
      final response = await _dio.download(url, './downloaded_book.pdf');
      return response.statusCode == 200;
    } catch (e) {
      print('Error downloading book: $e');
      return false;
    }
  }
}
