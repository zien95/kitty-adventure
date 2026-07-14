import 'package:flutter/material.dart';



class AdService {
  static bool _isAdFree = true; // Ad-free by default

  static bool get isAdFree => _isAdFree;

  static void setAdFree(bool adFree) {
    _isAdFree = adFree;
  }

  static void showInterstitialAd() {
    // Show interstitial ad between game sessions
    // Only show if not ad-free
    if (!_isAdFree) {
      // TODO: Implement actual ad logic
      // Could use an ad SDK.
    }
  }

  static void showRewardedAd() {
    // Show rewarded ad for extra coins
    if (!_isAdFree) {
      // TODO: Implement actual rewarded ad logic
    }
  }

  static Widget buildBannerAd() {
    // Return banner ad widget or empty container
    if (!_isAdFree) {
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fun icon
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.star,
                color: Color(0xFFFFD700),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            // Ad text
            const Text(
              'More Fun Games!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // CTA button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Play',
                style: TextStyle(
                  color: Color(0xFF764BA2),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  static void loadAds() {
    // Initialize ad SDK
    if (!_isAdFree) {
      // TODO: Initialize ad SDK
    }
  }
}
