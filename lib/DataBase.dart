import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  // Construtor privado
  DB._();

  // Instância de DB
  static final DB instance = DB._();

  // Instância do SQLite
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Inicia o banco de dados se ainda não estiver aberto
    return await _initDatabase();
  }

  // Inicializa o banco de dados
  _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'cripto.db'),  // Caminho para o banco de dados
      version: 1,
      onCreate: _onCreate,  // Função chamada para criar o banco na primeira execução
    );
  }

  _onCreate(Database db, int versao) async {
    await db.execute(_users);  // Criação da tabela de usuários
    await db.execute(_tags);   // Criação da tabela de tags
    await db.execute(_tasks);  // Criação da tabela de tarefas

    // Inserir a tag padrão "None" com cor branca
    await db.insert('tags', {
      'name': 'None',  // Nome da tag
      'color': '16777215', // Cor da tag em hexadecimal int
    });

    // Inserir um usuário de teste (remover em produção)
    await db.insert('users', {
      'username': 'teste',
      'email': 'teste@teste.com',
      'password': 'teste123',
    });
  }

  // SQL para criação da tabela de usuários
  String get _users => '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT, -- Identificador único do usuário
      username TEXT NOT NULL,               -- Nome de usuário
      email TEXT UNIQUE NOT NULL,           -- Email único
      password TEXT NOT NULL,               -- Senha
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Data de criação
    );
  ''';

  // SQL para criação da tabela de tags
  String get _tags => '''
    CREATE TABLE tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT, -- Identificador único da tag
      name TEXT NOT NULL,                   -- Nome da tag
      color INT NOT NULL                   -- Cor da tag
    );
  ''';

  // SQL para criação da tabela de tarefas
  String get _tasks => '''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Identificador único da tarefa
      user_id INTEGER NOT NULL,              -- ID do usuário associado
      name TEXT NOT NULL CHECK(length(name) <= 25), -- Nome da tarefa (máximo de 25 caracteres)
      description TEXT,                      -- Descrição da tarefa
      complete BOOLEAN DEFAULT 0,            -- Status de conclusão (0 = não, 1 = sim)
      reminder BOOLEAN DEFAULT 0,            -- Lembrete ativado (0 = não, 1 = sim)
      reminder_datetime TIMESTAMP,           -- Data e hora do lembrete
      tag_id INTEGER,                        -- ID da tag associada
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Data de criação
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE, -- Chave estrangeira para 'users'
      FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE SET NULL   -- Chave estrangeira para 'tags'
    );
  ''';


  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    final db = await instance.database;

    // Obtenha a tarefa existente no banco de dados
    final existingTask = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingTask.isEmpty) {
      throw Exception('Tarefa não encontrada');
    }

    final currentTask = existingTask.first;

    // Mantém os valores existentes para campos opcionais se não forem fornecidos
    task['tag_id'] = task.containsKey('tag_id') ? task['tag_id'] : currentTask['tag_id'];
    task['reminder_datetime'] = task.containsKey('reminder_datetime')
        ? task['reminder_datetime']
        : currentTask['reminder_datetime'];

    // Remove campos que não pertencem à tabela (como `tag_color`)
    task.remove('tag_color');

    // Atualiza a tarefa no banco de dados
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTasksByUser(int userId) async {
    final db = await instance.database;

    // Consulta com JOIN para incluir informações da tag
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT 
      tasks.*,
      tags.name AS tag_name,
      tags.color AS tag_color
    FROM tasks
    LEFT JOIN tags ON tasks.tag_id = tags.id
    WHERE tasks.user_id = ?
  ''', [userId]);

    return result;
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await instance.database;

    // Verificar se a tag_id foi fornecida, se não, usar o ID da tag "None"
    if (task['tag_id'] == null) {
      final List<Map<String, dynamic>> tags = await db.query('tags', where: 'name = ?', whereArgs: ['None']);
      if (tags.isNotEmpty) {
        task['tag_id'] = tags.first['id'];  // Atribui o ID da tag "None"
      }
    }

    // Excluindo a chave 'tag_color' caso esteja presente no mapa de dados
    task.remove('tag_color');

    return await db.insert('tasks', task);
  }

  // Função para inserir uma tag no banco de dados
  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await instance.database;
    return await db.insert('tags', tag);
  }

  // Função para pegar todas as tags
  Future<List<Map<String, dynamic>>> getTags() async {
    final db = await instance.database;
    return await db.query('tags');  // Retorna todas as tags na tabela 'tags'
  }

  // Função para atualizar o status de conclusão de uma tarefa
  Future<int> updateTaskStatus(int id, Map<String, dynamic> task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
  final db = await instance.database;
  return await db.query('tasks');
  }

}
