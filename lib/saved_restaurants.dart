import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SavedRestaurantsPage extends StatefulWidget {
  const SavedRestaurantsPage({super.key});

  @override
  State<SavedRestaurantsPage> createState() => _SavedRestaurantsPageState();
}

class _SavedRestaurantsPageState extends State<SavedRestaurantsPage> {
  List<Map<String, dynamic>> _savedRestaurants = [];
  bool _unsavedSomething = false;

  @override
  void initState() {
    super.initState();
    _fetchSavedRestaurants();
  }

  @override
  void dispose() {
    Navigator.pop(context, _unsavedSomething); // Notify ProfilePage
    super.dispose();
  }


  String sanitizeEmail(String email) {
    return email.replaceAll('.', ',');
  }

  Future<void> _fetchSavedRestaurants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = sanitizeEmail(user.email!);
    final ref = FirebaseDatabase.instance.ref("SavedRestaurants/$emailKey");

    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final List<Map<String, dynamic>> temp = [];

      data.forEach((key, value) {
        final restaurant = Map<String, dynamic>.from(value);
        restaurant['firebaseKey'] = key; // Store Firebase key
        temp.add(restaurant);
      });

      setState(() {
        _savedRestaurants = temp;
      });
    }
  }

  Future<void> _removeRestaurant(String firebaseKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _unsavedSomething = true;

    final emailKey = sanitizeEmail(user.email!);
    final ref = FirebaseDatabase.instance.ref("SavedRestaurants/$emailKey/$firebaseKey");

    await ref.remove();

    setState(() {
      _savedRestaurants.removeWhere((r) => r['firebaseKey'] == firebaseKey);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Restaurant removed from saved list")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);  // Send refresh signal
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Restaurants'),
          backgroundColor: Colors.redAccent,
          leading: IconButton(
            icon: Image.asset(
              'assets/back.png',
              width: 28,
              height: 28,
              color: Colors.white, // Optional: remove if your icon already has color
            ),
            onPressed: () {
              Navigator.pop(context); // also works on back button
            }, // NO 'true' here
          ),
        ),
        body: _savedRestaurants.isEmpty
            ? const Center(child: Text("No saved restaurants"))
            : ListView.builder(
          itemCount: _savedRestaurants.length,
          itemBuilder: (context, index) {
            final r = _savedRestaurants[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 4,
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (r['rating'] != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${r['rating']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                    ],
                  ],
                ),

                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    r['address'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),


                trailing: IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.redAccent),
                  onPressed: () => _removeRestaurant(r['firebaseKey']),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
