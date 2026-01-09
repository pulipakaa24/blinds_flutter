import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A comprehensive, flexible text input widget that maintains consistent styling
/// across the entire app while supporting all common text input use cases.
class BlindMasterInput extends StatefulWidget {
  const BlindMasterInput(
    this.label, {
    super.key,
    this.controller,
    this.validator,
    this.color,
    this.password = false,
    this.enabled = true,
    this.keyboardType,
    this.prefixIcon,
    this.hintText,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.focusedBorderColor,
    this.initialValue,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final Color? color;
  final bool password;
  final bool enabled;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? hintText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final Function(String)? onChanged;
  final Color? focusedBorderColor;
  final String? initialValue;
  final bool autofocus;

  final String? Function(String?)? validator;

  @override
  State<BlindMasterInput> createState() => _BlindMasterInputState();
}

class _BlindMasterInputState extends State<BlindMasterInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: TextFormField(
        initialValue: widget.initialValue,
        controller: widget.controller,
        validator: widget.validator,
        obscureText: widget.password && _obscureText,
        enableSuggestions: !widget.password,
        autocorrect: !widget.password,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        textAlign: widget.textAlign,
        maxLength: widget.maxLength,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        style: TextStyle(
          color: widget.color,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          focusedBorder: widget.focusedBorderColor != null
              ? OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(
                    color: widget.focusedBorderColor!,
                    width: 2,
                  ),
                )
              : null,
          labelText: widget.label,
          hintText: widget.hintText,
          labelStyle: TextStyle(color: widget.color),
          contentPadding: const EdgeInsets.all(10),
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          counterText: widget.maxLength != null ? '' : null, // Hide character counter
        ),
      ),
    );
  }
}

// Legacy alias for backward compatibility
class BlindMasterMainInput extends BlindMasterInput {
  const BlindMasterMainInput(
    super.label, {
    super.key,
    super.controller,
    super.validator,
    super.color,
    super.password,
  });
}