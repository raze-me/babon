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

  

 }
