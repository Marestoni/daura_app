import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'daura_app.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabela de campanhas (cache local)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS campaigns (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        objective TEXT,
        startDate TEXT,
        endDate TEXT,
        status TEXT,
        progress INTEGER,
        totalVisits INTEGER,
        completedVisits INTEGER,
        pendingVisits INTEGER,
        createdBy TEXT,
        data TEXT,
        updatedAt TEXT
      )
    ''');

    // 2. Tabela de visitas (cache local)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visits (
        id TEXT PRIMARY KEY,
        campaignId TEXT,
        visitorId TEXT,
        addressId TEXT,
        status TEXT,
        scheduledDate TEXT,
        completedDate TEXT,
        attempt TEXT,
        startedAt TEXT,
        completedAt TEXT,
        observation TEXT,
        attendedBy TEXT,
        situation TEXT,
        visitOrder INTEGER,
        isFinished INTEGER,
        data TEXT,
        updatedAt TEXT,
        FOREIGN KEY (campaignId) REFERENCES campaigns (id)
      )
    ''');

    // 3. Tabela de fotos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS photos (
        id TEXT PRIMARY KEY,
        visitId TEXT,
        filename TEXT,
        path TEXT,
        mimeType TEXT,
        size INTEGER,
        data BLOB,
        createdAt TEXT,
        FOREIGN KEY (visitId) REFERENCES visits (id)
      )
    ''');

    // 4. Tabela de pendências (sync queue)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT,
        entity TEXT,
        entityId TEXT,
        data TEXT,
        retryCount INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // Índices para melhor performance
    await db.execute('CREATE INDEX idx_visits_campaign ON visits(campaignId)');
    await db.execute('CREATE INDEX idx_visits_status ON visits(status)');
    await db.execute('CREATE INDEX idx_sync_status ON sync_queue(status)');

    print('✅ Banco de dados criado com sucesso!');
  }

  // ============================================
  // MÉTODOS GENÉRICOS
  // ============================================

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  // ============================================
  // ✅ MÉTODO UPSERT (INSERT OR UPDATE)
  // ============================================

  Future<void> upsert(
    String table,
    Map<String, dynamic> data, {
    String? conflictColumn,
  }) async {
    final db = await database;

    // Verificar se o registro já existe
    final column = conflictColumn ?? 'id';
    final id = data[column];

    if (id != null) {
      final existing = await db.query(
        table,
        where: '$column = ?',
        whereArgs: [id],
      );

      if (existing.isNotEmpty) {
        // ✅ Atualizar registro existente
        await db.update(table, data, where: '$column = ?', whereArgs: [id]);
      } else {
        // ✅ Inserir novo registro
        await db.insert(table, data);
      }
    } else {
      // Se não tiver ID, inserir normalmente
      await db.insert(table, data);
    }
  }

  // ============================================
  // MÉTODOS DE SINCRONIZAÇÃO
  // ============================================

  Future<void> addToSyncQueue({
    required String operation,
    required String entity,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'operation': operation,
      'entity': entity,
      'entityId': entityId,
      'data': jsonEncode(data),
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> markSyncProcessed(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'status': 'processed', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSyncError(int id, String error) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'status': 'error', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cleanProcessedSync() async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'status = ? OR status = ?',
      whereArgs: ['processed', 'error'],
    );
  }
}
