import 'package:flutter/material.dart';

/// Reusable loading indicator widget for both apps
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;
  
  const LoadingIndicator({
    super.key,
    this.message,
    this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: const LoadingIndicator(),
          ),
      ],
    );
  }
}

