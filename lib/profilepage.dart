import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'saved_restaurants.dart';
import 'liked_items.dart';
import 'main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final databaseRef = FirebaseDatabase.instance.ref("Profile Data");

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final street1Controller = TextEditingController();
  final street2Controller = TextEditingController();
  final pincodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();

  String selectedLanguage = "English";
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    fetchUserProfileData();
  }

  String sanitizeEmail(String email) {
    return email.replaceAll('.', ',');
  }

  Future<void> fetchUserProfileData() async {
    if (user == null) return;
    final emailKey = sanitizeEmail(user!.email!);
    final snapshot = await databaseRef.child(emailKey).get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        nameController.text = data['name'] ?? user!.displayName ?? '';
        emailController.text = data['email'] ?? user!.email ?? '';
        _imageUrl = data['photoUrl'] ?? user!.photoURL ?? '';
        selectedLanguage = data['language'] ?? "English";

        street1Controller.text = data['address']?['street1'] ?? '';
        street2Controller.text = data['address']?['street2'] ?? '';
        pincodeController.text = data['address']?['pincode'] ?? '';
        cityController.text = data['address']?['city'] ?? '';
        stateController.text = data['address']?['state'] ?? '';
        countryController.text = data['address']?['country'] ?? '';
      });
    } else {
      setState(() {
        nameController.text = user!.displayName ?? '';
        emailController.text = user!.email ?? '';
        _imageUrl = user!.photoURL ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final imageFile = File(picked.path);
      setState(() {
        _imageFile = imageFile;
      });

      final uploadedUrl = await uploadImageToCloudinary(imageFile);
      if (uploadedUrl != null) {
        await _saveImageUrl(uploadedUrl);
        setState(() {
          _imageUrl = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile photo updated")),
        );
      }
    }
  }


  Future<String?> uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dfmholuey';
    const uploadPreset = 'flutter_upload';

    final mimeType = lookupMimeType(imageFile.path)?.split('/');
    if (mimeType == null) return null;

    final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uploadUrl)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(mimeType[0], mimeType[1]),
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final data = json.decode(res);
      return data['secure_url'];
    } else {
      print("Cloudinary upload failed: \${response.statusCode}");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    String emailKey = sanitizeEmail(user!.email!);
    String? uploadedUrl = _imageFile != null ? await uploadImageToCloudinary(_imageFile!) : _imageUrl;

    await databaseRef.child(emailKey).set({
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "photoUrl": uploadedUrl ?? '',
      "language": selectedLanguage,
      "address": {
        "street1": street1Controller.text.trim(),
        "street2": street2Controller.text.trim(),
        "pincode": pincodeController.text.trim(),
        "city": cityController.text.trim(),
        "state": stateController.text.trim(),
        "country": countryController.text.trim(),
      },
    });

    setState(() {
      _imageUrl = uploadedUrl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)),
    );
  }

  Future<void> _saveImageUrl(String imageUrl) async {
    if (user == null) return;
    final emailKey = sanitizeEmail(user!.email!);
    await databaseRef.child(emailKey).update({
      'photoUrl': imageUrl,
    });
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.redAccent,
            leading: IconButton(
              icon: Image.asset(
                'assets/back.png',
                width: 28,
                height: 28,
                color: Colors.white, // Optional: remove if your icon already has color
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: Image.asset('assets/logout.png', width: 26, height: 26, color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? NetworkImage(_imageUrl!) as ImageProvider
                            : null,
                        child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                            ? const Icon(Icons.camera_alt, size: 30, color: Colors.redAccent)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nameController.text.isEmpty ? AppLocalizations.of(context)!.name : nameController.text,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                                onPressed: _showEditProfileDialog,
                                tooltip: AppLocalizations.of(context)!.editProfile,
                              )
                            ],
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                _buildOptionTile(Icons.location_on, AppLocalizations.of(context)!.address, _showAddressDialog),
                _buildOptionTile(Icons.language, AppLocalizations.of(context)!.language, _showLanguagePicker),
                _buildOptionTile(
                  Icons.favorite,
                  "Liked Dishes",
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LikedItemsPage()),
                  ),
                ),

                // Open saved restaurants from profile
                _buildOptionTile(
                  Icons.bookmark,
                  AppLocalizations.of(context)!.savedRestaurants,
                      () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedRestaurantsPage()),
                    );

                    if (changed == true) {
                      Navigator.pop(context, true); // Notify HomePage of changes
                    }
                  },
                ),

                _buildOptionTile(Icons.info_outline, AppLocalizations.of(context)!.aboutUs, () => Navigator.pushNamed(context, '/aboutus')),
                _buildOptionTile(Icons.email, AppLocalizations.of(context)!.contactUs, () => Navigator.pushNamed(context, '/contactus')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode.value ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.editProfile,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.name,
                      labelStyle: TextStyle(color: isDarkMode.value ? Colors.white70 : Colors.black),
                      filled: true,
                      fillColor: isDarkMode.value ? Colors.grey[850] : Colors.grey[200],
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: emailController,
                    readOnly: true,
                    style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      labelStyle: TextStyle(color: isDarkMode.value ? Colors.white70 : Colors.black),
                      filled: true,
                      fillColor: isDarkMode.value ? Colors.grey[850] : Colors.grey[200],
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      _saveProfile();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save),
                    label: Text(AppLocalizations.of(context)!.saveChanges),
                  )
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: isDarkMode.value ? Colors.white : Colors.black,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.editAddress,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(street1Controller, AppLocalizations.of(context)!.street1),
                    _buildTextField(street2Controller, AppLocalizations.of(context)!.street2),
                    _buildTextField(pincodeController, AppLocalizations.of(context)!.pincode),
                    _buildTextField(cityController, AppLocalizations.of(context)!.city),
                    _buildTextField(stateController, AppLocalizations.of(context)!.state),
                    _buildTextField(countryController, AppLocalizations.of(context)!.country),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        _saveProfile();
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.saveAddress),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () => _setLanguageAndClose('en'),
            ),
            ListTile(
              title: const Text('हिंदी (Hindi)'),
              onTap: () => _setLanguageAndClose('hi'),
            ),
            ListTile(
              title: const Text('मराठी (Marathi)'),
              onTap: () => _setLanguageAndClose('mr'),
            ),
            ListTile(
              title: const Text('ગુજરાતી (Gujarati)'),
              onTap: () => _setLanguageAndClose('gu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setLanguageAndClose(String langCode) async {
    Navigator.pop(context);

    final emailKey = sanitizeEmail(user!.email!);
    await databaseRef.child(emailKey).update({"language": langCode});

    appLocale.value = Locale(langCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
  }
}