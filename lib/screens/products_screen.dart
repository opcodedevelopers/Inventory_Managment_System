import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../database/product_repository.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductRepository _productRepo = ProductRepository();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      List<Product> products = await _productRepo.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading products: $e");
      setState(() => _isLoading = false);
    }
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
              (product.category?.toLowerCase() ?? '').contains(
                query.toLowerCase(),
              ) ||
              (product.barcode?.toLowerCase() ?? '').contains(
                query.toLowerCase(),
              );
        }).toList();
      }
    });
  }

  Color _getStockColor(Product product) {
    if (product.currentQuantity <= 0) return Colors.black;
    if (product.currentQuantity < product.minStockLevel) return Colors.red;
    if (product.currentQuantity > product.maxStockLevel) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatus(Product product) {
    if (product.currentQuantity <= 0) return 'Out of Stock';
    if (product.currentQuantity < product.minStockLevel) return 'Low Stock';
    if (product.currentQuantity > product.maxStockLevel) return 'Over Stock';
    return 'In Stock';
  }

  // ✅ EDIT PRODUCT FUNCTION
  Future<void> _editProduct(Product product) async {
    // Edit dialog
    TextEditingController nameController = TextEditingController(
      text: product.name,
    );
    TextEditingController categoryController = TextEditingController(
      text: product.category ?? '',
    );
    TextEditingController quantityController = TextEditingController(
      text: product.currentQuantity.toString(),
    );
    TextEditingController minStockController = TextEditingController(
      text: product.minStockLevel.toString(),
    );
    TextEditingController maxStockController = TextEditingController(
      text: product.maxStockLevel.toString(),
    );
    TextEditingController buyPriceController = TextEditingController(
      text: product.buyingPrice.toString(),
    );
    TextEditingController sellPriceController = TextEditingController(
      text: product.sellingPrice.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: minStockController,
                        decoration: InputDecoration(labelText: 'Min Stock'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: maxStockController,
                  decoration: InputDecoration(labelText: 'Max Stock'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: buyPriceController,
                        decoration: InputDecoration(labelText: 'Buy Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sellPriceController,
                        decoration: InputDecoration(labelText: 'Sell Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update product
                Product updatedProduct = Product(
                  id: product.id,
                  name: nameController.text,
                  category: categoryController.text.isEmpty
                      ? null
                      : categoryController.text,
                  currentQuantity: int.parse(quantityController.text),
                  minStockLevel: int.parse(minStockController.text),
                  maxStockLevel: int.parse(maxStockController.text),
                  buyingPrice: double.parse(buyPriceController.text),
                  sellingPrice: double.parse(sellPriceController.text),
                  description: product.description,
                  barcode: product.barcode,
                  createdAt: product.createdAt,
                );

                await _productRepo.updateProduct(updatedProduct);
                _loadProducts(); // Refresh list
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product updated successfully')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(Product product) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Product'),
          content: Text('Are you sure you want to delete "${product.name}"?'),
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
      await _productRepo.deleteProduct(product.id!);
      _loadProducts(); // Refresh list

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product deleted successfully')));
    }
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStockColor(product).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              product.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getStockColor(product),
              ),
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
              'Stock: ${product.currentQuantity} | Min: ${product.minStockLevel}',
            ),
            Text(
              'Buy: Rs ${product.buyingPrice.toStringAsFixed(2)} | Sell: Rs ${product.sellingPrice.toStringAsFixed(2)}',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stock Status Badge
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
                  fontSize: 12,
                  color: _getStockColor(product),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 10),
            // Edit & Delete Buttons
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') {
                  _editProduct(product);
                } else if (value == 'delete') {
                  _deleteProduct(product);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Show product details
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
                _buildDetailRow('Min Stock', product.minStockLevel.toString()),
                _buildDetailRow('Max Stock', product.maxStockLevel.toString()),
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
                  'Profit per Item',
                  'Rs ${(product.sellingPrice - product.buyingPrice).toStringAsFixed(2)}',
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStockColor(product).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getStockStatus(product),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStockColor(product),
                      ),
                    ),
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
                _editProduct(product);
              },
              child: Text('Edit'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Products (${_filteredProducts.length})'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadProducts),
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
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Stats Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildStatBox('Total', '${_products.length}', Colors.blue),
                SizedBox(width: 10),
                _buildStatBox(
                  'In Stock',
                  '${_products.where((p) => p.currentQuantity > 0).length}',
                  Colors.green,
                ),
                SizedBox(width: 10),
                _buildStatBox(
                  'Low',
                  '${_products.where((p) => p.currentQuantity < p.minStockLevel && p.currentQuantity > 0).length}',
                  Colors.red,
                ),
                SizedBox(width: 10),
                _buildStatBox(
                  'Out',
                  '${_products.where((p) => p.currentQuantity == 0).length}',
                  Colors.black,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'No products found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () => _searchProducts(''),
                            child: Text('Clear Search'),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_filteredProducts[index]);
                      },
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
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
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
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
