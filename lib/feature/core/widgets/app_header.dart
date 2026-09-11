import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.tela,
    required this.title,
    this.subtitle,
  });


  final String tela;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        tela,
        style: AppTextStyles.caption.copyWith(color: AppColors.white),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        style: AppTextStyles.h2.copyWith(color: AppColors.white),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle!,
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ],
    ],
  );
}