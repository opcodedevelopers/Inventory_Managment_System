import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal() {
    // Initialize database factory for Windows
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'inventory.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      ),
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print("Upgrading database from version $oldVersion to $newVersion");

    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE sales ADD COLUMN buying_price REAL DEFAULT 0',
        );
        await db.execute('ALTER TABLE sales ADD COLUMN profit REAL DEFAULT 0');
        await db.execute('ALTER TABLE sales ADD COLUMN customer_address TEXT');
        print(
          "Added buying_price, profit, customer_address columns to sales table",
        );
        try {
          await db.execute(
            'ALTER TABLE products ADD COLUMN min_stock_level INTEGER DEFAULT 5',
          );
          await db.execute(
            'ALTER TABLE products ADD COLUMN max_stock_level INTEGER DEFAULT 100',
          );
          print(
            "Added min_stock_level and max_stock_level columns to products table",
          );
        } catch (e) {
          print("Columns may already exist in products table: $e");
        }
      } catch (e) {
        print("Error during database upgrade: $e");
        // If alter fails, create new table and copy data
        await _recreateSalesTable(db);
      }
    }
  }

  // For TABLE RECREATION
  Future<void> _recreateSalesTable(Database db) async {
    print("Recreating sales table with new structure...");

    // Create temporary table with new structure
    await db.execute('''
      CREATE TABLE sales_new(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        product_name TEXT,
        quantity INTEGER,
        unit_price REAL,
        buying_price REAL DEFAULT 0,
        total_amount REAL,
        profit REAL DEFAULT 0,
        sale_date TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Copy data from old table to new table
    await db.execute('''
      INSERT INTO sales_new (
        id, product_id, product_name, quantity, unit_price, total_amount, 
        sale_date, customer_name, customer_phone
      )
      SELECT 
        id, product_id, product_name, quantity, unit_price, total_amount,
        sale_date, customer_name, customer_phone
      FROM sales
    ''');

    // Drop old table
    await db.execute('DROP TABLE sales');

    // Rename new table to sales
    await db.execute('ALTER TABLE sales_new RENAME TO sales');

    print("Sales table recreated successfully with new columns");
  }

  Future<void> _createTables(Database db, int version) async {
    // Products Table with Stock Alerts
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        barcode TEXT,
        current_quantity INTEGER DEFAULT 0,
        min_stock_level INTEGER DEFAULT 5,
        max_stock_level INTEGER DEFAULT 100,
        buying_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Sales Table - COMPLETE WITH ALL COLUMNS
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        product_name TEXT,
        quantity INTEGER,
        unit_price REAL,
        buying_price REAL DEFAULT 0,
        total_amount REAL,
        profit REAL DEFAULT 0,
        sale_date TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Investments Table
    await db.execute('''
      CREATE TABLE investments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        product_id INTEGER,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Stock History Table
    await db.execute('''
      CREATE TABLE stock_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        old_quantity INTEGER,
        new_quantity INTEGER,
        change_type TEXT,
        change_date TEXT,
        notes TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    print("All tables created successfully (Version: $version)");
  }
}
