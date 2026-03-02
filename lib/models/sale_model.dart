class Sale {
  int? id;
  int productId;
  String productName;
  int quantity;
  double unitPrice;
  double buyingPrice;
  double totalAmount;
  double profit;
  DateTime saleDate;
  String? customerName;
  String? customerPhone;
  String? customerAddress;

  Sale({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.buyingPrice,
    required this.totalAmount,
    required this.profit,
    DateTime? saleDate,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
  }) : saleDate = saleDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'buying_price': buyingPrice,
      'total_amount': totalAmount,
      'profit': profit,
      'sale_date': saleDate.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      buyingPrice: map['buying_price'] ?? 0,
      totalAmount: map['total_amount'],
      profit: map['profit'] ?? 0,
      saleDate: DateTime.parse(map['sale_date']),
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      customerAddress: map['customer_address'],
    );
  }
  double get profitPercentage {
    if (buyingPrice == 0) return 0;
    return ((profit / (buyingPrice * quantity)) * 100);
  }
}
