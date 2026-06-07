import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class BookProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _downloadedBooks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get books => _books;
  List<Map<String, dynamic>> get downloadedBooks => _downloadedBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedBooks = await _apiService.getBooks();
      final db = await _dbService.database;

      for (var book in fetchedBooks) {
        await db.insert(
          'books',
          {
            'id': book['book_id'] ?? '',
            'name': book['book_name'] ?? '',
            'link': book['link'] ?? '',
            'picture_url': book['book_picture'] ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      _books = fetchedBooks;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching books: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDownloadedBooks() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'books',
        where: 'is_downloaded = ?',
        whereArgs: [1],
      );
      _downloadedBooks = result;
      notifyListeners();
    } catch (e) {
      print('Error loading downloaded books: $e');
    }
  }

  Future<bool> downloadBook(String bookId, String bookUrl) async {
    try {
      final success = await _apiService.downloadBook(bookUrl);
      if (success) {
        final db = await _dbService.database;
        await db.update(
          'books',
          {
            'is_downloaded': 1,
            'downloaded_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [bookId],
        );
        await loadDownloadedBooks();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error downloading book: $e';
      notifyListeners();
      return false;
    }
  }

  List<Map<String, dynamic>> searchBooks(String query) {
    if (query.isEmpty) {
      return _books;
    }
    return _books
        .where((book) =>
            (book['book_name'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (book['book_id'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
