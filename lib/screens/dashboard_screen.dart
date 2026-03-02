import 'package:flutter/material.dart';
import '../database/product_repository.dart';
import '../database/investment_repository.dart';
import '../database/sale_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Repositories
  final ProductRepository _productRepo = ProductRepository();
  final InvestmentRepository _investmentRepo = InvestmentRepository();
  final SaleRepository _saleRepo = SaleRepository();

  // Statistics
  int _totalProducts = 0;
  int _lowStockCount = 0;
  double _totalInvestment = 0;
  double _productInvestment = 0;
  double _otherInvestment = 0;
  double _totalSales = 0;
  double _monthlySales = 0;
  double _monthlyProfit = 0;
  double _totalProfit = 0;

  // Bottom Navigation
  int _selectedIndex = 0;

  // New variables for communication text
  final List<String> _welcomeMessages = [
    "Welcome back! Your business is growing.",
    "Great work! Keep managing your inventory smartly.",
    "Your business insights are ready.",
    "Stay organized, stay profitable.",
    "Track everything, miss nothing.",
    "Smart inventory management leads to success.",
  ];

  String _currentMessage = "";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _updateWelcomeMessage();
  }

  Future<void> _loadDashboardData() async {
    try {
      final products = await _productRepo.getAllProducts();
      final lowStock = await _productRepo.getLowStockProducts();
      final totalInv = await _investmentRepo.getTotalInvestment();
      final productInv = await _investmentRepo.getProductInvestmentTotal();
      final otherInv = await _investmentRepo.getOtherInvestmentTotal();
      final totalProfitFromSales = await _saleRepo.getTotalProfit();
      final totalSalesRevenue = await _saleRepo.getTotalSales();
      final now = DateTime.now();
      final monthlySales = await _saleRepo.getMonthlyTotalSales(
        now.year,
        now.month,
      );
      final monthlyInvest = await _investmentRepo.getMonthlyInvestment(
        now.year,
        now.month,
      );
      final monthlyInvestment = monthlyInvest['total'] ?? 0;
      final monthlySalesList = await _saleRepo.getMonthlySales(
        now.year,
        now.month,
      );
      double monthlyProfitFromSales = 0;
      for (var sale in monthlySalesList) {
        monthlyProfitFromSales += sale.profit;
      }

      setState(() {
        _totalProducts = products.length;
        _lowStockCount = lowStock.length;
        _totalInvestment = totalInv;
        _productInvestment = productInv;
        _otherInvestment = otherInv;
        _totalSales = totalSalesRevenue;
        _monthlySales = monthlySales;
        _monthlyProfit = monthlyProfitFromSales;
        _totalProfit = totalProfitFromSales;
      });

      print("Dashboard Data Loaded:");
      print("Total Products: $_totalProducts");
      print("Low Stock: $_lowStockCount");
      print("Total Investment: $_totalInvestment");
      print("Product Investment: $_productInvestment");
      print("Other Investment: $_otherInvestment");
      print("Total Sales Revenue: $_totalSales");
      print("Monthly Sales Revenue: $_monthlySales");
      print("Monthly Profit: $_monthlyProfit");
      print("Total Profit: $_totalProfit");
    } catch (e) {
      print("Error loading dashboard: $e");
    }
  }

  void _updateWelcomeMessage() {
    final now = DateTime.now();
    final hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = "Good Morning! ☀️";
    } else if (hour < 17) {
      greeting = "Good Afternoon! 🌤️";
    } else {
      greeting = "Good Evening! 🌙";
    }

    final randomIndex = DateTime.now().millisecond % _welcomeMessages.length;
    setState(() {
      _currentMessage = "$greeting\n${_welcomeMessages[randomIndex]}";
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/products');
        break;
      case 2:
        Navigator.pushNamed(context, '/sales');
        break;
      case 3:
        Navigator.pushNamed(context, '/investments');
        break;
      case 4:
        Navigator.pushNamed(context, '/reports');
        break;
    }
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showBusinessTips() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('💡 Business Communication Tips'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTipItem('Track daily sales to identify patterns'),
                _buildTipItem('Maintain optimal stock levels'),
                _buildTipItem('Review monthly profit/loss reports'),
                _buildTipItem('Update inventory regularly'),
                _buildTipItem('Set reorder points for fast-moving items'),
                _buildTipItem('Analyze customer buying behavior'),
                _buildTipItem("Make The Goals On The Daily Basics"),
              ],
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

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _getRandomTip() {
    final tips = [
      "Regular inventory checks prevent stockouts.",
      "Analyze sales data to optimize product ordering.",
      "Keep popular items well-stocked for maximum sales.",
      "Track expiration dates for perishable goods.",
      "Regular price reviews can improve profit margins.",
      "Customer feedback helps improve product selection.",
    ];
    final index = DateTime.now().millisecond % tips.length;
    return tips[index];
  }

  void _showRandomTip() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Simple Salar Mobile Logo
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "SM",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Business Name Only
            Text(
              'Salar Mobile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadDashboardData();
              _updateWelcomeMessage();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card with Logo and Communication Text
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade50, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // App Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blue.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "IM",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 20),

                      // Welcome Message
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentMessage.split('\n')[0],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              _currentMessage.split('\n')[1],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Info Icon
                      IconButton(
                        onPressed: _showBusinessTips,
                        icon: Icon(Icons.info_outline, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: Colors.amber,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Business Tip of the Day',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.refresh, size: 18),
                            onPressed: _showRandomTip,
                            padding: EdgeInsets.zero,
                            tooltip: 'New Tip',
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        _getRandomTip(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Statistics Section
              Text(
                '📊 Statistics Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Products',
                      _totalProducts.toString(),
                      Icons.inventory,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock',
                      _lowStockCount.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Investment',
                      'Rs ${_totalInvestment.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Monthly Sales',
                      'Rs ${_monthlySales.toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),
              Text(
                'Investment Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Product Investment
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: Icon(
                            Icons.shopping_cart,
                            size: 18,
                            color: Colors.purple,
                          ),
                        ),
                        title: Text('Product Purchase'),
                        trailing: Text(
                          'Rs ${_productInvestment.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: Icon(
                            Icons.money_off,
                            size: 18,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text('Other Expenses'),
                        trailing: Text(
                          'Rs ${_otherInvestment.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Divider(),

                      // Total
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: Icon(
                            Icons.account_balance_wallet,
                            size: 18,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          'Total Investment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          'Rs ${_totalInvestment.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Profit Section
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Profit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Rs ${_monthlyProfit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _monthlyProfit >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Profit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Rs ${_totalProfit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _totalProfit >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: _monthlyProfit >= 0 ? 70 : 30,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _monthlyProfit >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Quick Actions - ONLY ONE SECTION
              Text(
                '✏️ Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _buildQuickAction(
                    'Add Product',
                    Icons.add,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/add_product'),
                  ),
                  _buildQuickAction(
                    'New Sale',
                    Icons.sell,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/add_sale'),
                  ),
                  _buildQuickAction(
                    'Add Investment',
                    Icons.attach_money,
                    Colors.orange,
                    () => Navigator.pushNamed(context, '/add_investment'),
                  ),
                  _buildQuickAction(
                    'Products',
                    Icons.inventory,
                    Colors.purple,
                    () => Navigator.pushNamed(context, '/products'),
                  ),
                  _buildQuickAction(
                    'Sales',
                    Icons.shopping_cart,
                    Colors.red,
                    () => Navigator.pushNamed(context, '/sales'),
                  ),
                  _buildQuickAction(
                    'Investments',
                    Icons.account_balance_wallet,
                    Colors.teal,
                    () => Navigator.pushNamed(context, '/investments'),
                  ),
                  _buildQuickAction(
                    'Low Stocks',
                    Icons.warning,
                    Colors.red,
                    () => Navigator.pushNamed(context, '/low_stocks'),
                  ),
                  _buildQuickAction(
                    'In Stocks',
                    Icons.check_circle,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/in_stocks'),
                  ),
                  _buildQuickAction(
                    'Reports',
                    Icons.assessment,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/reports'),
                  ),
                ],
              ),

              SizedBox(height: 20),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View All',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          'Dashboard loaded successfully',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Just now',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Icon(
                            Icons.refresh,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          'Data refreshed',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Last refresh: ${DateTime.now().hour}:${DateTime.now().minute}',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell_outlined),
            activeIcon: Icon(Icons.sell),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Investments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Quick Add',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: IconButton(
                                icon: Icon(Icons.add, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/add_product');
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Product', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: IconButton(
                                icon: Icon(
                                  Icons.attach_money,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    '/add_investment',
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Investment', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              child: IconButton(
                                icon: Icon(Icons.sell, color: Colors.orange),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/add_sale');
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Sale', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Quick Add',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
