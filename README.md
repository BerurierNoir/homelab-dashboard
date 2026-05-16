# 🚀 HomeLab Dashboard

Application Android pour gérer vos services self-hosted depuis votre réseau Tailscale.

---

## ✨ Fonctionnalités

- **Dashboard** : grille de tous vos services avec statut en temps réel
- **WebView intégrée** : accès direct aux interfaces web de chaque service
- **Auto-login** : injection JS ou token API selon le service
- **Monitoring** : temps de réponse, statut up/down, historique
- **Sécurité** : credentials chiffrés via Android Keystore

---

## 📦 Récupérer l'APK via GitHub Actions

### Méthode 1 — Télécharger l'artifact

1. Allez dans l'onglet **Actions** de votre repo GitHub
2. Cliquez sur le dernier workflow **Build APK** ✅
3. En bas de page, section **Artifacts**, téléchargez **homelab-apk**
4. Dezippez → vous obtenez `homelab-dashboard-vYYYYMMDD.apk`

### Méthode 2 — GitHub Release automatique

Chaque push sur `main` crée une **Release** avec l'APK en pièce jointe.
Allez dans **Releases** → téléchargez le dernier APK.

### Installation sur Android

```
1. Transférez l'APK sur votre téléphone (USB, Drive, etc.)
2. Paramètres → Sécurité → Autoriser les sources inconnues
3. Ouvrez le fichier APK → Installer
```

---

## ⚙️ Configuration initiale

### 1. Prérequis réseau

> **Tailscale doit être actif** sur votre téléphone Android pour accéder
> aux services de votre homelab via les noms d'hôtes internes.

Installez Tailscale : https://tailscale.com/download/android

### 2. Configurer les URLs

1. Ouvrez l'app → icône ⚙️ en haut à droite
2. Pour chaque service, dépliez la carte et modifiez l'URL
3. Utilisez les noms Tailscale de vos machines (ex: `http://mon-nas:8096`)
4. Bouton **Tester** pour vérifier la connectivité

### 3. Configurer les credentials

Dans les paramètres de chaque service :

| Service | Méthode | Ce qu'il faut saisir |
|---------|---------|----------------------|
| Jellyfin | API Token | Username + Password (token généré automatiquement) |
| Home Assistant | API Token | Token longue durée (Profil → Sécurité → Tokens) |
| Mealie | JS Injection | Username + Password |
| Paperless-ngx | JS Injection | Username + Password |
| Immich | JS Injection | Username + Password |
| Kavita | JS Injection | Username + Password |
| Uptime Kuma | JS Injection | Username + Password |
| Calibre-Web | JS Injection | Username + Password |
| Proxmox VE | JS Injection | Username + Password |
| Jotty | JS Injection | Username + Password |
| Homepage | Aucune | — |
| TeamSpeak 6 | Aucune | — |

### 4. Home Assistant — Token longue durée

```
1. Ouvrez Home Assistant dans un navigateur
2. Cliquez sur votre profil (en bas à gauche)
3. Faites défiler → "Tokens d'accès longue durée"
4. Créez un token → copiez-le
5. Collez-le dans l'app → champ "API Token" de Home Assistant
```

---

## 🏗️ Build local

### Prérequis

- Flutter SDK stable : https://flutter.dev/docs/get-started/install
- Java 17+
- Android SDK

### Commandes

```bash
# Cloner le repo
git clone https://github.com/VOTRE_USER/homelab-dashboard.git
cd homelab_dashboard

# Installer les dépendances
flutter pub get

# Vérifier le code
flutter analyze

# Build debug (pour tester)
flutter build apk --debug

# Build release
flutter build apk --release

# APK généré ici :
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🛡️ Sécurité

- Les credentials sont stockés via **Android Keystore** (chiffrement matériel)
- Ils ne quittent **jamais** l'appareil
- Les URLs sont stockées en clair dans SharedPreferences (pas sensible)
- Certificats self-signed acceptés (nécessaire pour Proxmox VE)
- Trafic HTTP cleartext autorisé pour le réseau local

---

## 📱 Compatibilité

- Android 7.0+ (API 24)
- Target Android 14 (API 34)
- Architecture : arm64-v8a, armeabi-v7a, x86_64

---

## 🗺️ Structure du projet

```
lib/
├── main.dart              # Point d'entrée
├── app.dart               # MaterialApp + thème spatial
├── models/
│   └── service.dart       # Modèle Service + statuts
├── providers/
│   ├── services_provider.dart   # État des services
│   ├── settings_provider.dart   # Préférences
│   └── health_provider.dart     # Monitoring
├── screens/
│   ├── dashboard_screen.dart    # Grille principale
│   ├── webview_screen.dart      # WebView + auto-login
│   ├── settings_screen.dart     # Configuration
│   └── status_screen.dart       # Statuts détaillés
├── widgets/
│   ├── service_card.dart        # Carte service avec glow
│   ├── status_badge.dart        # Badge pulse vert/rouge
│   └── shimmer_card.dart        # Loading skeleton
└── services/
    ├── health_check_service.dart # Ping HTTP
    ├── credential_service.dart   # Keystore wrapper
    └── auto_login_service.dart   # JS injection + API
```
