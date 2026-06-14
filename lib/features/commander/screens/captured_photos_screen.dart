import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CapturedPhotosScreen extends StatelessWidget {
  final String deviceId;
  const CapturedPhotosScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseService().firestore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto Kamera Depan'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF0F172A)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('devices')
              .doc(deviceId)
              .collection('photos')
              .orderBy('capturedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada foto yang diambil.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final url = data['url'] as String;
                final capturedAtStr = data['capturedAt'] as String;
                final capturedAt = DateTime.parse(capturedAtStr);

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Show full screen image
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImage(url: url),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.withOpacity(0.1),
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${capturedAt.day}/${capturedAt.month} ${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String url;
  const FullScreenImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}
