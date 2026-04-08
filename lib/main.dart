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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BabalonApp());
}

class BabalonApp extends StatelessWidget{
  const BablonApp({super.key});

  @override
  Widget build(BuildContext context){
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
          onSecondary: Color.white,
          surface: Colors.white,
          onSurface: Color(0xFF141301),
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final List<String> categories = ['All', 'Cement', 'Steel', 'Bricks', 'Sand'];
  int selectedCategoryIndex = 0;

  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Babalon')),
      body: Column(
        children:[
          _buildSearchBar(),
          _buildCategories(),
          Expand(child: _buildProductGrid()),
        ],
      ),
    );
  }
}
