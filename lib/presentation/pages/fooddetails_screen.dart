import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:ballast_machn_test/data/models/food_model.dart';
import 'package:ballast_machn_test/data/models/order_details_model.dart';
import 'package:ballast_machn_test/presentation/widgets/drawer.dart';
import '../blocs/tax_type_bloc.dart';
import '../widgets/custom_button.dart';
import '../pages/menu_screen.dart';

class FoodDetailsPage extends StatefulWidget {
  final Food food;
  final String customerName;
  final int table;

  const FoodDetailsPage({
    Key? key,
    required this.food,
    required this.customerName,
    required this.table,
  }) : super(key: key);

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  int _quantity = 1;
  List<Order> orders = [];
  String orderNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchOrderNumber();
  }

  void _incrementQuantity() {
    setState(() {
      if (_quantity < 10) {
        _quantity++;
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  Future<void> _addToMenu() async {
    double subtotal = widget.food.saleAmt * _quantity;
    double amountBeforeTax = subtotal;
    double taxAmount;
    double totalAmount;

    if (context.read<TaxTypeBloc>().state is InclusiveTax) {
      double amountBeforeTaxInclusive =
          amountBeforeTax / (1 + widget.food.tax / 100);
      taxAmount = amountBeforeTax - amountBeforeTaxInclusive;
      totalAmount = amountBeforeTaxInclusive + taxAmount;
    } else {
      taxAmount = amountBeforeTax * widget.food.tax / 100;
      totalAmount = amountBeforeTax + taxAmount;
    }

    final orderDetails = {
      "UserId": 101,
      "UserName": "Counter Sale",
      "CustomerId": 101,
      "CustomerName": widget.customerName,
      "TableName": widget.table,
      "StartDateTime": DateTime.now().toString(),
      "ItemCode": widget.food.codeOrSKU,
      "ItemName": widget.food.pdtName,
      "salePrice": widget.food.saleAmt,
      "Qty": _quantity,
      "TotalsalePrice": subtotal,
      "AmountBeforeTax": amountBeforeTax,
      "GST": widget.food.tax,
      "GSTAmount": taxAmount,
      "TotalAmount": totalAmount,
      "ActiveInnactive": "Active"
    };

    final url = Uri.parse('http://10.0.2.2:3000/api/order-details');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderDetails),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
                '$_quantity ${widget.food.pdtName} added to menu successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to Add'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchOrderNumber() async {
    final url = Uri.parse(
        'http://10.0.2.2:3000/api/orders/${widget.customerName}/${widget.table}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            orderNumber = data[0]['OrderNumber'];
          });
        } else {
          throw Exception('Order not found');
        }
      } else {
        throw Exception('Failed to load order number');
      }
    } catch (e) {
      throw Exception('Error fetching order number: $e');
    }
  }

  Future<void> _fetchOrders() async {
    final url = Uri.parse(
        'http://10.0.2.2:3000/api/orders/${widget.customerName}/${widget.table}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Order> fetchedOrders =
            data.map((json) => Order.fromJson(json)).toList();

        setState(() {
          orders = fetchedOrders;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/bb.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          drawer: const MyDrawer(),
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MenuPage(
                              customerNumber: widget.customerName,
                              table: widget.table.toInt(),
                            )),
                  );
                },
                child: const Icon(Icons.note),
              ),
              const SizedBox(
                width: 10,
              )
            ],
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            title: Text(
              widget.food.pdtName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: SizedBox(
                      height: 300,
                      width: 400,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          widget.food.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.food.pdtName,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '₹ ${widget.food.saleAmt.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 5,
                              padding: const EdgeInsets.all(5),
                              shape: const CircleBorder(),
                            ),
                            onPressed: _decrementQuantity,
                            child: const Icon(Icons.remove),
                          ),
                          SizedBox(
                            width: 25,
                            child: Center(
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 5,
                              padding: const EdgeInsets.all(5),
                              shape: const CircleBorder(),
                            ),
                            onPressed: _incrementQuantity,
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                BlocBuilder<TaxTypeBloc, TaxTypeState>(
                  builder: (context, state) {
                    double subtotal = widget.food.saleAmt * _quantity;
                    double amountBeforeTax = subtotal;
                    double taxAmount;
                    double totalAmount;

                    if (state is InclusiveTax) {
                      double amountBeforeTaxInclusive =
                          amountBeforeTax / (1 + widget.food.tax / 100);
                      taxAmount = amountBeforeTax - amountBeforeTaxInclusive;
                      totalAmount = amountBeforeTaxInclusive + taxAmount;
                    } else {
                      taxAmount = amountBeforeTax * widget.food.tax / 100;
                      totalAmount = amountBeforeTax + taxAmount;
                    }

                    return Card(
                      color: Colors.blue.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      elevation: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        height: 115,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Price ( ${widget.food.saleAmt.toInt()} x $_quantity )',
                                ),
                                const Spacer(),
                                if (state is InclusiveTax)
                                  Text(
                                      '${(widget.food.saleAmt.toInt() * _quantity - taxAmount).toStringAsFixed(3)}')
                                else
                                  Text(
                                      '${widget.food.saleAmt.toInt() * _quantity}'),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Tax'),
                                const Spacer(),
                                Text(
                                  taxAmount.toStringAsFixed(2),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sub-Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹ ${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            child: MyButton(
              onPressed: _addToMenu,
              text: 'Add to Menu',
            ),
          ),
        ),
      ],
    );
  }
}
