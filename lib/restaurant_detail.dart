import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final name = restaurant['name'] ?? 'Restaurant';
    final rating = restaurant['rating']?.toString() ?? '-';
    final reviews = restaurant['user_ratings_total']?.toString() ?? '0';
    final address = restaurant['address'] ?? '';
    final lat = restaurant['lat'];
    final lng = restaurant['lng'];
    final photoUrl = restaurant['photoUrl'];
    final openingHours = restaurant['opening_hours'];
    final website = restaurant['website'];
    final phone = restaurant['phone'];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Photo ───
            if (photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
              ),

            const SizedBox(height: 20),

            // ─── Name ───
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            // ─── Rating & Reviews ───
            Row(
              children: [
                Text('$rating ★', style: const TextStyle(fontSize: 16, color: Colors.orange)),
                const SizedBox(width: 10),
                Text('$reviews reviews', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 12),

            // ─── Address ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(address, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── Opening Hours ───
            if (openingHours != null && openingHours['weekday_text'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Opening Hours", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...List<Widget>.from(
                    (openingHours['weekday_text'] as List)
                        .map((day) => Text("• $day", style: const TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // ─── Website ───
            if (website != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.link, size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(website);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text(
                        website,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),


            const SizedBox(height: 10),

            // ─── Phone ───
            if (phone != null)
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      final phoneUrl = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(phoneUrl)) {
                        await launchUrl(phoneUrl);
                      }
                    },
                    child: Text(
                      phone,
                      style: const TextStyle(color: Colors.green, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // ─── Direction & Share Buttons ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    if (lat != null && lng != null) {
                      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Couldn't open Google Maps")),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text("Direction", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                    Share.share("Check out $name at $address:\n$url");
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text("Share", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
