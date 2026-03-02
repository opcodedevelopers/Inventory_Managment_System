import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../database/product_repository.dart';

class InStocksScreen extends StatefulWidget {
  @override
  _InStocksScreenState createState() => _InStocksScreenState();
}

class _InStocksScreenState extends State<InStocksScreen> {
  final ProductRepository _productRepo = ProductRepository();
  List<Product> _inStockProducts = [];
  List<Product> _normalStockProducts = [];
  List<Product> _overStockProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInStockProducts();
  }

  Future<void> _loadInStockProducts() async {
    setState(() => _isLoading = true);
    try {
      final allProducts = await _productRepo.getAllProducts();
      final inStock = allProducts.where((product) {
        return product.currentQuantity > 0;
      }).toList();
      final normalStock = inStock.where((product) {
        return product.currentQuantity >= product.minStockLevel &&
            product.currentQuantity <= product.maxStockLevel;
      }).toList();
      final overStock = inStock.where((product) {
        return product.currentQuantity > product.maxStockLevel;
      }).toList();
      normalStock.sort(
        (a, b) => b.currentQuantity.compareTo(a.currentQuantity),
      );
      overStock.sort((a, b) => b.currentQuantity.compareTo(a.currentQuantity));

      setState(() {
        _inStockProducts = inStock;
        _normalStockProducts = normalStock;
        _overStockProducts = overStock;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading in-stock products: $e");
      setState(() => _isLoading = false);
    }
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;

    return products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.category?.toLowerCase() ?? '').contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  Color _getStockColor(Product product) {
    if (product.currentQuantity > product.maxStockLevel) return Colors.orange;
    if (product.currentQuantity >= product.minStockLevel) return Colors.green;
    return Colors.red;
  }

  String _getStockStatus(Product product) {
    if (product.currentQuantity > product.maxStockLevel) return 'OVER STOCK';
    if (product.currentQuantity >= product.minStockLevel) return 'IN STOCK';
    return 'LOW STOCK';
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStockColor(product).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              product.currentQuantity > product.maxStockLevel
                  ? Icons.inventory_2
                  : Icons.inventory,
              color: _getStockColor(product),
              size: 24,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.category != null)
              Text('Category: ${product.category!}'),
            Text(
              'Current: ${product.currentQuantity} | Min: ${product.minStockLevel} | Max: ${product.maxStockLevel}',
            ),
            Text(
              'Buy: Rs ${product.buyingPrice.toStringAsFixed(2)} | Sell: Rs ${product.sellingPrice.toStringAsFixed(2)}',
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStockColor(product).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStockColor(product)),
              ),
              child: Text(
                _getStockStatus(product),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStockColor(product),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Value: Rs ${(product.currentQuantity * product.buyingPrice).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          _showProductDetails(product);
        },
      ),
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Category', product.category ?? 'Not set'),
                _buildDetailRow(
                  'Current Stock',
                  product.currentQuantity.toString(),
                ),
                _buildDetailRow(
                  'Minimum Stock',
                  product.minStockLevel.toString(),
                ),
                _buildDetailRow(
                  'Maximum Stock',
                  product.maxStockLevel.toString(),
                ),
                _buildDetailRow(
                  'Stock Range',
                  '${product.minStockLevel} - ${product.maxStockLevel}',
                ),
                _buildDetailRow(
                  'Buying Price',
                  'Rs ${product.buyingPrice.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Selling Price',
                  'Rs ${product.sellingPrice.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Stock Value',
                  'Rs ${(product.currentQuantity * product.buyingPrice).toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Profit Margin',
                  'Rs ${(product.sellingPrice - product.buyingPrice).toStringAsFixed(2)} per unit',
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStockColor(product).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getStockStatus(product),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStockColor(product),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (product.currentQuantity > product.maxStockLevel)
                        Text(
                          'Stock is above maximum level. Consider slowing down restocking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        )
                      else if (product.currentQuantity >= product.minStockLevel)
                        Text(
                          'Stock is at optimal level.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 120,
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
    final totalInStock = _inStockProducts.length;
    final filteredNormal = _getFilteredProducts(_normalStockProducts);
    final filteredOver = _getFilteredProducts(_overStockProducts);

    return Scaffold(
      appBar: AppBar(
        title: Text('In Stocks ($totalInStock)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInStockProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              onChanged: _searchProducts,
              decoration: InputDecoration(
                hintText: 'Search in-stock products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () => _searchProducts(''),
                      )
                    : null,
              ),
            ),
          ),

          // Summary Cards
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total In Stock',
                    totalInStock.toString(),
                    Colors.green,
                    Icons.inventory,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'Normal Stock',
                    _normalStockProducts.length.toString(),
                    Colors.blue,
                    Icons.check_circle,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'Over Stock',
                    _overStockProducts.length.toString(),
                    Colors.orange,
                    Icons.warning,
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : totalInStock == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'No Products in Stock',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('Add products to see them here.'),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInStockProducts,
                    child: ListView(
                      children: [
                        // Normal Stock Section
                        if (filteredNormal.isNotEmpty)
                          ExpansionTile(
                            title: Text(
                              'Normal Stock (${filteredNormal.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            leading: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            initiallyExpanded: true,
                            children: [
                              ...filteredNormal.map((product) {
                                return _buildProductCard(product);
                              }).toList(),
                            ],
                          ),

                        // Over Stock Section
                        if (filteredOver.isNotEmpty)
                          ExpansionTile(
                            title: Text(
                              'Over Stock (${filteredOver.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            leading: Icon(Icons.warning, color: Colors.orange),
                            children: [
                              ...filteredOver.map((product) {
                                return _buildProductCard(product);
                              }).toList(),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_product');
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
