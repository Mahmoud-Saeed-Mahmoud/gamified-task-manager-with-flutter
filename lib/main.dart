import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'services/database_helper.dart';
import 'services/gamification_service.dart';
import 'models/task.dart';
import 'models/user_progress.dart';
import 'widgets/add_task_dialog.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gamificationService = GamificationService();
  await gamificationService.init();
  runApp(MyApp(gamificationService: gamificationService));
}

class MyApp extends StatelessWidget {
  final GamificationService gamificationService;

  const MyApp({super.key, required this.gamificationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(
            databaseHelper: DatabaseHelper.instance,
            gamificationService: gamificationService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Gamified Tasks',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class TaskProvider with ChangeNotifier {
  final DatabaseHelper databaseHelper;
  final GamificationService gamificationService;
  List<Task> _tasks = [];
  UserProgress _userProgress = UserProgress();
  bool _isLoading = true;

  TaskProvider({
    required this.databaseHelper,
    required this.gamificationService,
  }) {
    _initializeData();
  }

  List<Task> get tasks => _tasks;
  UserProgress get userProgress => _userProgress;
  bool get isLoading => _isLoading;

  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.wait([
        _loadTasks(),
        _loadUserProgress(),
      ]);
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTasks() async {
    _tasks = await databaseHelper.getAllTasks();
  }

  Future<void> _loadUserProgress() async {
    _userProgress = await gamificationService.getUserProgress();
  }

  Future<void> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    
    await databaseHelper.createTask(task);
    await _loadTasks();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    
    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    await databaseHelper.updateTask(completedTask);
    _userProgress = await gamificationService.processTaskCompletion(completedTask);
    await _loadTasks();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    _isLoading = true;
    notifyListeners();
    
    await databaseHelper.deleteTask(id);
    await _loadTasks();
    
    _isLoading = false;
    notifyListeners();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamified Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first task to get started!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: taskProvider.tasks.length,
            itemBuilder: (context, index) {
              final task = taskProvider.tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description.isNotEmpty)
                        Text(task.description),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(task.dueDate),
                            style: TextStyle(
                              color: task.dueDate.isBefore(DateTime.now())
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ['Easy', 'Medium', 'Hard'][task.difficulty - 1],
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Checkbox(
                    value: task.isCompleted,
                    onChanged: (bool? value) {
                      if (value == true) {
                        taskProvider.completeTask(task);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final task = await showDialog<Task>(
            context: context,
            builder: (context) => const AddTaskDialog(),
          );
          if (task != null) {
            // ignore: use_build_context_synchronously
            Provider.of<TaskProvider>(context, listen: false).addTask(task);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
