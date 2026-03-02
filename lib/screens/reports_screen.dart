import 'package:flutter/material.dart';
import '../database/product_repository.dart';
import '../database/investment_repository.dart';
import '../database/sale_repository.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final InvestmentRepository _investmentRepo = InvestmentRepository();
  final SaleRepository _saleRepo = SaleRepository();

  // Report Data
  Map<String, dynamic> _monthlyReport = {};
  Map<String, dynamic> _stockReport = {};
  Map<String, dynamic> _investmentReport = {};
  Map<String, dynamic> _salesReport = {};
  Map<String, dynamic> _profitReport = {};
  List<Map<String, dynamic>> _customerReport = [];
  Map<String, double> _productProfitReport = {};

  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      // Load all reports in parallel
      final month = _selectedMonth.month;
      final year = _selectedMonth.year;

      final monthlyData = await _getMonthlyReport(year, month);
      final stockData = await _getStockReport();
      final investmentData = await _getInvestmentReport(year, month);
      final salesData = await _getSalesReport(year, month);
      final profitData = await _getProfitReport(year, month);
      final customerData = await _saleRepo.getCustomerWiseSales();
      final productProfitData = await _saleRepo.getProductWiseProfit();

      setState(() {
        _monthlyReport = monthlyData;
        _stockReport = stockData;
        _investmentReport = investmentData;
        _salesReport = salesData;
        _profitReport = profitData;
        _customerReport = customerData;
        _productProfitReport = productProfitData;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading reports: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getMonthlyReport(int year, int month) async {
    final monthlySales = await _saleRepo.getMonthlyTotalSales(year, month);
    final monthlyInvestment = await _investmentRepo.getMonthlyInvestment(
      year,
      month,
    );

    double totalSales = monthlySales;
    double totalInvestment = monthlyInvestment['total'] ?? 0;
    double profit = totalSales - totalInvestment;

    return {
      'sales': totalSales,
      'investment': totalInvestment,
      'profit': profit,
      'month': '$month/$year',
    };
  }

  Future<Map<String, dynamic>> _getStockReport() async {
    final products = await _productRepo.getAllProducts();
    final totalValue = await _productRepo.getTotalStockValue();

    int outOfStock = products.where((p) => p.currentQuantity == 0).length;
    int lowStock = products
        .where(
          (p) => p.currentQuantity < p.minStockLevel && p.currentQuantity > 0,
        )
        .length;
    int normalStock = products
        .where(
          (p) =>
              p.currentQuantity >= p.minStockLevel &&
              p.currentQuantity <= p.maxStockLevel,
        )
        .length;
    int overStock = products
        .where((p) => p.currentQuantity > p.maxStockLevel)
        .length;

    return {
      'total_products': products.length,
      'total_value': totalValue,
      'out_of_stock': outOfStock,
      'low_stock': lowStock,
      'normal_stock': normalStock,
      'over_stock': overStock,
    };
  }

  Future<Map<String, dynamic>> _getInvestmentReport(int year, int month) async {
    final allInvestments = await _investmentRepo.getAllInvestments();
    final monthlyData = await _investmentRepo.getMonthlyInvestment(year, month);

    // Latest investments
    List<Map<String, dynamic>> latestInvestments = [];
    int count = 0;
    for (var inv in allInvestments.take(5)) {
      latestInvestments.add({
        'description': inv.description,
        'amount': inv.amount,
        'date': inv.formattedDate,
        'type': inv.typeText,
      });
      count++;
    }

    return {
      'total': monthlyData['total'] ?? 0,
      'type_wise': monthlyData['type_wise'] ?? {},
      'latest': latestInvestments,
      'count': count,
    };
  }

  Future<Map<String, dynamic>> _getSalesReport(int year, int month) async {
    final monthlySales = await _saleRepo.getMonthlySales(year, month);

    double totalSales = 0;
    int totalItems = 0;
    double totalProfit = 0;

    for (var sale in monthlySales) {
      totalSales += sale.totalAmount;
      totalItems += sale.quantity;
      totalProfit += sale.profit;
    }

    return {
      'total_sales': totalSales,
      'total_items': totalItems,
      'total_profit': totalProfit,
      'average_sale': monthlySales.isNotEmpty
          ? totalSales / monthlySales.length
          : 0,
      'transaction_count': monthlySales.length,
    };
  }

  Future<Map<String, dynamic>> _getProfitReport(int year, int month) async {
    final salesSummary = await _saleRepo.getSalesSummary();

    return {
      'total_profit': salesSummary['total_profit'] ?? 0,
      'avg_profit': salesSummary['avg_profit'] ?? 0,
      'total_sales': salesSummary['total_sales'] ?? 0,
      'total_items': salesSummary['total_items'] ?? 0,
      'total_revenue': salesSummary['total_revenue'] ?? 0,
    };
  }

  Widget _buildReportCard(String title, Widget content) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReportCard() {
    return _buildReportCard(
      'Monthly Report (${_monthlyReport['month'] ?? ''})',
      Column(
        children: [
          _buildStatRow(
            'Total Sales',
            'Rs ${(_monthlyReport['sales'] ?? 0).toStringAsFixed(2)}',
            Colors.green,
          ),
          _buildStatRow(
            'Total Investment',
            'Rs ${(_monthlyReport['investment'] ?? 0).toStringAsFixed(2)}',
            Colors.blue,
          ),
          _buildStatRow(
            'Net Profit',
            'Rs ${(_monthlyReport['profit'] ?? 0).toStringAsFixed(2)}',
            (_monthlyReport['profit'] ?? 0) >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStockReportCard() {
    return _buildReportCard(
      'Stock Report',
      Column(
        children: [
          _buildStatRow(
            'Total Products',
            '${_stockReport['total_products'] ?? 0}',
            Colors.blue,
          ),
          _buildStatRow(
            'Stock Value',
            'Rs ${(_stockReport['total_value'] ?? 0).toStringAsFixed(2)}',
            Colors.green,
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMiniStat(
                'Out of Stock',
                '${_stockReport['out_of_stock'] ?? 0}',
                Colors.black,
              ),
              _buildMiniStat(
                'Low Stock',
                '${_stockReport['low_stock'] ?? 0}',
                Colors.red,
              ),
              _buildMiniStat(
                'Normal',
                '${_stockReport['normal_stock'] ?? 0}',
                Colors.green,
              ),
              _buildMiniStat(
                'Over Stock',
                '${_stockReport['over_stock'] ?? 0}',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentReportCard() {
    Map<String, double> typeWise = Map<String, double>.from(
      _investmentReport['type_wise'] ?? {},
    );

    return _buildReportCard(
      'Investment Report',
      Column(
        children: [
          _buildStatRow(
            'Total Investment',
            'Rs ${(_investmentReport['total'] ?? 0).toStringAsFixed(2)}',
            Colors.blue,
          ),

          if (typeWise.isNotEmpty) ...[
            SizedBox(height: 10),
            ...typeWise.entries.map((entry) {
              return _buildStatRow(
                entry.key == 'product_purchase'
                    ? 'Product Purchase'
                    : entry.key == 'expense'
                    ? 'Expenses'
                    : 'Other',
                'Rs ${entry.value.toStringAsFixed(2)}',
                Colors.grey,
                isSmall: true,
              );
            }).toList(),
          ],

          SizedBox(height: 10),
          Text(
            'Latest Investments',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          if ((_investmentReport['latest'] as List).isNotEmpty) ...[
            SizedBox(height: 5),
            ...(_investmentReport['latest'] as List<Map<String, dynamic>>).map((
              inv,
            ) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.circle, size: 8, color: Colors.blue),
                title: Text(inv['description'], style: TextStyle(fontSize: 12)),
                trailing: Text(
                  'Rs ${inv['amount'].toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesReportCard() {
    return _buildReportCard(
      'Sales Report',
      Column(
        children: [
          _buildStatRow(
            'Total Sales',
            'Rs ${(_salesReport['total_sales'] ?? 0).toStringAsFixed(2)}',
            Colors.green,
          ),
          _buildStatRow(
            'Items Sold',
            '${_salesReport['total_items'] ?? 0}',
            Colors.blue,
          ),
          _buildStatRow(
            'Total Profit',
            'Rs ${(_salesReport['total_profit'] ?? 0).toStringAsFixed(2)}',
            (_salesReport['total_profit'] ?? 0) >= 0
                ? Colors.green
                : Colors.red,
          ),
          _buildStatRow(
            'Transactions',
            '${_salesReport['transaction_count'] ?? 0}',
            Colors.purple,
          ),
          _buildStatRow(
            'Average Sale',
            'Rs ${(_salesReport['average_sale'] ?? 0).toStringAsFixed(2)}',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildProfitAnalysisCard() {
    return _buildReportCard(
      'Profit Analysis',
      Column(
        children: [
          _buildStatRow(
            'Total Profit',
            'Rs ${(_profitReport['total_profit'] ?? 0).toStringAsFixed(2)}',
            (_profitReport['total_profit'] ?? 0) >= 0
                ? Colors.green
                : Colors.red,
          ),
          _buildStatRow(
            'Average Profit',
            'Rs ${(_profitReport['avg_profit'] ?? 0).toStringAsFixed(2)}',
            Colors.orange,
          ),
          _buildStatRow(
            'Total Revenue',
            'Rs ${(_profitReport['total_revenue'] ?? 0).toStringAsFixed(2)}',
            Colors.green,
          ),
          _buildStatRow(
            'Total Transactions',
            '${_profitReport['total_sales'] ?? 0}',
            Colors.blue,
          ),
          _buildStatRow(
            'Items Sold',
            '${_profitReport['total_items'] ?? 0}',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildProductProfitCard() {
    return _buildReportCard(
      'Product-wise Profit',
      _productProfitReport.isEmpty
          ? Text('No product profit data available')
          : Column(
              children: [
                for (
                  var i = 0;
                  i <
                      (_productProfitReport.length > 5
                          ? 5
                          : _productProfitReport.length);
                  i++
                )
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Icon(
                        Icons.shopping_bag,
                        size: 14,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      _productProfitReport.keys.toList()[i],
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      'Rs ${_productProfitReport.values.toList()[i].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _productProfitReport.values.toList()[i] >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                if (_productProfitReport.length > 5)
                  TextButton(
                    onPressed: () {
                      _showAllProductProfits();
                    },
                    child: Text(
                      'View All ${_productProfitReport.length} Products',
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCustomerAnalysisCard() {
    return _buildReportCard(
      'Customer Analysis',
      _customerReport.isEmpty
          ? Text('No customer data available')
          : Column(
              children: [
                for (
                  var i = 0;
                  i < (_customerReport.length > 5 ? 5 : _customerReport.length);
                  i++
                )
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        _customerReport[i]['customer_name']
                            .toString()
                            .substring(0, 1),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(
                      _customerReport[i]['customer_name'].toString(),
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      '${_customerReport[i]['total_purchases']} purchases',
                      style: TextStyle(fontSize: 10),
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs ${(_customerReport[i]['total_spent']?.toDouble() ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Profit: Rs ${(_customerReport[i]['total_profit']?.toDouble() ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                if (_customerReport.length > 5)
                  TextButton(
                    onPressed: () {
                      _showAllCustomers();
                    },
                    child: Text('View All ${_customerReport.length} Customers'),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    Color color, {
    bool isSmall = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAllProductProfits() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('All Product Profits (${_productProfitReport.length})'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _productProfitReport.length,
              itemBuilder: (context, index) {
                var key = _productProfitReport.keys.toList()[index];
                var value = _productProfitReport.values.toList()[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: value >= 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: Icon(
                        value >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: value >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(key),
                    trailing: Text(
                      'Rs ${value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: value >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAllCustomers() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('All Customers (${_customerReport.length})'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _customerReport.length,
              itemBuilder: (context, index) {
                var customer = _customerReport[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        customer['customer_name'].toString().substring(0, 1),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    title: Text(customer['customer_name'].toString()),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purchases: ${customer['total_purchases']}'),
                        Text(
                          'Spent: Rs ${(customer['total_spent']?.toDouble() ?? 0).toStringAsFixed(2)}',
                        ),
                        Text(
                          'Profit: Rs ${(customer['total_profit']?.toDouble() ?? 0).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Month Selector
                  Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      leading: Icon(Icons.calendar_month, color: Colors.blue),
                      title: Text('Selected Month'),
                      subtitle: Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _selectMonth(context),
                        child: Text('Change Month'),
                      ),
                    ),
                  ),
                  _buildMonthlyReportCard(),
                  _buildSalesReportCard(),
                  _buildProfitAnalysisCard(),
                  _buildProductProfitCard(),
                  _buildStockReportCard(),
                  _buildInvestmentReportCard(),
                  _buildCustomerAnalysisCard(),

                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _exportReports();
                        },
                        icon: Icon(Icons.download),
                        label: Text('Export All Reports'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  void _exportReports() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Export Reports'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.insert_drive_file, color: Colors.blue),
                title: Text('Export as CSV'),
                onTap: () {
                  Navigator.pop(context);
                  _showExportSuccess('CSV');
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Export as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _showExportSuccess('PDF');
                },
              ),
              ListTile(
                leading: Icon(Icons.table_chart, color: Colors.green),
                title: Text('Export as Excel'),
                onTap: () {
                  Navigator.pop(context);
                  _showExportSuccess('Excel');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showExportSuccess(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reports exported as $format successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
