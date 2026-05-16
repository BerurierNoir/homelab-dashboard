class BeszelStats {
  final double cpu;
  final double mem;
  final double disk;
  final double? temp;
  final double networkSentMbs;
  final double networkRecvMbs;
  final String systemName;
  final bool available;

  const BeszelStats({
    required this.cpu,
    required this.mem,
    required this.disk,
    this.temp,
    this.networkSentMbs = 0,
    this.networkRecvMbs = 0,
    required this.systemName,
    this.available = true,
  });

  const BeszelStats.unavailable()
      : cpu = 0,
        mem = 0,
        disk = 0,
        temp = null,
        networkSentMbs = 0,
        networkRecvMbs = 0,
        systemName = '',
        available = false;

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory BeszelStats.fromJson(Map<String, dynamic> stats, String name) {
    final t = stats['t'];
    return BeszelStats(
      cpu: _d(stats['cpu']),
      mem: _d(stats['m']),
      disk: _d(stats['du']),
      temp: t is num ? t.toDouble() : null,
      networkSentMbs: _d(stats['ns']) / 1024 / 1024,
      networkRecvMbs: _d(stats['nr']) / 1024 / 1024,
      systemName: name,
    );
  }
}
