import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service.onStatusChange;
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _lastStatus = true;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _lastStatus) {
        _lastStatus = online;
        _controller.add(online);
      }
    });
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final results = await _connectivity.checkConnectivity();
    _lastStatus = results.any((r) => r != ConnectivityResult.none);
    _controller.add(_lastStatus);
  }

  Stream<bool> get onStatusChange => _controller.stream;

  bool get isOnline => _lastStatus;

  void dispose() {
    _controller.close();
  }
}
