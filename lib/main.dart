import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

List<Product> cartItems = [];

Future<void> openWhatsApp(String productName, String price, int quantity) async {
  final String phoneNumber = "918707746094";
  final String message = "Hello, I want to  place an order:\n\nProduct: $productName\nPrice: $price\nQuantity: $quantity\n\nPlease confirm availability.";
  final String encodedMessage = Uri.encodedComponent(message);
  final Uri url = Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage");

  try{
    if(await canLauchUrl(url)){
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }else{
      print("Could not open Whatsapp");
    }
  } catch(e){
    print("Could not open WhatsApp: $e");
  }
}


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);

  runApp(const BablonApp());
} 

class BabalonApp extends StatelessWidget{
  const BabalonApp({super.key});

  @override
  Widget build(BuildContext context){
    return MatrialApp(
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
          backgroundColor: Color(0xFFA442D),
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

 class Product{
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

 class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState => _HomeScreenState();
 }

 class _HomeScreenState extends State<HomeScreen>{
  final List<String> categories = ['All', 'Cement', 'Steel', 'Bricks', 'Sand'];
  int selectedCatrogyIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose(){
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget buiild(BuildContext context){
    retur Scaffold(
      appBar: AppBar(
        title: const Text('Babalon', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        leading: Builder(
          builder: (context){
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: (){
                Scaffold.of(context).openDrawer();
              },
            );
          }
        ),
        action: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: (){
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

  Widget _buildDrawer(BuildContext context){
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const 
            BoxDecoration(
              color: Color(0xFF4A442D),
            ),
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFF2F6D0),
                  backgroundImage: FirebaseAuth.instance.currentUser?.photoURL!=null ? NetworkImage(FirebaseAuth.instance.currentUser?.photoURL == null? const Icon(Icons.person, size: 36, color: Color(0xFF141301)): null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName?? 'User Module',
                    stlye: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if(FirebaseAuth.instance.currentUser?.email != null)
                  Text(
                    FirebaseAuth.instance.currentUser!.email!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF141301)),
            title: const Text('Profile', style: TextStyle(color: Color(0xFF141301), fontWeight: FontWeight.w600)),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF141301)),
            title: const Text('Cart', style: TextStyle(color: Color(0xFF141301), fontWeigth: FontWeight.w600)),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder:(conetxt) => const CartScreen()));
            },
          ),
          const Divider(color: Colors.black12),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Color(0xFF141301)),
            title: const Text('Settings', stlye: TextStyle(color: Color(0xFF141301),
            fontWeight: FontWeight.w600)),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder:(context) => const SettingsScreen()));
            },
          ),
          const Divider(color: Colors.black12),
          ListTile(
            leading: const Icon(Icons.logoutm color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            onTap: () async{
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
              await googleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(){
    return Padding(
      padding: const EdgeInsets.fromLTRB.fromTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Color(0xFF141301)),
          cursorColor: const Color(0xFF3D3522),
          onChanged: (value){
            setState((){
              _searchQuery = value;
            });
          },
          decoration: const InputeDecoration(
            hitText: 'Search materials...',
            hintStyle: TextStyle(color: Colors.black45),
            prefixIcon: Icon(Icons.search, color: Color(0xFF3D3522)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(){
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index == selectedCategoryIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            label: Text(Categories[index]),
            selected: isSelected,
            onSelected: (selected){
              setState((){
                selectedCategoryIndex = index;
              });
            },
            selectedColor: const Color(0xFF4A442D),
            checkmarkColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            labelStyle: TextStyle( 
              color: isSelected ? Colors.white : const Color(0xFF141301),
              fontWeight: isSelected ? FontWeight.bold : FontWeigth.w500,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            side: isSelected
            ? BorderSide.none
            : const BorderSide(color: Colors.black12, width: 1),
          ),
        );
        ),
      ),
    );
  }

  Widget _buildProductGrid(){
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshot(),
      builder: (context, snapshot){
        if(snapshot.connectionState==ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4442D)));
        }
        if(snapshot.hasError){
          returnCenter(child: Text('Error: ${snapshot.error}', style: const TestStyle(color: Color(0xFF3D3522))));
        }
        if (!snapshot.hasData || snpshot.data!.docs.isEmpty){
          return const Center(
            child: Text(
              'No products found.',
              style: TextStyle(color: Color(0xFF3D3522), ;fontSize: 16),
            ),
          );
        }
        final List<Product> products = snapshot.data!.docs.map((dooc){
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
        
        final String selectedCategory = categories[selectedCategoriesIndex];
        final List<Product> displayedProducts = products.where((p){
          final matchesCategory == 'All' || p.category == selectedCategory;
          final matchesSearch = p.name.toLowerCase().contains(_seachQuery.toLowerCase());
          return matchesCategories && matchesSearch;
        }).toList();

        if (displayedProducts.isEmpty){
          retuen const Center(
            child: Text(
              'No products found matching your criteria.',
              style: TextStyle(color: Color(0xFF3D3522), fontSize: 16),
            ),
          );
        }

        return GridView.builder(
          padding: const Edgeinsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SilverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.60,
            crossAxisSpacing: 14, 
            mainAxisSpacing: 16,
          ),
          itemCount: displayedProducts.length,
          itemBuilder: (context, index){
            return  _buildProductCard(displayedProducts[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product){
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builde: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Color.white,
     borderRadius: BorderRadius.circular(16),
     boxShadow:[
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
              'asset/images/${product.imageUrl}',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace){
                return Container(
                  color: const Color(0xFF4F4F9),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, color: Colors.grey, size: 36),
                      const sizedBox(height: 4),
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
            crossAxisAlignment: CrossxisAlignment.start,
            children: {
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
                    flex:6,
                    child: ElevtedButton.icon(
                      onPressed:(){
                        createOrderAndOpenWhatsApp(context, product, 1);
                      },
                      style: ElevatedButton.styleForm(
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
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      onPressed:(){
                        addToCartInFirestore(context, product, quantity: 1);
                      },
                      style: OutlineButton.styleFrom(
                        foregroundColor: const Color(0xFF3D3522),
                        side: const BorderSide(color: Color(0xFF3D3522), widht: 1.5),
                        padding: const EdgeInsets.symmetric(vertical:8, horizontal: 0),
                        shape: RoundedRectangeleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add_shopping_cart, size: 16),
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );
  }
 }


 class ProductDetailScreen extends StatefulWidget{
  final Product product;
  const ProductDetilScreen({super.key, requrired this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
 }

 class_ProductDetailScreenState extends State<ProductDetailScreenState>{
  int quantity = 1;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6D0),
      appBar: AppBar(
        title: Text(widget.product.name, style: const TextStyle(fontsSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SignleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'asset/image/${widget.product.imageUrl}',
              height: 350,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stactTrace){
                return Container(
                  height: 350,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: mainAxisAlignment.center,
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
                decoration: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding const EdgeInsets.all(24.0),
              widht: double.infinity,
              child: Column(
                crossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecortion(
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
                    style: const TextWeight.w900,
                    color: Color(0xFF3D3522),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children:[
                      const Text(
                        'Quantity:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF141301)),
                      ),
                      const SizedBox(widht: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: (){
                                if(quantity>1){
                                  setState(() => quantity--);
                                }
                              },
                            ),
                            Text(
                              quantity.toString(),
                              style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: (){
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
                    : 'This high-grade ${widget.product.name} provides exceptional structural durability and reliability across a vast array of building and core masonry projects. It guarantees excellent binding properties alongside strict industrial standard compliance. Recomended heavily for high endurances requirements.',
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
                onPressed: (){
                  addToCartInFirestore(context, widget.product, quantity);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3D3522),
                  side: const BorderSide(color: Color(0xF3D3522), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (){
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


