import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'aboutus.dart';
import 'contactus.dart';
import 'home.dart';
import 'login.dart';
import 'msq.dart';
import 'profilepage.dart';
import 'register.dart';
import 'restaurant_detail.dart';
import 'saved_restaurants.dart';
import 'splash_screen.dart';

final ValueNotifier<bool> isDarkMode = ValueNotifier(false);
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final savedDarkMode = prefs.getBool('isDarkMode') ?? false;
  isDarkMode.value = savedDarkMode;
  appLocale.value = const Locale('en');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'FoodieLoc',
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('hi'),
                Locale('mr'),
                Locale('gu'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData.light().copyWith(
                scaffoldBackgroundColor: Colors.white,
                appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
                iconTheme: const IconThemeData(color: Colors.black),
                textTheme: ThemeData.light().textTheme.apply(
                  bodyColor: Colors.black,
                  displayColor: Colors.black,
                ),
              ),
              darkTheme: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
                iconTheme: const IconThemeData(color: Colors.white),
                textTheme: ThemeData.dark().textTheme.apply(
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
              ),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const RootWrapper(), // ⬅️ handles splash + auth check
              routes: {
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
                '/msq': (context) => const MSQScreen(),
                '/home': (context) => const HomeScreen(),
                '/profile': (context) => const ProfilePage(),
                '/contactus': (context) => const ContactUsPage(),
                '/aboutus': (context) => const AboutUsPage(),
                '/savedRestaurants': (context) => const SavedRestaurantsPage(),
                '/restaurantDetail': (context) => const RestaurantDetailPage(restaurant: {}),
              },
            );
          },
        );
      },
    );
  }
}

class RootWrapper extends StatefulWidget {
  const RootWrapper({super.key});

  @override
  State<RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<RootWrapper> {
  bool _isLoading = true;
  Widget _nextPage = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash at least 2s

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final emailKey = user.email!.replaceAll('.', ',');
      final databaseRef = FirebaseDatabase.instance.ref("Profile Data/$emailKey");
      final snapshot = await databaseRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final userLang = data['language'] ?? 'English';
        final langCode = _getLangCode(userLang);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('languageCode', langCode);

        appLocale.value = Locale(langCode);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('languageCode', 'en');
        appLocale.value = const Locale('en');
      }

      _nextPage = const HomeScreen();
    } else {
      _nextPage = const LoginScreen();
    }

    setState(() => _isLoading = false);
  }

  String _getLangCode(String language) {
    switch (language) {
      case 'Hindi':
        return 'hi';
      case 'Marathi':
        return 'mr';
      case 'Gujarati':
        return 'gu';
      default:
        return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const SplashScreen()
        : _nextPage;
  }
}
