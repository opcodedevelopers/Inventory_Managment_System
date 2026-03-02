import 'package:sqflite/sqflite.dart';
import '../models/sale_model.dart';
import 'database_helper.dart';

class SaleRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Add sale
  Future<int> addSale(Sale sale) async {
    Database db = await dbHelper.database;
    return await db.insert('sales', sale.toMap());
  }

  // Get all sales
  Future<List<Sale>> getAllSales() async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      'sales',
      orderBy: 'sale_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  // Get sales by product
  Future<List<Sale>> getSalesByProduct(int productId) async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'sale_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  // Get total profit
  Future<double> getTotalProfit() async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(profit) as total FROM sales',
    );

    double profit = result.first['total']?.toDouble() ?? 0.0;
    print("Total Profit from Database: Rs $profit");
    return profit;
  }

  // Get product-wise profit
  Future<Map<String, double>> getProductWiseProfit() async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        product_name,
        SUM(profit) as total_profit,
        SUM(quantity) as total_quantity,
        SUM(total_amount) as total_sales
      FROM sales 
      GROUP BY product_id
      ORDER BY total_profit DESC
    ''');

    Map<String, double> productProfits = {};
    for (var row in result) {
      productProfits[row['product_name']] =
          row['total_profit']?.toDouble() ?? 0;
    }

    return productProfits;
  }

  // Get customer-wise sales
  Future<List<Map<String, dynamic>>> getCustomerWiseSales() async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        customer_name,
        COUNT(*) as total_purchases,
        SUM(total_amount) as total_spent,
        SUM(profit) as total_profit
      FROM sales 
      WHERE customer_name IS NOT NULL AND customer_name != ''
      GROUP BY customer_name
      ORDER BY total_spent DESC
    ''');

    return result;
  }

  // Get monthly sales
  Future<List<Sale>> getMonthlySales(int year, int month) async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM sales 
      WHERE strftime('%Y', sale_date) = ? 
      AND strftime('%m', sale_date) = ?
      ORDER BY sale_date DESC
    ''',
      [year.toString(), month.toString().padLeft(2, '0')],
    );

    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  // Get total sales amount
  Future<double> getTotalSales() async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM sales',
    );

    return result.first['total']?.toDouble() ?? 0.0;
  }

  // Get monthly total sales
  Future<double> getMonthlyTotalSales(int year, int month) async {
    Database db = await dbHelper.database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT SUM(total_amount) as total 
      FROM sales 
      WHERE strftime('%Y', sale_date) = ? 
      AND strftime('%m', sale_date) = ?
    ''',
      [year.toString(), month.toString().padLeft(2, '0')],
    );

    return result.first['total']?.toDouble() ?? 0.0;
  }

  // Get today's sales
  Future<List<Sale>> getTodaySales() async {
    Database db = await dbHelper.database;
    String today = DateTime.now().toIso8601String().split('T')[0];

    List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM sales 
      WHERE DATE(sale_date) = ?
      ORDER BY sale_date DESC
    ''',
      [today],
    );

    return List.generate(maps.length, (i) {
      return Sale.fromMap(maps[i]);
    });
  }

  // Delete sale
  Future<int> deleteSale(int id) async {
    Database db = await dbHelper.database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  // Get sales summary
  Future<Map<String, dynamic>> getSalesSummary() async {
    Database db = await dbHelper.database;

    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sales,
        SUM(quantity) as total_items,
        SUM(total_amount) as total_revenue,
        SUM(profit) as total_profit,
        AVG(profit) as avg_profit
      FROM sales
    ''');

    return result.isNotEmpty ? result.first : {};
  }
}
