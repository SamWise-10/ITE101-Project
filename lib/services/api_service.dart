import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cloud data access via Supabase (Postgres tables), plus a Dio client used
/// only to download book PDFs from their public URLs.
///
/// Read methods (`getBooks`, `getQuizzes`) intentionally let network errors
/// propagate so callers can fall back to their local SQLite cache when offline.
/// Write methods swallow errors and report success/failure via their return.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Dio _dio = Dio();

  factory ApiService() => _instance;

  ApiService._internal();

  SupabaseClient get _sb => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getBooks() async {
    final data = await _sb.from('books').select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getQuizzes() async {
    final data = await _sb.from('quizzes').select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final data = await _sb.from('courses').select();
    return List<Map<String, dynamic>>.from(data);
  }

  /// Downloads a book PDF and returns the local file path, or null on failure.
  Future<String?> downloadBook(String bookId, String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(p.join(dir.path, 'books'));
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }
      final savePath = p.join(booksDir.path, '$bookId.pdf');
      final response = await _dio.download(url, savePath);
      if (response.statusCode == 200) return savePath;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> addBook(Map<String, dynamic> data) async {
    try {
      final res = await _sb.from('books').insert(data).select().single();
      return Map<String, dynamic>.from(res);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      await _sb.from('books').delete().eq('book_id', bookId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> addQuiz(Map<String, dynamic> data) async {
    try {
      final res = await _sb.from('quizzes').insert(data).select().single();
      return Map<String, dynamic>.from(res);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _sb.from('quizzes').delete().eq('quiz_id', quizId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitQuizResults(Map<String, dynamic> data) async {
    try {
      await _sb.from('quiz_results').insert(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// All submitted quiz results (teacher "monitor students" view).
  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final data = await _sb.from('quiz_results').select();
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }
}
