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
