import 'package:flutter/material.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';
import '../database/sale_repository.dart';
import '../database/product_repository.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SaleRepository _saleRepo = SaleRepository();
  final ProductRepository _productRepo = ProductRepository();
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String _selectedFilter = 'today';
  String _searchQuery = '';
  double _totalSalesAmount = 0;
  double _totalProfit = 0;
  int _totalItemsSold = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load sales and products simultaneously
      final sales = await _saleRepo.getAllSales();
      final products = await _productRepo.getAllProducts();

      // Calculate totals
      double totalAmount = 0;
      double totalProfit = 0;
      int totalItems = 0;

      for (var sale in sales) {
        totalAmount += sale.totalAmount;
        totalProfit += sale.profit;
        totalItems += sale.quantity;
      }
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      final todaySales = sales.where((sale) {
        final saleDate = sale.saleDate.toIso8601String().split('T')[0];
        return saleDate == todayStr;
      }).toList();

      setState(() {
        _sales = sales;
        _allProducts = products;
        _filteredSales = todaySales;
        _totalSalesAmount = totalAmount;
        _totalProfit = totalProfit;
        _totalItemsSold = totalItems;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSearchBar() {
    List<Product> filteredProducts = _searchQuery.isEmpty
        ? []
        : _allProducts.where((product) {
            return product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (product.category?.toLowerCase() ?? '').contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _searchSales(value);
            },
            decoration: InputDecoration(
              hintText: 'Search by product name or customer...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _searchSales('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty && filteredProducts.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Products matching "${_searchQuery}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...filteredProducts.take(5).map((product) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.shopping_bag,
                      size: 18,
                      color: Colors.blue,
                    ),
                    title: Text(product.name, style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      'Stock: ${product.currentQuantity} | Price: Rs ${product.sellingPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      product.category ?? 'No Category',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    onTap: () {
                      setState(() {
                        _searchQuery = product.name;
                      });
                      _searchSales(product.name);
                    },
                  );
                }).toList(),
                if (filteredProducts.length > 5)
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      '... and ${filteredProducts.length - 5} more',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _searchSales(String query) {
    setState(() {
      _searchQuery = query;
      List<Sale> tempSales = _sales;

      if (_selectedFilter == 'today') {
        final today = DateTime.now();
        final todayStr = today.toIso8601String().split('T')[0];
        tempSales = _sales.where((sale) {
          final saleDate = sale.saleDate.toIso8601String().split('T')[0];
          return saleDate == todayStr;
        }).toList();
      } else if (_selectedFilter == 'week') {
        final weekAgo = DateTime.now().subtract(Duration(days: 7));
        tempSales = _sales.where((sale) {
          return sale.saleDate.isAfter(weekAgo);
        }).toList();
      } else if (_selectedFilter == 'month') {
        final monthAgo = DateTime.now().subtract(Duration(days: 30));
        tempSales = _sales.where((sale) {
          return sale.saleDate.isAfter(monthAgo);
        }).toList();
      }
      if (query.isEmpty) {
        _filteredSales = tempSales;
      } else {
        _filteredSales = tempSales.where((sale) {
          return sale.productName.toLowerCase().contains(query.toLowerCase()) ||
              (sale.customerName?.toLowerCase() ?? '').contains(
                query.toLowerCase(),
              );
        }).toList();
      }
    });
  }

  void _filterSales(String filter) {
    setState(() {
      _selectedFilter = filter;

      if (filter == 'today') {
        final today = DateTime.now();
        final todayStr = today.toIso8601String().split('T')[0];
        _filteredSales = _sales.where((sale) {
          final saleDate = sale.saleDate.toIso8601String().split('T')[0];
          return saleDate == todayStr;
        }).toList();
      } else if (filter == 'week') {
        final weekAgo = DateTime.now().subtract(Duration(days: 7));
        _filteredSales = _sales.where((sale) {
          return sale.saleDate.isAfter(weekAgo);
        }).toList();
      } else if (filter == 'month') {
        final monthAgo = DateTime.now().subtract(Duration(days: 30));
        _filteredSales = _sales.where((sale) {
          return sale.saleDate.isAfter(monthAgo);
        }).toList();
      } else {
        _filteredSales = _sales;
      }
      if (_searchQuery.isNotEmpty) {
        _filteredSales = _filteredSales.where((sale) {
          return sale.productName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (sale.customerName?.toLowerCase() ?? '').contains(
                _searchQuery.toLowerCase(),
              );
        }).toList();
      }
    });
  }

  Future<void> _deleteSale(Sale sale) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Sale'),
          content: Text(
            'Are you sure you want to delete this sale of "${sale.productName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _saleRepo.deleteSale(sale.id!);
      _loadData(); // Refresh list

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sale deleted successfully')));
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: sale.profit >= 0
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              sale.profit >= 0 ? Icons.trending_up : Icons.trending_down,
              color: sale.profit >= 0 ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
        ),
        title: Text(
          sale.productName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${sale.quantity}'),
            Text('Date: ${_formatDate(sale.saleDate)}'),
            if (sale.customerName != null && sale.customerName!.isNotEmpty)
              Text('Customer: ${sale.customerName!}'),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs ${sale.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Profit: Rs ${sale.profit.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: sale.profit >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          _showSaleDetails(sale);
        },
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sale Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSaleDetailRow('Product', sale.productName),
                _buildSaleDetailRow('Quantity', sale.quantity.toString()),
                _buildSaleDetailRow(
                  'Unit Price',
                  'Rs ${sale.unitPrice.toStringAsFixed(2)}',
                ),
                _buildSaleDetailRow(
                  'Buying Price',
                  'Rs ${sale.buyingPrice.toStringAsFixed(2)}',
                ),
                _buildSaleDetailRow(
                  'Total Amount',
                  'Rs ${sale.totalAmount.toStringAsFixed(2)}',
                ),
                _buildSaleDetailRow(
                  'Profit',
                  'Rs ${sale.profit.toStringAsFixed(2)} (${sale.profitPercentage.toStringAsFixed(1)}%)',
                ),
                _buildSaleDetailRow('Date', _formatDate(sale.saleDate)),
                if (sale.customerName != null && sale.customerName!.isNotEmpty)
                  _buildSaleDetailRow('Customer', sale.customerName!),
                if (sale.customerPhone != null &&
                    sale.customerPhone!.isNotEmpty)
                  _buildSaleDetailRow('Phone', sale.customerPhone!),
                if (sale.customerAddress != null &&
                    sale.customerAddress!.isNotEmpty)
                  _buildSaleDetailRow('Address', sale.customerAddress!),
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

  Widget _buildSaleDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales (${_filteredSales.length})'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Sales Overview',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Rs ${_totalSalesAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Total Sales',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Rs ${_totalProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _totalProfit >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            'Total Profit',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            _totalItemsSold.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Items Sold',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Today'),
                  selected: _selectedFilter == 'today',
                  onSelected: (_) => _filterSales('today'),
                ),
                SizedBox(width: 5),
                FilterChip(
                  label: Text('This Week'),
                  selected: _selectedFilter == 'week',
                  onSelected: (_) => _filterSales('week'),
                ),
                SizedBox(width: 5),
                FilterChip(
                  label: Text('This Month'),
                  selected: _selectedFilter == 'month',
                  onSelected: (_) => _filterSales('month'),
                ),
                SizedBox(width: 5),
                FilterChip(
                  label: Text('All Time'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => _filterSales('all'),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          _selectedFilter == 'today'
                              ? 'No sales today'
                              : 'No sales found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                              _searchSales('');
                            },
                            child: Text('Clear Search'),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      itemCount: _filteredSales.length,
                      itemBuilder: (context, index) {
                        return _buildSaleCard(_filteredSales[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_sale');
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
