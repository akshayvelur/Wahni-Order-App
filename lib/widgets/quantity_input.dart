import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable quantity input widget providing:
/// - [-] Minus button (decrements quantity; <= 0 removes product)
/// - Direct numeric input field with [FilteringTextInputFormatter.digitsOnly]
/// - [+] Plus button (increments quantity up to [maxQuantity])
///
/// Quality & Reliability guarantees:
/// - [TextEditingController] and [FocusNode] are created in initState(), NOT in build().
/// - Both are safely disposed in dispose().
/// - Focus remains stable while typing.
/// - Cursor does not jump unexpectedly.
/// - Typed text is not overwritten during external rebuilds while focused.
/// - Empty input removes the product.
/// - Zero removes the product.
/// - Negative numbers, decimal numbers, and non-digit text are strictly rejected.
class QuantityInput extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final int maxQuantity;
  final Key? inputKey;
  final Key? incrementKey;
  final Key? decrementKey;

  const QuantityInput({
    required this.quantity,
    required this.onQuantityChanged,
    this.onIncrement,
    this.onDecrement,
    this.maxQuantity = 9999,
    this.inputKey,
    this.incrementKey,
    this.decrementKey,
    super.key,
  });

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // TextEditingController and FocusNode are created in initState(), NEVER in build()
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller text if the external quantity changed AND field is not focused.
    // This prevents typed text overwriting and cursor jumping while the user types.
    if (widget.quantity != oldWidget.quantity) {
      if (!_focusNode.hasFocus && _controller.text != '${widget.quantity}') {
        _controller.text = '${widget.quantity}';
      }
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = _controller.text.trim();
      if (text.isEmpty || text == '0') {
        // Empty input or zero removes the product
        widget.onQuantityChanged(0);
      } else {
        final parsed = int.tryParse(text);
        if (parsed != null && parsed > 0) {
          final clamped = parsed > widget.maxQuantity
              ? widget.maxQuantity
              : parsed;
          widget.onQuantityChanged(clamped);
          _controller.text = '$clamped';
        } else {
          widget.onQuantityChanged(0);
        }
      }
    }
  }

  void _handleChanged(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      // Empty input removes the product
      widget.onQuantityChanged(0);
      return;
    }

    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) {
      // Zero or non-positive removes the product
      widget.onQuantityChanged(0);
    } else {
      final clamped = parsed > widget.maxQuantity ? widget.maxQuantity : parsed;
      widget.onQuantityChanged(clamped);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _decrement() {
    if (widget.onDecrement != null) {
      widget.onDecrement!();
      return;
    }
    final newQty = widget.quantity - 1;
    widget.onQuantityChanged(newQty <= 0 ? 0 : newQty);
    if (!_focusNode.hasFocus) {
      _controller.text = '${newQty <= 0 ? 0 : newQty}';
    }
  }

  void _increment() {
    if (widget.onIncrement != null) {
      widget.onIncrement!();
      return;
    }
    final newQty = widget.quantity < widget.maxQuantity
        ? widget.quantity + 1
        : widget.maxQuantity;
    widget.onQuantityChanged(newQty);
    if (!_focusNode.hasFocus) {
      _controller.text = '$newQty';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // [-] Minus button
        IconButton(
          key: widget.decrementKey,
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          tooltip: 'Decrease quantity',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: _decrement,
        ),

        // Direct numeric text field
        SizedBox(
          width: 48,
          height: 36,
          child: TextField(
            key: widget.inputKey,
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: TextInputType.number,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            // Rejects decimal numbers, negative numbers, and letters/text
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: _handleChanged,
          ),
        ),

        // [+] Plus button
        IconButton(
          key: widget.incrementKey,
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          tooltip: 'Increase quantity',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _increment,
        ),
      ],
    );
  }
}
