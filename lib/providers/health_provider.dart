import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../services/health_check_service.dart';
import 'services_provider.dart';
import 'settings_provider.dart';

class HealthState {
  final Map<String, ServiceStatus> statuses;
  final bool isChecking;

  const HealthState({this.statuses = const {}, this.isChecking = false});

  HealthState copyWith({Map<String, ServiceStatus>? statuses, bool? isChecking}) =>
      HealthState(
        statuses: statuses ?? this.statuses,
        isChecking: isChecking ?? this.isChecking,
      );

  ServiceStatus? statusFor(String id) => statuses[id];
}

class HealthNotifier extends StateNotifier<HealthState>
    with WidgetsBindingObserver {
  HealthNotifier(this._ref) : super(const HealthState()) {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  final Ref _ref;
  Timer? _timer;
  final _checker = HealthCheckService();

  void _startTimer() {
    // Delay the first check by 4 s so Tailscale can reconnect after cold start.
    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;
      await checkAll();
      _scheduleNext();
    });
  }

  void _scheduleNext() {
    _timer?.cancel();
    final interval = _ref.read(settingsProvider).refreshIntervalSeconds;
    _timer = Timer(Duration(seconds: interval), () async {
      await checkAll();
      if (mounted) _scheduleNext();
    });
  }

  // Re-check when app comes back to foreground (Tailscale may have reconnected).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer?.cancel();
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        await checkAll();
        _scheduleNext();
      });
    }
  }

  Future<void> checkAll() async {
    final services = _ref.read(enabledServicesProvider);
    state = state.copyWith(isChecking: true);
    final results = await Future.wait(
      services.map((s) => _checker.check(s)),
    );
    final map = Map<String, ServiceStatus>.from(state.statuses);
    for (final r in results) {
      map[r.serviceId] = r;
    }
    if (mounted) state = state.copyWith(statuses: map, isChecking: false);
  }

  Future<void> checkSingle(ServiceModel service) async {
    final result = await _checker.check(service);
    final map = Map<String, ServiceStatus>.from(state.statuses);
    map[result.serviceId] = result;
    if (mounted) state = state.copyWith(statuses: map);
  }

  void resetInterval() => _scheduleNext();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _checker.close();
    super.dispose();
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>(
        (ref) => HealthNotifier(ref));
