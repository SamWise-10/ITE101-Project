import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// How the book lists are ordered.
enum BookSort {
  titleAsc('Title (A–Z)', Icons.sort_by_alpha_rounded),
  titleDesc('Title (Z–A)', Icons.sort_by_alpha_rounded),
  course('Course', Icons.category_rounded);

  const BookSort(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Sorts a copy of [books] by [sort]. [nameKey] is the map key holding the
/// book title ('book_name' for the API list, 'name' for downloaded rows).
List<Map<String, dynamic>> sortBooks(
  List<Map<String, dynamic>> books,
  BookSort sort,
  String nameKey,
) {
  final list = List<Map<String, dynamic>>.from(books);
  String title(Map<String, dynamic> b) =>
      (b[nameKey] as String? ?? '').toLowerCase();
  String course(Map<String, dynamic> b) => (b['course_id'] as String? ?? '');
  switch (sort) {
    case BookSort.titleAsc:
      list.sort((a, b) => title(a).compareTo(title(b)));
    case BookSort.titleDesc:
      list.sort((a, b) => title(b).compareTo(title(a)));
    case BookSort.course:
      list.sort((a, b) {
        final c = course(a).compareTo(course(b));
        return c != 0 ? c : title(a).compareTo(title(b));
      });
  }
  return list;
}

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchCtrl;
  String? _selectedCourseId;
  BookSort _sort = BookSort.titleAsc;

  static const _courseMap = {
    'course-001': 'Computer Fundamentals',
    'course-002': 'Basic Mathematics',
    'course-003': 'Science and Technology',
    'course-004': 'English Communication',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().fetchBooks();
      context.read<BookProvider>().loadDownloadedBooks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isTeacher =>
      context.read<AuthProvider>().currentUser?['role'] == 'Teacher';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [_buildSortButton(cs)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Books'),
            Tab(text: 'Downloaded'),
          ],
        ),
      ),
      floatingActionButton: _isTeacher
          ? GradientFab(
              icon: Icons.add_rounded,
              label: 'Add Book',
              onPressed: () => _showAddBookDialog(context),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              children: [
                _CourseChip(
                  label: 'All',
                  selected: _selectedCourseId == null,
                  cs: cs,
                  onTap: () => setState(() => _selectedCourseId = null),
                ),
                for (final entry in _courseMap.entries) ...[
                  const SizedBox(width: 8),
                  _CourseChip(
                    label: entry.value,
                    selected: _selectedCourseId == entry.key,
                    cs: cs,
                    onTap: () => setState(() => _selectedCourseId =
                        _selectedCourseId == entry.key ? null : entry.key),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllBooksTab(
                  searchQuery: _searchCtrl.text,
                  isTeacher: _isTeacher,
                  selectedCourseId: _selectedCourseId,
                  sort: _sort,
                ),
                _DownloadedTab(
                  selectedCourseId: _selectedCourseId,
                  sort: _sort,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(ColorScheme cs) {
    return PopupMenuButton<BookSort>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort books',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (s) => setState(() => _sort = s),
      itemBuilder: (ctx) => [
        for (final s in BookSort.values)
          PopupMenuItem<BookSort>(
            value: s,
            child: Row(
              children: [
                Icon(s.icon,
                    size: 18,
                    color: _sort == s ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  s.label,
                  style: TextStyle(
                    fontWeight:
                        _sort == s ? FontWeight.w700 : FontWeight.w500,
                    color: _sort == s ? cs.primary : cs.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                if (_sort == s)
                  Icon(Icons.check_rounded, size: 18, color: cs.primary),
              ],
            ),
          ),
      ],
    );
  }

  void _showAddBookDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final pictureCtrl = TextEditingController();
    String dialogCourse = 'course-001';
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Book'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Book Title *',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'PDF URL *',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pictureCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Cover Image URL (optional)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Course Category *',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dialogCourse,
                      isDense: true,
                      isExpanded: true,
                      items: _courseMap.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => dialogCourse = v);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Title and URL are required'),
                      backgroundColor: cs.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final ok = await context.read<BookProvider>().addBook({
                  'book_name': title,
                  'link': url,
                  'book_picture': pictureCtrl.text.trim(),
                  'course_id': dialogCourse,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(ok ? 'Book added!' : 'Failed to add book'),
                      backgroundColor: ok ? cs.primary : cs.error,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Course Chip
// ──────────────────────────────────────────────

class _CourseChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _CourseChip({
    required this.label,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? decor.brand : null,
          color: selected ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : cs.outlineVariant,
          ),
          boxShadow: selected ? decor.glow(0.28) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// All Books Tab
// ──────────────────────────────────────────────

class _AllBooksTab extends StatelessWidget {
  final String searchQuery;
  final bool isTeacher;
  final String? selectedCourseId;
  final BookSort sort;

  static const _courseMap = {
    'course-001': 'Computer Fundamentals',
    'course-002': 'Basic Mathematics',
    'course-003': 'Science and Technology',
    'course-004': 'English Communication',
  };

  const _AllBooksTab({
    required this.searchQuery,
    required this.isTeacher,
    required this.selectedCourseId,
    required this.sort,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var books = searchQuery.isEmpty
            ? provider.books
            : provider.searchBooks(searchQuery);

        if (selectedCourseId != null) {
          books = books
              .where((b) => (b['course_id'] ?? '') == selectedCourseId)
              .toList();
        }

        books = sortBooks(books, sort, 'book_name');

        if (books.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<BookProvider>().fetchBooks(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 400,
                  child: _EmptyState(
                    icon: Icons.menu_book_rounded,
                    message: selectedCourseId != null
                        ? 'No books in\n${_courseMap[selectedCourseId] ?? 'this course'}'
                        : searchQuery.isEmpty
                            ? 'No books available'
                            : 'No results for "$searchQuery"',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<BookProvider>().fetchBooks(),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final bookId = book['book_id'] as String? ?? '';
              final isDownloaded =
                  provider.downloadedBooks.any((d) => d['id'] == bookId);
              final isDownloading = provider.isDownloading(bookId);
              final hasFailed = provider.hasFailed(bookId);

              return _BookCard(
                book: book,
                isDownloaded: isDownloaded,
                isDownloading: isDownloading,
                hasFailed: hasFailed,
                isTeacher: isTeacher,
                courseLabel: _courseMap[book['course_id'] as String? ?? ''],
                onTap: isDownloading
                    ? () {}
                    : () => _showDownloadDialog(context, book),
                onDelete: isTeacher
                    ? () => _confirmDelete(context, book, provider)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showDownloadDialog(
      BuildContext context, Map<String, dynamic> book) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(book['book_name'] ?? 'Download Book'),
        content: const Text('Download this book for offline reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final bookProvider = context.read<BookProvider>();
              Navigator.pop(ctx);
              final ok = await bookProvider.downloadBook(
                book['book_id'] ?? '',
                book['link'] ?? '',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Downloaded successfully!'
                        : 'Download failed. Please try again.'),
                    backgroundColor: ok ? cs.primary : cs.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Map<String, dynamic> book,
    BookProvider provider,
  ) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Book'),
        content:
            Text('Delete "${book['book_name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteBook(book['book_id'] ?? '');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Book deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Book Card
// ──────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final bool isDownloaded;
  final bool isDownloading;
  final bool hasFailed;
  final bool isTeacher;
  final String? courseLabel;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _BookCard({
    required this.book,
    required this.isDownloaded,
    required this.isDownloading,
    required this.hasFailed,
    required this.isTeacher,
    required this.onTap,
    this.courseLabel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverUrl = book['book_picture'] as String?;

    final decor = AppDecoration.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: isTeacher ? () => onDelete?.call() : null,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: decor.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null && coverUrl.isNotEmpty)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _BookPlaceholder(cs: cs),
                    )
                  else
                    _BookPlaceholder(cs: cs),
                  if (isDownloading)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    )
                  else if (hasFailed)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.error_rounded,
                            size: 14, color: cs.onError),
                      ),
                    )
                  else if (isDownloaded)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.download_done_rounded,
                            size: 14, color: cs.onPrimary),
                      ),
                    ),
                  if (isTeacher)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.touch_app_rounded,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  if (isDownloading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['book_name'] ?? 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        height: 1.3,
                      ),
                    ),
                    if (courseLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        courseLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isDownloading)
                      Row(children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary),
                        ),
                        const SizedBox(width: 5),
                        Text('Downloading...',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w500)),
                      ])
                    else if (hasFailed)
                      Row(children: [
                        Icon(Icons.error_rounded,
                            size: 13, color: cs.error),
                        const SizedBox(width: 4),
                        Text('Failed · Retry',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.error,
                                fontWeight: FontWeight.w500)),
                      ])
                    else if (isDownloaded)
                      Row(children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: cs.primary),
                        const SizedBox(width: 4),
                        Text('Ready',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w500)),
                      ])
                    else
                      Row(children: [
                        Icon(Icons.download_outlined,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Download',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500)),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookPlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _BookPlaceholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: decor.hero),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 46, color: Colors.white),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Downloaded Tab
// ──────────────────────────────────────────────

class _DownloadedTab extends StatelessWidget {
  final String? selectedCourseId;
  final BookSort sort;

  static const _courseMap = {
    'course-001': 'Computer Fundamentals',
    'course-002': 'Basic Mathematics',
    'course-003': 'Science and Technology',
    'course-004': 'English Communication',
  };

  const _DownloadedTab({required this.selectedCourseId, required this.sort});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        var books = provider.downloadedBooks;
        if (selectedCourseId != null) {
          books = books
              .where((b) => (b['course_id'] ?? '') == selectedCourseId)
              .toList();
        }

        books = sortBooks(books, sort, 'name');

        if (books.isEmpty) {
          return RefreshIndicator(
            onRefresh: () =>
                context.read<BookProvider>().loadDownloadedBooks(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 400,
                  child: _EmptyState(
                    icon: Icons.download_done_rounded,
                    message: selectedCourseId != null
                        ? 'No downloaded books in\n${_courseMap[selectedCourseId] ?? 'this course'}'
                        : 'No downloaded books yet.\nTap a book to download it.',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              context.read<BookProvider>().loadDownloadedBooks(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final courseLabel =
                  _courseMap[book['course_id'] as String? ?? ''];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: AppDecoration.of(context).softShadow,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E7E), Color(0xFFE11D48)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white, size: 24),
                  ),
                  title: Text(
                    book['name'] ?? 'Unknown',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (courseLabel != null)
                        Text(
                          courseLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      Text(
                        book['downloaded_at']
                                ?.toString()
                                .split('T')[0] ??
                            'Downloaded',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.open_in_new_rounded,
                      color: cs.primary, size: 20),
                  onTap: () async {
                    final path = book['downloaded_path'] as String?;
                    if (path == null || path.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'File path not found. Try re-downloading.')),
                      );
                      return;
                    }
                    final result = await OpenFilex.open(path);
                    if (result.type != ResultType.done &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Cannot open file: ${result.message}')),
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Shared
// ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: decor.brand,
              borderRadius: BorderRadius.circular(24),
              boxShadow: decor.glow(0.3),
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            message,
            style: TextStyle(
                fontSize: 14, color: cs.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
