import 'package:flutter/material.dart';

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString()),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

String? requiredField(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Required' : null;

String? emailField(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  return valid ? null : 'Enter a valid email';
}
