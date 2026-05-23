/// Nettoie une URL : ajoute https:// si manquant, supprime le slash final
String cleanUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return url;
  url = url.replaceAll(RegExp(r'/+$'), '');
  if (url.contains('nabu.casa') && url.startsWith('http://')) {
    url = url.replaceFirst('http://', 'https://');
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  return url;
}
