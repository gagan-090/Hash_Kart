import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        child: OutlinedButton(
          onPressed: (isLoading || onPressed == null) ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(text),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading || onPressed == null) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(text),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint ?? label,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String? originalPrice;
  final double? rating;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.originalPrice,
    this.rating,
    required this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (onFavorite != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? AppTheme.accentColor : AppTheme.textLight,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            price,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (originalPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              originalPrice!,
                              style: AppTheme.bodySmall.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating!.toString(),
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.category,
                      size: 40,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTheme.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed!,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
