import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().fetchBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Books'),
            Tab(text: 'Downloaded'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllBooksTab(),
                _buildDownloadedBooksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllBooksTab() {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, _) {
        if (bookProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = _searchController.text.isEmpty
            ? bookProvider.books
            : bookProvider.searchBooks(_searchController.text);

        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty ? 'No books available' : 'No results found',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey[300],
                      child: book['book_picture'] != null
                          ? Image.network(
                              book['book_picture'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.book, color: Colors.grey[600]),
                            )
                          : Icon(Icons.book, color: Colors.grey[600]),
                    ),
                  ),
                  title: Text(
                    book['book_name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    'Tap to download',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    Icons.download_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  onTap: () {
                    _showDownloadDialog(context, book);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDownloadedBooksTab() {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          bookProvider.loadDownloadedBooks();
        });

        if (bookProvider.downloadedBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_done,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No downloaded books yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: bookProvider.downloadedBooks.length,
          itemBuilder: (context, index) {
            final book = bookProvider.downloadedBooks[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf,
                    size: 40,
                    color: Colors.red,
                  ),
                  title: Text(
                    book['name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    'Downloaded',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    Icons.open_in_new,
                    color: Theme.of(context).primaryColor,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening file...')),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context, Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book['book_name'] ?? 'Download Book'),
        content: const Text('Download this book for offline reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BookProvider>().downloadBook(
                    book['book_id'] ?? '',
                    book['link'] ?? '',
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download started...')),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
