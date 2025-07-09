import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LikedItemsPage extends StatefulWidget {
  const LikedItemsPage({super.key});

  @override
  State<LikedItemsPage> createState() => _LikedItemsPageState();
}

class _LikedItemsPageState extends State<LikedItemsPage> {
  List<MapEntry<String, String>> likedDishes = []; // (firebaseKey, dishName)

  @override
  void initState() {
    super.initState();
    fetchLikedDishes();
  }

  Future<void> fetchLikedDishes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("LikedDishes/$emailKey");

    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        likedDishes = data.entries
            .map((entry) => MapEntry(entry.key, entry.value.toString()))
            .toList();
      });
    }
  }

  Future<void> removeLikedDish(String firebaseKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("LikedDishes/$emailKey/$firebaseKey");

    await ref.remove();
    setState(() {
      likedDishes.removeWhere((entry) => entry.key == firebaseKey);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dish removed from liked items")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: Image.asset(
            'assets/back.png',
            width: 28,
            height: 28,
            color: Colors.white, // Optional: only if you want it white
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Liked Dishes"),
      ),

      body: likedDishes.isEmpty
          ? const Center(child: Text("No liked dishes yet"))
          : ListView.builder(
        itemCount: likedDishes.length,
        itemBuilder: (context, index) {
          final entry = likedDishes[index];
          return ListTile(
            leading: GestureDetector(
              onTap: () => removeLikedDish(entry.key),
              child: const Icon(Icons.favorite, color: Colors.pink), // ✅ Only icon
            ),
            title: Text(entry.value),
          );
        },
      ),
    );
  }
}
