import 'package:flutter/material.dart';
import '../models/investment_model.dart';
import '../models/product_model.dart';
import '../database/investment_repository.dart';
import '../database/product_repository.dart';

class AddInvestmentScreen extends StatefulWidget {
  @override
  _AddInvestmentScreenState createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final InvestmentRepository _investmentRepo = InvestmentRepository();
  final ProductRepository _productRepo = ProductRepository();

  // Form controllers
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Variables
  String _selectedType = 'product_purchase';
  Product? _selectedProduct;
  List<Product> _products = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      List<Product> products = await _productRepo.getAllProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  Future<void> _saveInvestment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == 'product_purchase' && _selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a product for purchase')),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        Investment investment = Investment(
          description: _descController.text,
          amount: double.parse(_amountController.text),
          type: _selectedType,
          productId: _selectedProduct?.id,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

        await _investmentRepo.addInvestment(investment);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Investment added successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'product_purchase':
        return 'Product Purchase';
      case 'expense':
        return 'Expense';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Investment')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Investment Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Investment Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ['product_purchase', 'expense', 'other'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select type';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Product Selection (only for purchase)
              if (_selectedType == 'product_purchase')
                Column(
                  children: [
                    DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      decoration: InputDecoration(
                        labelText: 'Select Product *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_cart),
                      ),
                      items: _products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text(
                            '${product.name} (Stock: ${product.currentQuantity})',
                          ),
                        );
                      }).toList(),
                      onChanged: (product) {
                        setState(() {
                          _selectedProduct = product;
                        });
                      },
                      validator: _selectedType == 'product_purchase'
                          ? (value) {
                              if (value == null) {
                                return 'Please select a product';
                              }
                              return null;
                            }
                          : null,
                    ),
                    SizedBox(height: 16),
                  ],
                ),

              // Description
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'e.g., Purchased 10 iPhones',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (Rs) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                  prefixText: 'Rs ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid amount';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),

              SizedBox(height: 24),

              // Current Date Display
              Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text('Investment Date'),
                  subtitle: Text(DateTime.now().toString().split(' ')[0]),
                  trailing: Icon(Icons.info, color: Colors.grey),
                ),
              ),

              SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveInvestment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'SAVE INVESTMENT',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
