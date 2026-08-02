import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Screen Navigation Lab',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // Named routes for the screens that DON'T need to return data.
      // (HomeScreen and DetailScreen are reached this way.)
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/detail': (context) => const DetailScreen(),
      },
      // AddItemScreen is intentionally NOT a named route — see README
      // "Troubleshooting" section for why.
    );
  }
}

/// A simple data model passed between screens.
class TaskItem {
  final String title;
  final String note;

  TaskItem({required this.title, required this.note});
}

/// ---------------------------------------------------------------------
/// SCREEN 1: HomeScreen
/// - Root of the navigation stack.
/// - Displays a list of TaskItems.
/// - Tapping an item PUSHES DetailScreen and PASSES the item forward.
/// - The "+" button PUSHES AddItemScreen and AWAITS a result that is
///   POPPED back (data returned from a closed route).
/// ---------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<TaskItem> _items = [
    TaskItem(title: 'Read Chapter 6', note: 'Focus on Navigator & routes'),
    TaskItem(title: 'Build lab app', note: 'Three screens, pass data'),
    TaskItem(title: 'Test on emulator', note: 'Check forward & back nav'),
  ];

  Future<void> _openAddItemScreen() async {
    // Navigator.push + await: this screen waits here until AddItemScreen
    // calls Navigator.pop(context, someValue).
    final newItem = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );

    // If the user cancelled (pressed system/app-bar back button),
    // newItem will be null — handle that gracefully instead of crashing.
    if (newItem != null) {
      setState(() {
        _items.add(newItem);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${newItem.title}"')),
        );
      }
    }
  }

  void _openDetailScreen(TaskItem item) {
    // Pushing a NAMED route and passing data via `arguments`.
    Navigator.pushNamed(
      context,
      '/detail',
      arguments: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: _items.isEmpty
          ? const Center(child: Text('No tasks yet. Tap + to add one.'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(item.title),
                  subtitle: Text(item.note, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openDetailScreen(item),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItemScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// SCREEN 2: DetailScreen
/// - Reached via a named route ('/detail').
/// - Reads the TaskItem passed as route arguments.
/// - Back button (auto-added by AppBar) pops this screen off the stack,
///   returning to HomeScreen.
/// ---------------------------------------------------------------------
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Defensive check: if this screen is ever opened without arguments
    // (e.g. via deep link or hot-reload on this route), don't crash.
    final args = ModalRoute.of(context)?.settings.arguments;
    final TaskItem? item = args is TaskItem ? args : null;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Detail')),
        body: const Center(child: Text('No task data was provided.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(item.note, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              // Explicit, clearly labeled way back — in addition to the
              // AppBar back arrow — satisfying "clear way to navigate
              // backward" and "intuitive, clearly labeled actions".
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Task List'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// SCREEN 3: AddItemScreen
/// - Reached via Navigator.push (not a named route — see README).
/// - Collects a title + note, then POPS itself and RETURNS a TaskItem
///   to whoever pushed it (HomeScreen), demonstrating data flowing
///   back when a route is closed.
/// ---------------------------------------------------------------------
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newItem = TaskItem(
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
      );
      // Pop this screen AND send data back to HomeScreen in one call.
      Navigator.pop(context, newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Task')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // Cancel = pop with NO data. Home already handles
                      // the null case gracefully.
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Task'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
