import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:foodie_loc/restaurant_detail.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'main.dart'; // For isDarkMode

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _dishSearchController = TextEditingController();
  String? profilePhotoUrl;
  String? _selectedCity;
  bool _showCitySearch = false;
  List<String> cityList = [];
  List<Map<String, dynamic>> restaurants = [];
  Set<String> _savedRestaurantNames = {};
  List<String> dishList = [];
  Set<String> likedDishes = {};

  String? _extractPhotoUrl(Map place) {
    if (place['photos'] != null && place['photos'].isNotEmpty) {
      final ref = place['photos'][0]['photo_reference'];
      return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$ref&key=AIzaSyDkJpegqjFb1Fa3VU3duPxraoL5aGxH7DI';
    }
    return null;
  }

  Future<void> loadDishes() async {
    final jsonString = await DefaultAssetBundle.of(context).loadString('assets/dishes.json');
    final List<dynamic> data = json.decode(jsonString);
    setState(() => dishList = data.cast<String>());
  }

  Future<void> loadLikedDishes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("LikedDishes/$emailKey");

    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        likedDishes = data.values.map((e) => e.toString()).toSet();
      });
    }
  }


  Future<void> toggleLike(String dishName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("LikedDishes/$emailKey");

    if (likedDishes.contains(dishName)) {
      likedDishes.remove(dishName);
    } else {
      likedDishes.add(dishName);
    }

    await ref.set(likedDishes.toList());
    setState(() {}); // Refresh UI
  }


  @override
  void initState() {
    super.initState();
    fetchProfilePhoto();
    loadCities();
    loadSavedCityFromFirebase();
    loadThemeFromFirebase();
    _loadUserLanguage();
    _loadSavedRestaurantNames();
    loadDishes();
    loadLikedDishes();
  }

  Future<void> _loadUserLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final emailKey = user.email!.replaceAll('.', ',');
    final langRef = FirebaseDatabase.instance.ref('Users/$emailKey/language');
    final snapshot = await langRef.get();
    final langCode = snapshot.value?.toString() ?? 'en';
    appLocale.value = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
  }

  Future<void> fetchProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final emailKey = user.email!.replaceAll('.', ',');
    final databaseRef = FirebaseDatabase.instance.ref("Profile Data/$emailKey");
    final snapshot = await databaseRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() => profilePhotoUrl = data['photoUrl']);
    }
  }

  Future<void> loadCities() async {
    final jsonString = await DefaultAssetBundle.of(context).loadString('assets/cities.json');
    final List<dynamic> data = jsonDecode(jsonString);
    setState(() => cityList = data.cast<String>());
  }

  Future<void> loadSavedCityFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("Location/$emailKey");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() => _selectedCity = data["city"]);
    }
  }

  Future<void> saveCityToFirebase(String city) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("Location/$emailKey");
    await ref.set({"city": city});
  }

  void _toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final emailKey = user.email!.replaceAll('.', ',');
      final ref = FirebaseDatabase.instance.ref("Theme/$emailKey");
      await ref.set({"isDark": isDarkMode.value});
    }
  }

  Future<void> loadThemeFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final emailKey = user.email!.replaceAll('.', ',');
      final ref = FirebaseDatabase.instance.ref("Theme/$emailKey");
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        isDarkMode.value = data["isDark"] ?? false;
      }
    }
  }

  Future<Map<String, double>?> getLatLngFromCity(String city, String apiKey) async {
    final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=$city&key=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return {'lat': location['lat'], 'lng': location['lng']};
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchRestaurants({
    required double lat,
    required double lng,
    required String keyword,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=$lat,$lng&radius=4000&keyword=$keyword&minprice=0&maxprice=2'
          '&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return (data['results'] as List)
            .where((place) =>
        place['rating'] != null &&
            (place['rating'] as num).toDouble() >= 3.0) // ✅ only rating >= 3.0
            .map((place) {
          return {
            'name': place['name'],
            'rating': place['rating'],
            'address': place['vicinity'],
            'lat': place['geometry']['location']['lat'],
            'lng': place['geometry']['location']['lng'],
            'photoUrl': _extractPhotoUrl(place),
            'user_ratings_total': place['user_ratings_total'],
            'place_id': place['place_id'],
          };
        }).toList();
      }
    }
    return [];
  }


  Future<void> _handleSearch() async {
    final city = _selectedCity;
    final dish = _dishSearchController.text.trim();
    const apiKey = 'AIzaSyDkJpegqjFb1Fa3VU3duPxraoL5aGxH7DI'; // Replace with your real key

    if (city == null || dish.isEmpty) return;

    final coords = await getLatLngFromCity(city, apiKey);
    if (coords == null) return;

    final results = await fetchRestaurants(
      lat: coords['lat']!,
      lng: coords['lng']!,
      keyword: dish,
      apiKey: apiKey,
    );

    setState(() => restaurants = results);
  }

  Future<void> _loadSavedRestaurantNames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("SavedRestaurants/$emailKey");

    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _savedRestaurantNames = data.values
            .map((r) => (r as Map)['name']?.toString())
            .where((name) => name != null)
            .cast<String>()
            .toSet();
      });
    } else {
      setState(() {
        _savedRestaurantNames.clear();
      });
    }
  }

  Future<void> saveRestaurant(Map<String, dynamic> restaurant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = user.email!.replaceAll('.', ',');
    final ref = FirebaseDatabase.instance.ref("SavedRestaurants/$emailKey");

    await ref.push().set({
      'name': restaurant['name'],
      'rating': restaurant['rating'],
      'address': restaurant['address'],
      'lat': restaurant['lat'],
      'lng': restaurant['lng'],
      'timestamp': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Restaurant saved!")),
    );
  }

  Future<Map<String, dynamic>> fetchRestaurantDetails(String placeId, String apiKey) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_phone_number,website,opening_hours&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final result = data['result'];
        return {
          'phone': result['formatted_phone_number'],
          'website': result['website'],
          'opening_hours': result['opening_hours'],
        };
      }
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 30),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _showCitySearch = !_showCitySearch),
                        child: Row(
                          children: [
                            Text(
                              _selectedCity ?? "Select City",
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                            ),
                            AnimatedRotation(
                              turns: _showCitySearch ? 0.5 : 0.0, // 0.5 turn = 180 degrees
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      IconButton(
                        icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                            color: isDark ? Colors.white : Colors.black, size: 28),
                        onPressed: _toggleTheme,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/profile').then((refresh) {
                            if (refresh == true) {
                              _loadSavedRestaurantNames(); // Refresh saved icon state
                            }
                          });
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage: profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                              ? NetworkImage(profilePhotoUrl!)
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                      ),
                    ],
                  ),

                  // City Search Dropdown
                  if (_showCitySearch)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Autocomplete<String>(
                        optionsBuilder: (text) {
                          return cityList.where((city) =>
                              city.toLowerCase().startsWith(text.text.toLowerCase()));
                        },
                        onSelected: (String selection) {
                          saveCityToFirebase(selection);
                          setState(() {
                            _selectedCity = selection;
                            _showCitySearch = false;
                          });
                        },
                        fieldViewBuilder: (context, controller, node, onComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: node,
                            onEditingComplete: onComplete,
                            decoration: InputDecoration(
                              hintText: 'Search city...',
                              filled: true,
                              fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height:10),

                  // Dish Search + Button Row
                  Row(
                    children: [
                      Expanded(
                        child: Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                              return dishList.where((dish) => dish.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (String selection) {
                              _dishSearchController.text = selection;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                autofocus: false,
                                onEditingComplete: onEditingComplete,
                                decoration: InputDecoration(
                                  hintText: 'Search for dishes (e.g. dosa)',
                                  filled: true,
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      likedDishes.contains(controller.text.trim())
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.pink,
                                    ),
                                      onPressed: () async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        final dish = controller.text.trim();
                                        final emailKey = user.email!.replaceAll('.', ',');
                                        final ref = FirebaseDatabase.instance.ref("LikedDishes/$emailKey");

                                        if (dish.isNotEmpty) {
                                          setState(() {
                                            if (likedDishes.contains(dish)) {
                                              likedDishes.remove(dish);
                                              ref.orderByValue().equalTo(dish).once().then((snapshot) {
                                                final data = snapshot.snapshot.value as Map?;
                                                data?.forEach((key, value) {
                                                  if (value == dish) ref.child(key).remove();
                                                });
                                              });
                                            } else {
                                              likedDishes.add(dish);
                                              ref.push().set(dish);
                                            }
                                          });
                                        }
                                      }

                                  ),
                                  fillColor: isDarkMode.value ? Colors.grey[850] : Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                ),
                                style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black),
                              );
                            },


                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _handleSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Search"), // ← Changed text here
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Restaurant Results
                  Expanded(
                    child: restaurants.isEmpty
                        ? Center(
                        child: Text("No restaurants yet",
                            style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87)))
                        : ListView.builder(
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurants[index];

                        return GestureDetector(
                          onTap: () async {
                            const apiKey = 'AIzaSyDkJpegqjFb1Fa3VU3duPxraoL5aGxH7DI'; // Replace with real key
                            final placeId = restaurant['place_id'];

                            final details = await fetchRestaurantDetails(placeId, apiKey);

                            final enrichedRestaurant = {
                              ...restaurant,
                              ...details, // Add website, phone, opening_hours
                            };

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailPage(restaurant: enrichedRestaurant),
                              ),
                            );
                          },

                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ─── Image ───
                                  if (restaurant['photoUrl'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        restaurant['photoUrl'],
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                  const SizedBox(height: 12),

                                  // ─── Name & Rating ───
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          restaurant['name'] ?? '',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  restaurant['rating']?.toString() ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                const SizedBox(width: 2),
                                                const Icon(Icons.star, size: 14, color: Colors.white),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${restaurant['user_ratings_total'] ?? 0} reviews',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // ─── Address ───
                                  Text(
                                    restaurant['address'] != null && restaurant['address'].toString().trim().isNotEmpty
                                        ? restaurant['address']
                                        : 'No address available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: DefaultTextStyle.of(context).style.color, // ✅ more reliable across themes
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 12),

                                  // ─── Buttons ───
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // ─── Direction ───
                                      IconButton(
                                        icon: const Icon(Icons.directions, color: Colors.blue, size: 38),
                                        onPressed: () async {
                                          final lat = restaurant['lat'];
                                          final lng = restaurant['lng'];
                                          if (lat != null && lng != null) {
                                            final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                            try {
                                              await launchUrl(url, mode: LaunchMode.externalApplication);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Couldn't open Google Maps")),
                                              );
                                            }
                                          }
                                        },
                                      ),

                                      // ─── Share ───
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.green, size: 38),
                                        onPressed: () {
                                          final name = restaurant['name'];
                                          final address = restaurant['address'];
                                          final lat = restaurant['lat'];
                                          final lng = restaurant['lng'];
                                          final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                          Share.share("Check out $name at $address:\n$url");
                                        },
                                      ),

                                      // ─── Save / Unsave ───
                                      IconButton(
                                        icon: Icon(
                                          _savedRestaurantNames.contains(restaurant['name'])
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: Colors.deepPurple,
                                            size: 38
                                        ),
                                        onPressed: () async {
                                          final user = FirebaseAuth.instance.currentUser;
                                          if (user == null) return;

                                          final emailKey = user.email!.replaceAll('.', ',');
                                          final ref = FirebaseDatabase.instance.ref("SavedRestaurants/$emailKey");
                                          final name = restaurant['name'];

                                          if (_savedRestaurantNames.contains(name)) {
                                            final snapshot = await ref.get();
                                            if (snapshot.exists) {
                                              final data = snapshot.value as Map;
                                              for (final entry in data.entries) {
                                                final value = entry.value as Map;
                                                if (value['name'] == name) {
                                                  await ref.child(entry.key).remove();
                                                  break;
                                                }
                                              }
                                            }
                                            setState(() => _savedRestaurantNames.remove(name));
                                          } else {
                                            await ref.push().set({
                                              'name': name,
                                              'rating': restaurant['rating'],
                                              'address': restaurant['address'],
                                              'lat': restaurant['lat'],
                                              'lng': restaurant['lng'],
                                              'timestamp': DateTime.now().toIso8601String(),
                                            });
                                            setState(() => _savedRestaurantNames.add(name));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
