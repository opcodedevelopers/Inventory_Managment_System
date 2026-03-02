import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../database/product_repository.dart';

class LowStocksScreen extends StatefulWidget {
  @override
  _LowStocksScreenState createState() => _LowStocksScreenState();
}

class _LowStocksScreenState extends State<LowStocksScreen> {
  final ProductRepository _productRepo = ProductRepository();
  List<Product> _lowStockProducts = [];
  List<Product> _outOfStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
  }

  Future<void> _loadLowStockProducts() async {
    setState(() => _isLoading = true);
    try {
      final allProducts = await _productRepo.getAllProducts();
      final lowStock = allProducts.where((product) {
        return product.currentQuantity < product.minStockLevel &&
            product.currentQuantity > 0;
      }).toList();
      final outOfStock = allProducts.where((product) {
        return product.currentQuantity == 0;
      }).toList();
      lowStock.sort((a, b) => a.currentQuantity.compareTo(b.currentQuantity));
      outOfStock.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _lowStockProducts = lowStock;
        _outOfStockProducts = outOfStock;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading low stock products: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getStockColor(int current, int min) {
    if (current == 0) return Colors.black;
    if (current < min) return Colors.red;
    return Colors.green;
  }

  Widget _buildProductCard(Product product, bool isOutOfStock) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStockColor(
              product.currentQuantity,
              product.minStockLevel,
            ).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              isOutOfStock ? Icons.error_outline : Icons.warning,
              color: _getStockColor(
                product.currentQuantity,
                product.minStockLevel,
              ),
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
              'Current: ${product.currentQuantity} | Min: ${product.minStockLevel}',
            ),
            Text(
              'Reorder: ${product.minStockLevel - product.currentQuantity} units needed',
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
                color: _getStockColor(
                  product.currentQuantity,
                  product.minStockLevel,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStockColor(
                    product.currentQuantity,
                    product.minStockLevel,
                  ),
                ),
              ),
              child: Text(
                isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStockColor(
                    product.currentQuantity,
                    product.minStockLevel,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Stock Value: Rs ${(product.currentQuantity * product.buyingPrice).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          _showProductDetails(product, isOutOfStock);
        },
      ),
    );
  }

  void _showProductDetails(Product product, bool isOutOfStock) {
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
                  'Reorder Quantity',
                  '${product.minStockLevel - product.currentQuantity} units',
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
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStockColor(
                      product.currentQuantity,
                      product.minStockLevel,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isOutOfStock ? '⚠️ OUT OF STOCK' : '⚠️ LOW STOCK ALERT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStockColor(
                            product.currentQuantity,
                            product.minStockLevel,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        isOutOfStock
                            ? 'This product is completely out of stock. Restock immediately!'
                            : 'Stock is below minimum level. Reorder ${product.minStockLevel - product.currentQuantity} units.',
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to add stock or edit product
                Navigator.pushNamed(context, '/add_product');
              },
              child: Text('Restock'),
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
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalLowStock = _lowStockProducts.length + _outOfStockProducts.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Low Stocks ($totalLowStock)'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLowStockProducts,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : totalLowStock == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    'All Products are Well Stocked!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No low stock or out of stock products found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary Cards
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Out of Stock',
                          _outOfStockProducts.length.toString(),
                          Colors.black,
                          Icons.error_outline,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          'Low Stock',
                          _lowStockProducts.length.toString(),
                          Colors.red,
                          Icons.warning,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total',
                          totalLowStock.toString(),
                          Colors.orange,
                          Icons.inventory,
                        ),
                      ),
                    ],
                  ),
                ),

                // Out of Stock Section
                if (_outOfStockProducts.isNotEmpty)
                  ExpansionTile(
                    title: Text(
                      'Out of Stock (${_outOfStockProducts.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    leading: Icon(Icons.error_outline, color: Colors.black),
                    children: [
                      ..._outOfStockProducts.map((product) {
                        return _buildProductCard(product, true);
                      }).toList(),
                    ],
                  ),

                // Low Stock Section
                if (_lowStockProducts.isNotEmpty)
                  ExpansionTile(
                    title: Text(
                      'Low Stock (${_lowStockProducts.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    leading: Icon(Icons.warning, color: Colors.red),
                    children: [
                      ..._lowStockProducts.map((product) {
                        return _buildProductCard(product, false);
                      }).toList(),
                    ],
                  ),

                SizedBox(height: 20),

                // Restock Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_product');
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add New Stock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ],
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
