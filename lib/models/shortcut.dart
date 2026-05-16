import 'package:flutter/material.dart';

class AppShortcut {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String androidPackage;
  final String webFallbackUrl;
  final bool enabled;

  const AppShortcut({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.androidPackage,
    required this.webFallbackUrl,
    this.enabled = false,
  });

  AppShortcut copyWith({bool? enabled}) => AppShortcut(
        id: id,
        name: name,
        description: description,
        icon: icon,
        color: color,
        androidPackage: androidPackage,
        webFallbackUrl: webFallbackUrl,
        enabled: enabled ?? this.enabled,
      );
}

const List<AppShortcut> kDefaultShortcuts = [
  AppShortcut(
    id: 'whatsapp',
    name: 'WhatsApp',
    description: 'Messagerie & appels',
    icon: Icons.chat_bubble_rounded,
    color: Color(0xFF25D366),
    androidPackage: 'com.whatsapp',
    webFallbackUrl: 'https://web.whatsapp.com',
  ),
  AppShortcut(
    id: 'youtube',
    name: 'YouTube',
    description: 'Vidéos en ligne',
    icon: Icons.play_circle_filled,
    color: Color(0xFFFF0000),
    androidPackage: 'com.google.android.youtube',
    webFallbackUrl: 'https://www.youtube.com',
  ),
  AppShortcut(
    id: 'youtubemusic',
    name: 'YouTube Music',
    description: 'Musique YouTube',
    icon: Icons.music_note_rounded,
    color: Color(0xFFFF0000),
    androidPackage: 'com.google.android.apps.youtube.music',
    webFallbackUrl: 'https://music.youtube.com',
  ),
  AppShortcut(
    id: 'netflix',
    name: 'Netflix',
    description: 'Streaming films & séries',
    icon: Icons.local_movies_rounded,
    color: Color(0xFFE50914),
    androidPackage: 'com.netflix.mediaclient',
    webFallbackUrl: 'https://www.netflix.com',
  ),
  AppShortcut(
    id: 'twitch',
    name: 'Twitch',
    description: 'Streaming & gaming',
    icon: Icons.live_tv_rounded,
    color: Color(0xFF9146FF),
    androidPackage: 'tv.twitch.android.app',
    webFallbackUrl: 'https://www.twitch.tv',
  ),
  AppShortcut(
    id: 'claude',
    name: 'Claude AI',
    description: 'Assistant IA Anthropic',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFDA7756),
    androidPackage: 'com.anthropic.claude',
    webFallbackUrl: 'https://claude.ai',
  ),
  AppShortcut(
    id: 'spotify',
    name: 'Spotify',
    description: 'Musique en streaming',
    icon: Icons.headphones_rounded,
    color: Color(0xFF1DB954),
    androidPackage: 'com.spotify.music',
    webFallbackUrl: 'https://open.spotify.com',
  ),
  AppShortcut(
    id: 'discord',
    name: 'Discord',
    description: 'Chat & communautés',
    icon: Icons.forum_rounded,
    color: Color(0xFF5865F2),
    androidPackage: 'com.discord',
    webFallbackUrl: 'https://discord.com/app',
  ),
  AppShortcut(
    id: 'reddit',
    name: 'Reddit',
    description: 'Forum communautaire',
    icon: Icons.people_alt_rounded,
    color: Color(0xFFFF4500),
    androidPackage: 'com.reddit.frontpage',
    webFallbackUrl: 'https://www.reddit.com',
  ),
  AppShortcut(
    id: 'telegram',
    name: 'Telegram',
    description: 'Messagerie chiffrée',
    icon: Icons.send_rounded,
    color: Color(0xFF0088CC),
    androidPackage: 'org.telegram.messenger',
    webFallbackUrl: 'https://web.telegram.org',
  ),
  AppShortcut(
    id: 'signal',
    name: 'Signal',
    description: 'Messagerie sécurisée',
    icon: Icons.lock_rounded,
    color: Color(0xFF3A76F0),
    androidPackage: 'org.thoughtcrime.securesms',
    webFallbackUrl: 'https://signal.org',
  ),
  AppShortcut(
    id: 'twitter',
    name: 'X',
    description: 'Réseau social',
    icon: Icons.alternate_email_rounded,
    color: Color(0xFF1DA1F2),
    androidPackage: 'com.twitter.android',
    webFallbackUrl: 'https://x.com',
  ),
  AppShortcut(
    id: 'github',
    name: 'GitHub',
    description: 'Code & open source',
    icon: Icons.code_rounded,
    color: Color(0xFF6E40C9),
    androidPackage: 'com.github.android',
    webFallbackUrl: 'https://github.com',
  ),
  AppShortcut(
    id: 'maps',
    name: 'Google Maps',
    description: 'Navigation & cartes',
    icon: Icons.map_rounded,
    color: Color(0xFF4285F4),
    androidPackage: 'com.google.android.apps.maps',
    webFallbackUrl: 'https://maps.google.com',
  ),
  AppShortcut(
    id: 'primevideo',
    name: 'Prime Video',
    description: 'Streaming Amazon',
    icon: Icons.movie_rounded,
    color: Color(0xFF00A8E0),
    androidPackage: 'com.amazon.avod.thirdpartyclient',
    webFallbackUrl: 'https://www.primevideo.com',
  ),
  AppShortcut(
    id: 'deezer',
    name: 'Deezer',
    description: 'Musique en streaming',
    icon: Icons.equalizer_rounded,
    color: Color(0xFFA238FF),
    androidPackage: 'deezer.android.app',
    webFallbackUrl: 'https://www.deezer.com',
  ),
];
