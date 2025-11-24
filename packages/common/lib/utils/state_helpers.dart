import 'package:flutter/material.dart';
import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

/// Helper mixin for common loading/error state patterns
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        _isLoading = value;
      });
    }
  }
  
  void setError(String? message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }
  
  void clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }
  
  /// Execute an async function with automatic loading/error handling
  Future<R?> executeWithLoading<R>({
    required Future<R> Function() action,
    String? errorMessage,
    bool showErrorSnackbar = true,
  }) async {
    setLoading(true);
    clearError();
    
    try {
      final result = await action();
      if (mounted) {
        setLoading(false);
      }
      return result;
    } on ApiClientException catch (e) {
      if (mounted) {
        setError(errorMessage ?? e.message);
        if (showErrorSnackbar) {
          showErrorSnackBar(context, errorMessage ?? e.message);
        }
      }
      return null;
    } catch (e) {
      if (mounted) {
        final message = errorMessage ?? 'An unexpected error occurred: $e';
        setError(message);
        if (showErrorSnackbar) {
          showErrorSnackBar(context, message);
        }
      }
      return null;
    }
  }
  
  /// Widget to show loading state
  Widget buildLoadingState({String? message}) {
    return LoadingIndicator(message: message);
  }
  
  /// Widget to show error state with retry
  Widget buildErrorState({
    String? customMessage,
    VoidCallback? onRetry,
    IconData? icon,
  }) {
    return ErrorMessage(
      message: customMessage ?? errorMessage ?? 'Something went wrong',
      onRetry: onRetry,
      icon: icon ?? Icons.error_outline,
    );
  }
}

/// Helper for async data loading pattern
class AsyncDataLoader<T> {
  final Future<T> Function() loader;
  
  AsyncDataLoader(this.loader);
  
  Future<T?> load({
    required Function(bool) setLoading,
    required Function(String?) setError,
    String? defaultErrorMessage,
  }) async {
    setLoading(true);
    setError(null);
    
    try {
      final result = await loader();
      setLoading(false);
      return result;
    } on ApiClientException catch (e) {
      setError(defaultErrorMessage ?? e.message);
      return null;
    } catch (e) {
      setError(defaultErrorMessage ?? 'Failed to load data: $e');
      return null;
    }
  }
}

