import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../database/product_repository.dart';
import '../database/sale_repository.dart';

class AddSaleScreen extends StatefulWidget {
  @override
  _AddSaleScreenState createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductRepository _productRepo = ProductRepository();
  final SaleRepository _saleRepo = SaleRepository();

  // Form controllers
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();

  // Variables
  Product? _selectedProduct;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  double _unitPrice = 0;
  double _buyingPrice = 0;
  double _totalAmount = 0;
  double _profit = 0;
  double _profitPercentage = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      List<Product> products = await _productRepo.getAllProducts();
      // Only show products with stock
      final availableProducts = products
          .where((p) => p.currentQuantity > 0)
          .toList();
      setState(() {
        _products = availableProducts;
        _filteredProducts = availableProducts;
        if (availableProducts.isNotEmpty) {
          _selectedProduct = availableProducts.first;
          _unitPrice = availableProducts.first.sellingPrice;
          _buyingPrice = availableProducts.first.buyingPrice;
          _calculateTotals();
        }
      });
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  void _searchProducts(String query) {
    setState(() {
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

  void _calculateTotals() {
    if (_selectedProduct != null && _quantityController.text.isNotEmpty) {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final unitPrice = _selectedProduct!.sellingPrice;
      final buyingPrice = _selectedProduct!.buyingPrice;

      final totalAmount = unitPrice * quantity;
      final totalCost = buyingPrice * quantity;
      final profit = totalAmount - totalCost;
      final profitPercentage = buyingPrice > 0 ? (profit / totalCost) * 100 : 0;

      setState(() {
        _unitPrice = unitPrice;
        _buyingPrice = buyingPrice;
        _totalAmount = totalAmount;
        _profit = profit;
        _profitPercentage = profitPercentage.toDouble();
      });
    }
  }

  Future<void> _saveSale() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a product')));
        return;
      }

      final quantity = int.parse(_quantityController.text);
      if (quantity > _selectedProduct!.currentQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough stock. Available: ${_selectedProduct!.currentQuantity}',
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        Sale sale = Sale(
          productId: _selectedProduct!.id!,
          productName: _selectedProduct!.name,
          quantity: quantity,
          unitPrice: _unitPrice,
          buyingPrice: _buyingPrice,
          totalAmount: _totalAmount,
          profit: _profit,
          customerName: _customerNameController.text.isNotEmpty
              ? _customerNameController.text
              : null,
          customerPhone: _customerPhoneController.text.isNotEmpty
              ? _customerPhoneController.text
              : null,
          customerAddress: _customerAddressController.text.isNotEmpty
              ? _customerAddressController.text
              : null,
        );

        // Save sale
        await _saleRepo.addSale(sale);

        // Update product stock
        final newQuantity = _selectedProduct!.currentQuantity - quantity;
        await _productRepo.updateStock(_selectedProduct!.id!, newQuantity);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sale completed successfully! Profit: Rs ${_profit.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        print("Error saving sale: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Sale'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //PRODUCT SEARCH SECTION
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search & Select Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _productSearchController,
                        onChanged: _searchProducts,
                        decoration: InputDecoration(
                          hintText: 'Search product by name, category...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          suffixIcon: _productSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _productSearchController.clear();
                                    _searchProducts('');
                                  },
                                )
                              : null,
                        ),
                      ),

                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _products.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text('No products available'),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return ListTile(
                                    leading: Icon(
                                      Icons.shopping_bag,
                                      color: product.currentQuantity > 0
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    title: Text(
                                      product.name,
                                      style: TextStyle(
                                        fontWeight:
                                            _selectedProduct?.id == product.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Stock: ${product.currentQuantity}',
                                        ),
                                        Text(
                                          'Price: Rs ${product.sellingPrice.toStringAsFixed(2)}',
                                        ),
                                        if (product.category != null)
                                          Text(
                                            'Category: ${product.category!}',
                                          ),
                                      ],
                                    ),
                                    trailing: _selectedProduct?.id == product.id
                                        ? Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                    tileColor:
                                        _selectedProduct?.id == product.id
                                        ? Colors.green.withOpacity(0.1)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedProduct = product;
                                        _unitPrice = product.sellingPrice;
                                        _buyingPrice = product.buyingPrice;
                                        _calculateTotals();
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Selected Product Info
              if (_selectedProduct != null)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: Icon(Icons.check, color: Colors.green),
                          ),
                          title: Text(_selectedProduct!.name),
                          subtitle: Text(
                            'Stock: ${_selectedProduct!.currentQuantity} units available',
                          ),
                          trailing: Text(
                            'Rs ${_selectedProduct!.sellingPrice.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Quantity
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Quantity *',
                          prefixIcon: Icon(Icons.numbers),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  final current =
                                      int.tryParse(_quantityController.text) ??
                                      1;
                                  if (current > 1) {
                                    _quantityController.text = (current - 1)
                                        .toString();
                                    _calculateTotals();
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  final current =
                                      int.tryParse(_quantityController.text) ??
                                      1;
                                  _quantityController.text = (current + 1)
                                      .toString();
                                  _calculateTotals();
                                },
                              ),
                            ],
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculateTotals(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Enter valid quantity';
                          }
                          if (_selectedProduct != null &&
                              qty > _selectedProduct!.currentQuantity) {
                            return 'Max available: ${_selectedProduct!.currentQuantity}';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Price & Profit Details
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price & Profit Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),

                      ListTile(
                        title: Text('Buying Price'),
                        trailing: Text(
                          'Rs ${_buyingPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      ListTile(
                        title: Text('Selling Price'),
                        trailing: Text(
                          'Rs ${_unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      ListTile(
                        title: Text('Quantity'),
                        trailing: Text(
                          _quantityController.text.isEmpty
                              ? '0'
                              : _quantityController.text,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Divider(),

                      ListTile(
                        title: Text('Total Cost'),
                        trailing: Text(
                          'Rs ${(_buyingPrice * (int.tryParse(_quantityController.text) ?? 0)).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),

                      ListTile(
                        title: Text('Total Amount'),
                        trailing: Text(
                          'Rs ${_totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),

                      ListTile(
                        title: Text('Profit'),
                        trailing: Text(
                          'Rs ${_profit.toStringAsFixed(2)} (${_profitPercentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _profit >= 0 ? Colors.green : Colors.red,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Details (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),

                      TextFormField(
                        controller: _customerNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),

                      SizedBox(height: 10),

                      TextFormField(
                        controller: _customerPhoneController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),

                      SizedBox(height: 10),

                      TextFormField(
                        controller: _customerAddressController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'COMPLETE SALE',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
