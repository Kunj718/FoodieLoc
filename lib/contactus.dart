import 'package:flutter/material.dart';
import 'main.dart'; // for isDarkMode notifier
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            title: const Text('Contact Us'),
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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(local.contactAppName, local.contactAppNameDesc, isDark),
                    _buildSection(local.contactTagline, local.contactTaglineDesc, isDark),
                    _buildSection(local.contactDescription, "", isDark),
                    _buildSection(local.contactMission, local.contactMissionDesc, isDark),
                    _buildSection(local.contactFeatures, local.contactFeaturesList, isDark),
                    _buildSection(local.contactTeam, local.contactTeamDesc, isDark),
                    _buildSection(local.contactEmail, local.contactEmailDesc, isDark),
                    _buildSection(local.contactPrivacy, local.contactPrivacyDesc, isDark),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
