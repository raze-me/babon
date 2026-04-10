import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helper for WhatsApp~
Future<void> openWhatsApp(String productName, String price, int quantity) async {
  final String phoneNumber = "918707746094";
  final String message = "Hello, I want to place an order:\n\nProduct: $productName\nPrice: $price\nQuantity: $quantity\n\nPlease confirm availability.";
  final String encodedMessage = Uri.encodeComponent(message);
  final Uri url = Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage");

  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not open WhatsApp");
    }
  } catch (e) {
    print("Could not open WhatsApp: $e");
  }
}

Future<void> createOrderAndOpenWhatsApp(BuildContext context, Product product, int quantity) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      }
      return;
  }
  
  try {
     await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Unknown',
        'productName': product.name,
        'productImage': product.imageUrl,
        'price': product.price,
        'quantity': quantity,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
     });
  } catch(e) {
     print('Failed to save order: $e');
  }
  
  await openWhatsApp(product.name, product.price, quantity);
}

Future<void> addToCartInFirestore(BuildContext context, Product product, {int quantity = 1}) async {
  final user = FirebaseAuth.instance.currentUser;
  if(user == null) {
     if(context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to add to cart')));
     }
     return;
  }
  
  try {
     final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart');
     final query = await cartRef.where('productName', isEqualTo: product.name).get();
     
     if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        final int currentQty = query.docs.first.data()['quantity'] ?? 0;
        await cartRef.doc(docId).update({'quantity': currentQty + quantity});
     } else {
        await cartRef.add({
           'productName': product.name,
           'price': product.price,
           'image': product.imageUrl,
           'quantity': quantity,
        });
     }
     
     if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Cart: ${product.name}')));
     }
  } catch(e) {
     print('Failed to add to cart: $e');
     if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add to cart')));
     }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BabalonApp());
}

class BabalonApp extends StatelessWidget {
  const BabalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Babalon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F6D0),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4A442D), 
          onPrimary: Colors.white,
          secondary: Color(0xFF3D3522), 
          onSecondary: Colors.white,
          surface: Colors.white, 
          onSurface: Color(0xFF141301), 
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A442D), 
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF141301)),
          bodyMedium: TextStyle(color: Color(0xFF141301)),
        ),
      ),
      home: const AuthChecker(),
    );
  }
}

class Product {
  final String name;
  final String price;
  final String imageUrl;
  final String category;
  final String unit;
  final String description;

  Product({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.unit = '',
    this.description = '',
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> categories = ['All', 'Cement', 'Steel', 'Bricks', 'Sand'];
  int selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Babalon', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context ).openDrawer();
              },
            );
          }
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context), 
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategories(),
          const SizedBox(height: 8),
          Expanded(
            child: _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF4A442D), 
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFF2F6D0), 
                      backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!) : null,
                      child: FirebaseAuth.instance.currentUser?.photoURL == null ? const Icon(Icons.person, size: 36, color: Color(0xFF141301)) : null,
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 50,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? 'User Module',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (FirebaseAuth.instance.currentUser?.email != null)
                  Text(
                    FirebaseAuth.instance.currentUser!.email!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF141301)),
            title: const Text('Profile', style: TextStyle(color: Color(0xFF141301), fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Color(0xFF141301)),
            title: const Text('My Orders', style: TextStyle(color: Color(0xFF141301), fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF141301)),
            title: const Text('Cart', style: TextStyle(color: Color(0xFF141301), fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
            },
          ),
          const Divider(color: Colors.black12),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Color(0xFF141301)),
            title: const Text('Settings', style: TextStyle(color: Color(0xFF141301), fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          const Divider(color: Colors.black12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context); 
              Navigator.of(context).popUntil((route) => route.isFirst);
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Color(0xFF141301)),
          cursorColor: const Color(0xFF3D3522),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Search materials...',
            hintStyle: TextStyle(color: Colors.black45),
            prefixIcon: Icon(Icons.search, color: Color(0xFF3D3522)), 
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedCategoryIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategoryIndex = index;
                });
              },
              selectedColor: const Color(0xFF4A442D), 
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF141301),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              side: isSelected 
                 ? BorderSide.none 
                 : const BorderSide(color: Colors.black12, width: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4A442D)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Color(0xFF3D3522))));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
             child: Text(
               'No products found.',
               style: TextStyle(color: Color(0xFF3D3522), fontSize: 16),
             ),
          );
        }

        final List<Product> products = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Product(
            name: data['name'] ?? '',
            price: data['price'] ?? '',
            imageUrl: data['image'] ?? '',
            category: data['category'] ?? 'All',
            unit: data['unit'] ?? '',
            description: data['description'] ?? '',
          );
        }).toList();

        final String selectedCategory = categories[selectedCategoryIndex];
        final List<Product> displayedProducts = products.where((p) {
          final matchesCategory = selectedCategory == 'All' || p.category == selectedCategory;
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCategory && matchesSearch;
        }).toList();

        if (displayedProducts.isEmpty) {
           return const Center(
             child: Text(
               'No products found matching your criteria.',
               style: TextStyle(color: Color(0xFF3D3522), fontSize: 16),
             ),
           );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.60, 
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
          ),
          itemCount: displayedProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(displayedProducts[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), 
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  'assets/images/${product.imageUrl}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF4F4F9),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, color: Colors.grey, size: 36),
                          const SizedBox(height: 4),
                          Text(
                            'No Asset', 
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF141301),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.price,
                    style: const TextStyle(
                      color: Color(0xFF3D3522), 
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            createOrderAndOpenWhatsApp(context, product, 1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                          label: const Text(
                            'Order',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add to Cart
                      Expanded(
                        flex: 3,
                        child: OutlinedButton(
                          onPressed: () {
                            addToCartInFirestore(context, product, quantity: 1);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3D3522),
                            side: const BorderSide(color: Color(0xFF3D3522), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.add_shopping_cart, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6D0),
      appBar: AppBar(
        title: Text(widget.product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/images/${widget.product.imageUrl}',
              height: 350,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 350,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, color: Colors.grey, size: 60),
                      const SizedBox(height: 8),
                      Text('Asset Missing', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              },
            ),
            
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6D0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.product.category.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF3D3522),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF141301),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.price,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3D3522),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Quantity Selector
                    Row(
                      children: [
                        const Text(
                          'Quantity:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF141301)),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: () {
                                  if (quantity > 1) {
                                    setState(() => quantity--);
                                  }
                                },
                              ),
                              Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () {
                                  setState(() => quantity++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF141301),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description.isNotEmpty 
                        ? widget.product.description 
                        : 'This high-grade ${widget.product.name} provides exceptional structural durability and reliability across a vast array of building and core masonry projects. It guarantees excellent binding properties alongside strict industrial standard compliance. Recommended heavily for high endurance requirements.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            )
          ]
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () {
                   addToCartInFirestore(context, widget.product, quantity: quantity);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3D3522),
                  side: const BorderSide(color: Color(0xFF3D3522), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                   createOrderAndOpenWhatsApp(context, widget.product, quantity);
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Order Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

 class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _removeItem(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if(user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(docId).delete();
      } catch(e) {
        print('Error removing item: $e');
      }
    }
  }

  Future<void> _clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if(user != null) {
      try {
        final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart');
        final snapshot = await cartRef.get();
        for(final doc in snapshot.docs) {
           await doc.reference.delete();
        }
      } catch(e) {
        print('Error clearing cart: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: const Center(child: Text('Please log in to view cart.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6D0),
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cart',
            onPressed: () => _clearCart(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFF4A442D)));
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error loading cart: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
             return const Center(
               child: Text(
                 'Cart is empty',
                 style: TextStyle(fontSize: 18, color: Color(0xFF4A442D), fontWeight: FontWeight.bold),
               ),
             );
          }

          final cartDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartDocs.length,
            itemBuilder: (context, index) {
              final doc = cartDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final String name = data['productName'] ?? 'Unknown';
              final String price = data['price'] ?? '0';
              final String img = data['image'] ?? '';
              final int qty = data['quantity'] ?? 1;

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/$img',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF141301)),
                  ),
                  subtitle: Text(
                    'Qty: $qty\n$price',
                    style: const TextStyle(color: Color(0xFF3D3522), fontWeight: FontWeight.w600),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    onPressed: () => _removeItem(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please log in to view orders.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6D0),
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFF4A442D)));
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error loading orders: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
             return const Center(
               child: Text(
                 'No orders yet',
                 style: TextStyle(fontSize: 18, color: Color(0xFF4A442D), fontWeight: FontWeight.bold),
               ),
             );
          }

          final orders = snapshot.data!.docs;
          final sortedOrders = orders.toList()..sort((a, b) {
             final aData = a.data() as Map<String, dynamic>;
             final bData = b.data() as Map<String, dynamic>;
             final Timestamp? aTime = aData['timestamp'] as Timestamp?;
             final Timestamp? bTime = bData['timestamp'] as Timestamp?;
             if(aTime == null && bTime == null) return 0;
             if(aTime == null) return 1;
             if(bTime == null) return -1;
             return bTime.compareTo(aTime); 
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              final order = sortedOrders[index].data() as Map<String, dynamic>;
              
              final String pName = order['productName'] ?? 'Unknown';
              final String pPrice = order['price'] ?? '0';
              final int qty = order['quantity'] ?? 1;
              final String status = order['status'] ?? 'pending';
              final String img = order['productImage'] ?? '';
              
              String dateStr = '';
              if (order['timestamp'] != null) {
                 final dt = (order['timestamp'] as Timestamp).toDate();
                 dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/$img',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF141301))),
                            const SizedBox(height: 4),
                            Text('Qty: $qty | $pPrice', style: const TextStyle(color: Color(0xFF3D3522), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6D0),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF4A442D),
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
            ),
            const SizedBox(height: 24),
            _buildProfileCard('Name', user?.displayName ?? 'Not provided', Icons.person_outline),
            const SizedBox(height: 12),
            _buildProfileCard('Phone', user?.phoneNumber ?? 'Not provided', Icons.phone_outlined),
            const SizedBox(height: 12),
            _buildProfileCard('Email', user?.email ?? 'Not provided', Icons.email_outlined),
            const SizedBox(height: 12),
            _buildProfileCard('Address', 'Please update address in settings', Icons.location_on_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3D3522)),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        subtitle: Text(
           value, 
           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF141301))
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6D0),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsWrapper(
             SwitchListTile(
               title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF141301))),
               activeColor: const Color(0xFF4A442D),
               value: isDarkMode,
               onChanged: (val) => setState(() => isDarkMode = val),
             )
          ),
          const SizedBox(height: 12),
          _buildSettingsWrapper(
             SwitchListTile(
               title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF141301))),
               activeColor: const Color(0xFF4A442D),
               value: notifications,
               onChanged: (val) => setState(() => notifications = val),
             )
          ),
          const SizedBox(height: 12),
          _buildSettingsWrapper(
            ListTile(
              title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF141301))),
              trailing: const Text('English', style: TextStyle(color: Colors.black54)),
              onTap: () {},
            )
          ),
          const SizedBox(height: 12),
          _buildSettingsWrapper(
            ListTile(
              title: const Text('About App', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF141301))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
              onTap: () {},
            )
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsWrapper(Widget child) {
     return Container(
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.04),
             blurRadius: 4,
             offset: const Offset(0, 2),
           ),
         ]
       ),
       child: child,
     );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF2F6D0),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF4A442D))),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
       final User? user = userCredential.user;
      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6D0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 16),
              const Text(
                'Babalon',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFF4A442D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Construction Materials On Demand',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF3D3522),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF4A442D))
                  : ElevatedButton.icon(
                      onPressed: signInWithGoogle,
                      icon: const FaIcon(FontAwesomeIcons.google, color: Colors.blueAccent),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF141301),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
