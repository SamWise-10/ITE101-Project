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
  final Set<String> _downloadingIds = {};
  final Set<String> _failedIds = {};

  List<Map<String, dynamic>> get books => _books;
  List<Map<String, dynamic>> get downloadedBooks => _downloadedBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isDownloading(String id) => _downloadingIds.contains(id);
  bool hasFailed(String id) => _failedIds.contains(id);

  Future<void> fetchBooks() async {
    // Offline-first: show the local cache immediately…
    await _loadCachedBooks();
    _isLoading = _books.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      // …then refresh from the cloud and write through to the cache.
      final fetchedBooks = await _apiService.getBooks();
      final db = await _dbService.database;

      for (var book in fetchedBooks) {
        await db.rawInsert(
          '''INSERT INTO books (id, name, link, picture_url, course_id)
             VALUES (?, ?, ?, ?, ?)
             ON CONFLICT(id) DO UPDATE SET
               name = excluded.name,
               link = excluded.link,
               picture_url = excluded.picture_url,
               course_id = excluded.course_id''',
          [
            book['book_id'] ?? '',
            book['book_name'] ?? '',
            book['link'] ?? '',
            book['book_picture'] ?? '',
            book['course_id'] ?? '',
          ],
        );
      }

      _books = fetchedBooks;
      _errorMessage = null;
    } catch (e) {
      // Offline or fetch failed — keep the cached books we already loaded.
      if (_books.isEmpty) {
        _errorMessage = 'You are offline and have no cached books yet.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads books from the local SQLite cache and maps the columns back to the
  /// in-memory shape the UI expects (`book_id`, `book_name`, …).
  Future<void> _loadCachedBooks() async {
    try {
      final db = await _dbService.database;
      final rows = await db.query('books');
      _books = rows
          .map((r) => <String, dynamic>{
                'book_id': r['id'],
                'book_name': r['name'],
                'link': r['link'],
                'book_picture': r['picture_url'],
                'course_id': r['course_id'],
              })
          .toList();
    } catch (_) {
      // No cache yet.
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
    } catch (_) {}
  }

  Future<bool> downloadBook(String bookId, String bookUrl) async {
    _downloadingIds.add(bookId);
    _failedIds.remove(bookId);
    notifyListeners();
    try {
      final savedPath = await _apiService.downloadBook(bookId, bookUrl);
      _downloadingIds.remove(bookId);
      if (savedPath != null) {
        final db = await _dbService.database;
        await db.update(
          'books',
          {
            'is_downloaded': 1,
            'downloaded_path': savedPath,
            'downloaded_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [bookId],
        );
        await loadDownloadedBooks();
        return true;
      }
      _failedIds.add(bookId);
      notifyListeners();
      return false;
    } catch (e) {
      _downloadingIds.remove(bookId);
      _failedIds.add(bookId);
      _errorMessage = 'Error downloading book: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addBook(Map<String, dynamic> data) async {
    try {
      final book = await _apiService.addBook(data);
      if (book != null) {
        _books.add(book);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) { return false; }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      final success = await _apiService.deleteBook(bookId);
      if (success) {
        _books.removeWhere((b) => b['book_id'] == bookId);
        notifyListeners();
      }
      return success;
    } catch (_) { return false; }
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
