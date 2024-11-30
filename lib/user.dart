import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class User {
  final int? id;
  final String username;
  final String email;
  final String password;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
  });

  // Converte o objeto para um mapa para inserir no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
    };
  }

  // Cria um objeto User a partir de um mapa
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}

class Task {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final bool complete;
  final bool reminder;
  final String? reminderDatetime;

  Task({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.complete = false,
    this.reminder = false,
    this.reminderDatetime,
  });

  // Converte o objeto Task para um mapa para inserir no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'complete': complete ? 1 : 0,
      'reminder': reminder ? 1 : 0,
      'reminder_datetime': reminderDatetime,
    };
  }

  // Cria um objeto Task a partir de um mapa
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      complete: map['complete'] == 1,
      reminder: map['reminder'] == 1,
      reminderDatetime: map['reminder_datetime'] as String?,
    );
  }
}

class UserDatabase {
  static final UserDatabase instance = UserDatabase._init();
  static Database? _database;

  UserDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,  // Atualizei a versão do banco de dados
      onCreate: _createDB,
      onUpgrade: _onUpgrade,  // Adiciona a lógica de atualização do banco
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Criação da tabela de usuários
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // Criação da tabela de tarefas
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL CHECK(length(name) <= 25),
        description TEXT,
        complete BOOLEAN DEFAULT 0,
        reminder BOOLEAN DEFAULT 0,
        reminder_datetime TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');
  }

  // Função chamada quando a versão do banco é atualizada
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL CHECK(length(name) <= 25),
          description TEXT,
          complete BOOLEAN DEFAULT 0,
          reminder BOOLEAN DEFAULT 0,
          reminder_datetime TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );
      ''');
    }
  }

  // Insere um novo usuário no banco
  Future<void> insertUser(User user) async {
    final db = await instance.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Verifica se o usuário existe pelo e-mail e senha
  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Registra um novo usuário, verificando se o e-mail já está em uso
  Future<String> registerUser(User user) async {
    final db = await instance.database;

    // Verifica se o e-mail já está cadastrado
    final existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );

    if (existingUser.isNotEmpty) {
      return 'E-mail já cadastrado!';
    }

    try {
      // Insere o usuário no banco
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return 'Cadastro realizado com sucesso!';
    } catch (e) {
      return 'Erro ao cadastrar: $e';
    }
  }

  // Métodos de CRUD para tarefas

  // Cria uma nova tarefa
  Future<int> createTask(Task task) async {
    final db = await instance.database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obter todas as tarefas de um usuário
  Future<List<Task>> getTasksByUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.isNotEmpty
        ? result.map((task) => Task.fromMap(task)).toList()
        : [];
  }

  // Atualiza uma tarefa
  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Deleta uma tarefa
  Future<int> deleteTask(int taskId) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Fecha a conexão com o banco de dados
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
