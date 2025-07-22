import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NoInternetMessage extends StatefulWidget {
  final Widget child;
  final String message;
  const NoInternetMessage({
    super.key,
    required this.child,
    this.message = 'لا يوجد اتصال بالإنترنت. بعض الميزات قد لا تعمل.',
  });

  @override
  State<NoInternetMessage> createState() => _NoInternetMessageState();
}

class _NoInternetMessageState extends State<NoInternetMessage> {
  bool _isOffline = false;
  late final Connectivity _connectivity;
  late final _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _checkConnection();
    _connectivityStream.listen((result) {
      final offline = result == ConnectivityResult.none;
      if (offline != _isOffline && mounted) {
        setState(() {
          _isOffline = offline;
        });
      }
    });
  }

  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red[700],
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
