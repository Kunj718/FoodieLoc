import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                local.welcomeTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                local.welcomeSubtitle,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                local.aboutDescription,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              Text(
                local.featuresTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(local.featuresList),
              const SizedBox(height: 20),
              Text(local.madeWithLove),
            ],
          ),
        ),
      ),
    );
  }
}
