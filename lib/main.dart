import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FoodCrushApp());
}

class Product {
  String id;
  String name;
  String category;
  double price;
  bool active;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'active': active,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'].toString(),
      category: json['category'].toString(),
      price: (json['price'] as num).toDouble(),
      active: json['active'] as bool? ?? true,
    );
  }
}

class CartItem {
  final Product product;
  int qty;

  CartItem(this.product, this.qty);

  double get total => product.price * qty;
}

class BillItem {
  final String name;
  final double price;
  final int qty;

  BillItem({
    required this.name,
    required this.price,
    required this.qty,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'qty': qty,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['name'].toString(),
      price: (json['price'] as num).toDouble(),
      qty: (json['qty'] as num).toInt(),
    );
  }
}

class Bill {
  final String id;
  final DateTime date;
  final String customer;
  final String mobile;
  final String address;
  final String payment;
  final List<BillItem> items;
  final double total;

  Bill({
    required this.id,
    required this.date,
    required this.customer,
    required this.mobile,
    required this.address,
    required this.payment,
    required this.items,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'customer': customer,
        'mobile': mobile,
        'address': address,
        'payment': payment,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
      };

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'].toString(),
      date: DateTime.parse(json['date'].toString()),
      customer: json['customer'].toString(),
      mobile: json['mobile'].toString(),
      address: json['address'].toString(),
      payment: json['payment'].toString(),
      items: (json['items'] as List)
          .map((e) => BillItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class AppStore extends ChangeNotifier {
  List<Product> products = [];
  List<Bill> bills = [];
  bool shopOpen = true;

  static const productsKey = 'products';
  static const billsKey = 'bills';
  static const shopKey = 'shop_open';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final productData = prefs.getString(productsKey);
    final billData = prefs.getString(billsKey);

    if (productData == null) {
      products = [
        Product(id: '1', name: 'Veg Sandwich', category: 'Sandwich', price: 60),
        Product(id: '2', name: 'Cheese Sandwich', category: 'Sandwich', price: 80),
        Product(id: '3', name: 'Masala Dosa', category: 'Dosa', price: 70),
        Product(id: '4', name: 'Cheese Dosa', category: 'Dosa', price: 100),
        Product(id: '5', name: 'Vada Pav', category: 'Fast Food', price: 30),
        Product(id: '6', name: 'Dabeli', category: 'Fast Food', price: 35),
        Product(id: '7', name: 'Pav Bhaji', category: 'Fast Food', price: 80),
        Product(id: '8', name: 'Veg Noodles', category: 'Chinese', price: 90),
        Product(id: '9', name: 'Manchurian', category: 'Chinese', price: 100),
        Product(id: '10', name: 'Cold Coffee', category: 'Drinks', price: 70),
      ];
    } else {
      final list = jsonDecode(productData) as List;
      products = list
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (billData != null) {
      final list = jsonDecode(billData) as List;
      bills = list
          .map((e) => Bill.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    shopOpen = prefs.getBool(shopKey) ?? true;
    notifyListeners();
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      productsKey,
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveBills() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      billsKey,
      jsonEncode(bills.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveShop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(shopKey, shopOpen);
  }

  Future<void> addProduct(Product product) async {
    products.add(product);
    await saveProducts();
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    final index = products.indexWhere((e) => e.id == product.id);
    if (index != -1) {
      products[index] = product;
      await saveProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(Product product) async {
    products.removeWhere((e) => e.id == product.id);
    await saveProducts();
    notifyListeners();
  }

  Future<void> addBill(Bill bill) async {
    bills.insert(0, bill);
    await saveBills();
    notifyListeners();
  }

  Future<void> toggleShop() async {
    shopOpen = !shopOpen;
    await saveShop();
    notifyListeners();
  }
}

final store = AppStore();

class FoodCrushApp extends StatefulWidget {
  const FoodCrushApp({super.key});

  @override
  State<FoodCrushApp> createState() => _FoodCrushAppState();
}

class _FoodCrushAppState extends State<FoodCrushApp> {
  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'The Food Crush Billing',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.amber,
            scaffoldBackgroundColor: const Color(0xfff8f8f8),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
    BillingPage(),
    BillsPage(),
    ProductsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Items',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final searchController = TextEditingController();
  final Map<String, CartItem> cart = {};
  String category = 'All';

  List<String> get categories {
    final values = store.products.map((e) => e.category).toSet().toList();
    return ['All', ...values];
  }

  List<Product> get filteredProducts {
    final query = searchController.text.toLowerCase();

    return store.products.where((product) {
      final matchCategory =
          category == 'All' || product.category == category;
      final matchSearch =
          product.name.toLowerCase().contains(query);

      return product.active && matchCategory && matchSearch;
    }).toList();
  }

  int get totalItems {
    return cart.values.fold(0, (sum, item) => sum + item.qty);
  }

  double get total {
    return cart.values.fold(0, (sum, item) => sum + item.total);
  }

  void add(Product product) {
    setState(() {
      if (cart.containsKey(product.id)) {
        cart[product.id]!.qty++;
      } else {
        cart[product.id] = CartItem(product, 1);
      }
    });
  }

  void remove(Product product) {
    setState(() {
      if (!cart.containsKey(product.id)) return;

      cart[product.id]!.qty--;

      if (cart[product.id]!.qty <= 0) {
        cart.remove(product.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'The Food Crush',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                store.shopOpen ? Icons.circle : Icons.circle_outlined,
                size: 14,
                color: store.shopOpen ? Colors.green : Colors.red,
              ),
              label: Text(store.shopOpen ? 'OPEN' : 'CLOSED'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search item...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: categories.map((item) {
                final selected = category == item;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => category = item);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('No items found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, i) {
                      final product = filteredProducts[i];
                      final qty = cart[product.id]?.qty ?? 0;

                      return Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  if (qty > 0)
                                    IconButton(
                                      onPressed: () => remove(product),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                  if (qty > 0)
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: () => add(product),
                                    icon: const Icon(
                                      Icons.add_circle,
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
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CheckoutSheet(
                        items: cart.values.toList(),
                        total: total,
                        onDone: () {
                          setState(() => cart.clear());
                        },
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'VIEW BILL • $totalItems items • ₹${total.toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class CheckoutSheet extends StatefulWidget {
  final List<CartItem> items;
  final double total;
  final VoidCallback onDone;

  const CheckoutSheet({
    super.key,
    required this.items,
    required this.total,
    required this.onDone,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();

  String payment = 'Cash';

  Future<void> createBill() async {
    final bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      customer: nameController.text.trim().isEmpty
          ? 'Walk-in Customer'
          : nameController.text.trim(),
      mobile: mobileController.text.trim(),
      address: addressController.text.trim(),
      payment: payment,
      items: widget.items
          .map(
            (e) => BillItem(
              name: e.product.name,
              price: e.product.price,
              qty: e.qty,
            ),
          )
          .toList(),
      total: widget.total,
    );

    await store.addBill(bill);

    if (!mounted) return;

    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillPreviewPage(bill: bill),
      ),
    );

    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customer & Payment',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Customer name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Payment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Cash', 'UPI', 'Card'].map((item) {
                return ChoiceChip(
                  label: Text(item),
                  selected: payment == item,
                  onSelected: (_) {
                    setState(() => payment = item);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: createBill,
              child: Text(
                'CREATE BILL • ₹${widget.total.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class BillPreviewPage extends StatefulWidget {
  final Bill bill;

  const BillPreviewPage({
    super.key,
    required this.bill,
  });

  @override
  State<BillPreviewPage> createState() => _BillPreviewPageState();
}

class _BillPreviewPageState extends State<BillPreviewPage> {
  final boundaryKey = GlobalKey();

  Future<Uint8List> captureBill() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> saveGallery() async {
    try {
      final bytes = await captureBill();

      bool access = await Gal.hasAccess(toAlbum: true);

      if (!access) {
        access = await Gal.requestAccess(toAlbum: true);
      }

      if (!access) {
        throw Exception('Gallery permission denied');
      }

      await Gal.putImageBytes(
        bytes,
        album: 'The Food Crush',
        name: 'bill_${widget.bill.id}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill Gallery me save ho gaya ✅'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> shareBill() async {
    try {
      final bytes = await captureBill();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'The_Food_Crush_Bill.png',
              mimeType: 'image/png',
            ),
          ],
          text: 'The Food Crush Bill',
          subject: 'The Food Crush Bill',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            RepaintBoundary(
              key: boundaryKey,
              child: Container(
                width: 380,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'THE FOOD CRUSH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'FOOD • TASTE • MOOD',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    ),
                    const Divider(height: 25),
                    Text('Bill No: ${bill.id}'),
                    Text(
                      'Date: ${bill.date.day.toString().padLeft(2, '0')}-'
                      '${bill.date.month.toString().padLeft(2, '0')}-'
                      '${bill.date.year}',
                    ),
                    const SizedBox(height: 10),
                    Text('Customer: ${bill.customer}'),
                    if (bill.mobile.isNotEmpty)
                      Text('Mobile: ${bill.mobile}'),
                    if (bill.address.isNotEmpty)
                      Text('Address: ${bill.address}'),
                    const Divider(height: 25),
                    ...bill.items.map(
                      (item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} x${item.qty}',
                              ),
                            ),
                            Text(
                              '₹${(item.price * item.qty).toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 25),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        Text(
                          '₹${bill.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment: ${bill.payment}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Thank you! Visit again ❤️',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: saveGallery,
                    icon: const Icon(Icons.download),
                    label: const Text('Save Gallery'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: shareBill,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  String dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bills History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: store.bills.isEmpty
          ? const Center(
              child: Text('Abhi koi bill nahi hai'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: store.bills.length,
              itemBuilder: (context, index) {
                final bill = store.bills[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt),
                    ),
                    title: Text(
                      bill.customer,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${dateText(bill.date)} • ${bill.payment}',
                    ),
                    trailing: Text(
                      '₹${bill.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BillPreviewPage(bill: bill),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  Future<void> addOrEdit({Product? product}) async {
    final nameController =
        TextEditingController(text: product?.name ?? '');

    final priceController = TextEditingController(
      text: product == null
          ? ''
          : product.price.toStringAsFixed(0),
    );

    final categoryController =
        TextEditingController(text: product?.category ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Item' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                  ),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final category =
                    categoryController.text.trim();
                final price =
                    double.tryParse(priceController.text.trim());

                if (name.isEmpty ||
                    category.isEmpty ||
                    price == null) {
                  return;
                }

                if (product == null) {
                  await store.addProduct(
                    Product(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: name,
                      category: category,
                      price: price,
                    ),
                  );
                } else {
                  product.name = name;
                  product.category = category;
                  product.price = price;
                  await store.updateProduct(product);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Items',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: store.products.length,
        itemBuilder: (context, index) {
          final product = store.products[index];

          return Card(
            child: ListTile(
              title: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle:
                  Text('${product.category} • ₹${product.price}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: product.active,
                    onChanged: (value) async {
                      product.active = value;
                      await store.updateProduct(product);
                    },
                  ),
                  IconButton(
                    onPressed: () => addOrEdit(product: product),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      await store.deleteProduct(product);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Shop Open'),
            subtitle: Text(
              store.shopOpen
                  ? 'Billing system is active'
                  : 'Shop is closed',
            ),
            value: store.shopOpen,
            onChanged: (_) {
              store.toggleShop();
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.store),
            title: Text('The Food Crush'),
            subtitle: Text('Offline Billing System'),
          ),
          const ListTile(
            leading: Icon(Icons.photo),
            title: Text('Bill Images'),
            subtitle: Text(
              'Bills Gallery me save karke share kiye ja sakte hain.',
            ),
          ),
        ],
      ),
    );
  }
}