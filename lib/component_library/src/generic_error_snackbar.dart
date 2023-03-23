import 'package:flutter/material.dart';

class GenericErrorSnackBar extends SnackBar {
  GenericErrorSnackBar({Key? key, required this.message})
      : super(
          key: key,
          content: _GenericErrorSnackBarMessage(
            message: message,
          ),
        );

  final String message;
}

class _GenericErrorSnackBarMessage extends StatelessWidget {
  const _GenericErrorSnackBarMessage({Key? key, required this.message})
      : super(key: key);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
    );
  }
}
