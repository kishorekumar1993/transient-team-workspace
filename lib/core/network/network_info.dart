import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    try {
      final dynamic result = await connectivity.checkConnectivity();
      if (result is List) {
        return result.isNotEmpty && !result.contains(ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map((dynamic result) {
      if (result is List) {
        return result.isNotEmpty && !result.contains(ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    });
  }
}
