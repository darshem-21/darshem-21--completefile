import 'package:flutter/material.dart';
import 'package:farmmarket/services/supabase_service.dart';
import 'package:farmmarket/services/whatsapp_service.dart';

/// Admin view: lists all users with a small white location icon and name/location.
class UsersMapPage extends StatelessWidget {
  const UsersMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Locations'),
      ),
      backgroundColor: Colors.green,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.streamProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading users',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          final profiles = snapshot.data ?? const [];
          if (profiles.isEmpty) {
            return const Center(
              child: Text(
                'No users found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final p = profiles[index];
              final name = (p['name'] ?? p['email'] ?? 'User').toString();
              final address = (p['address'] ?? '').toString();
              final phone = (p['phone'] ?? '').toString().trim();
              final locationText = address.isNotEmpty ? address : 'Location not set';

              return Container
              (
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locationText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                      tooltip: 'Chat via WhatsApp',
                      onPressed: phone.isEmpty
                          ? null
                          : () async {
                              try {
                                await WhatsAppService.openWhatsApp(
                                  phone,
                                  message:
                                      'Hi $name, this is the FarmMarket team. We would like to contact you regarding your account.',
                                );
                              } catch (_) {
                                // Silent failure; in UI it will just not open WhatsApp
                              }
                            },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
