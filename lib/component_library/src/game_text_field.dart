import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nostrawars/component_library/component_library.dart';

class GameTextField extends StatelessWidget {
  const GameTextField({
    super.key,
    required this.hintText,
    // this.iconData,
    this.iconPath,
    this.focusNode,
    this.autoCorrect,
    this.enabled,
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.keyboardType,
    this.obscureText,
    this.onEditingComplete,
    this.controller,
  });

  final String hintText;
  // final IconData? iconData;
  final String? iconPath;
  final FocusNode? focusNode;
  final bool? autoCorrect;
  final bool? enabled;
  final String? errorText;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool? obscureText;
  final Function()? onEditingComplete;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: white,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          color: athens,
          letterSpacing: 0,
        ),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
            color: white,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
            color: santasGray10,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
            color: white,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
            color: santasGray10,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
        prefixIcon: iconPath != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SvgPicture.asset(
                  iconPath!,
                  height: 24,
                  width: 24,
                  color: white,
                ),
              )
            : null,
        errorText: errorText,
      ),
      enabled: enabled,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: textInputAction,
      autocorrect: autoCorrect ?? true,
      onEditingComplete: onEditingComplete,
      controller: controller,
    );
  }
}
