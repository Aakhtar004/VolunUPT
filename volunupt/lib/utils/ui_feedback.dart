import 'package:flutter/material.dart';

class UiFeedback {
  static void showSuccess(BuildContext context, String message) {
    _showSnack(context, message, Colors.green);
  }

  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: onRetry != null
          ? SnackBarAction(label: 'Reintentar', onPressed: onRetry)
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnack(context, message, Colors.blueGrey);
  }

  static void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}