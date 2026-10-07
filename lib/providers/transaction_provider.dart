// lib/providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/my_transaction.dart';

class TransactionProvider with ChangeNotifier {
  static const String _dbName = 'expenses.db';
  static const String _tableName = 'transactions';

  Database? _database;
  List<MyTransaction> _transactions = [];
  double _balance = 0;
  double get balance => _balance;

  TransactionProvider() {
    fetchAndSetTransactions(); // โหลดข้อมูลเมื่อ Provider ถูกสร้าง
  }

  List<MyTransaction> get transactions => [..._transactions];

  // กระบวนการที่ 2: การสร้างฐานข้อมูล
  Future<void> _initDatabase() async {
    if (_database != null) return;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          print('Creating table $_tableName...');
          return db.execute(
            'CREATE TABLE $_tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, type TEXT)',
          );
        },
      );
      print('Database initialized at $path');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  // กระบวนการที่ 3: การ Insert
  Future<void> addTransaction(
    String title,
    double amount,
    DateTime date,
    TransactionType type,
  ) async {
    await _initDatabase(); // ตรวจสอบว่า DB พร้อมใช้งาน
    if (_database == null) return;

    final newTransaction = MyTransaction(
      title: title,
      amount: amount,
      date: date,
      type: type,
    );

    final id = await _database!.insert(_tableName, newTransaction.toMap());
    print('Inserted transaction with id: $id');

    await fetchAndSetTransactions(); // เปิดบรรทัดนี้ในกระบวนการที่ 4
  }

  // กระบวนการที่ 4: การ Read
  Future<void> fetchAndSetTransactions() async {
    await _initDatabase();
    if (_database == null) return;

    final dataList = await _database!.query(_tableName, orderBy: 'date DESC');
    _transactions = dataList
        .map((item) => MyTransaction.fromMap(item))
        .toList();
    final result = await _database!.rawQuery(
      "SELECT SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) AS balance "
      'FROM $_tableName',
    );
    _balance = (result.first['balance'] as num?)?.toDouble() ?? 0;
    print('Fetched ${_transactions.length} transactions.');
    notifyListeners(); // แจ้ง UI ให้วาดใหม่
  }

  // กระบวนการที่ 5: การ Update
  Future<void> updateTransaction(int id, MyTransaction newTransaction) async {
    await _initDatabase();
    if (_database == null) return;

    await _database!.update(
      _tableName,
      newTransaction
          .toMap(), // toMap() ไม่ส่ง id ที่เป็น null จึงไม่ไปเปลี่ยนคีย์หลัก
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchAndSetTransactions();
  }

  // กระบวนการที่ 6: การ Delete
  Future<void> deleteTransaction(int id) async {
    await _initDatabase();
    if (_database == null) return;

    await _database!.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    await fetchAndSetTransactions();
  }

  // สร้างรายการตัวอย่าง 100 รายการ
  List<MyTransaction> _buildSamples() {
    final now = DateTime.now();
    return List.generate(100, (i) {
      return MyTransaction(
        title: 'ตัวอย่าง ${i + 1}',
        amount: 10.0 + i,
        date: now.add(Duration(seconds: i)),
        type: i.isEven ? TransactionType.income : TransactionType.expense,
      );
    });
  }

  // แบบ insert ทีละรายการ
  Future<int> importOneByOne() async {
    await _initDatabase();
    if (_database == null) return 0;

    final stopwatch = Stopwatch()..start();
    for (final tx in _buildSamples()) {
      await _database!.insert(_tableName, tx.toMap());
    }
    stopwatch.stop();

    await fetchAndSetTransactions();
    return stopwatch.elapsedMilliseconds;
  }

  // batch ภายใน transaction
  Future<int> importWithBatch() async {
    await _initDatabase();
    if (_database == null) return 0;

    final stopwatch = Stopwatch()..start();
    await _database!.transaction((txn) async {
      final batch = txn.batch();
      for (final tx in _buildSamples()) {
        batch.insert(_tableName, tx.toMap());
      }
      await batch.commit(noResult: true);
    });
    stopwatch.stop();

    await fetchAndSetTransactions();
    return stopwatch.elapsedMilliseconds;
  }
}
