import 'package:flutter/material.dart';

import '../../domain/entities/learning_item.dart';

class AnswerButtons extends StatelessWidget {
  const AnswerButtons({super.key, required this.onAnswer, this.disabled = false});

  final ValueChanged<ReviewAnswer> onAnswer;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnswerBtn(
            label: 'Nie wiem',
            color: Colors.redAccent,
            onTap: disabled ? null : () => onAnswer(ReviewAnswer.nieWiem),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AnswerBtn(
            label: 'Prawie',
            color: Colors.orangeAccent,
            onTap: disabled ? null : () => onAnswer(ReviewAnswer.prawie),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AnswerBtn(
            label: 'Wiem',
            color: Colors.greenAccent.shade700,
            onTap: disabled ? null : () => onAnswer(ReviewAnswer.wiem),
          ),
        ),
      ],
    );
  }
}

class _AnswerBtn extends StatelessWidget {
  const _AnswerBtn({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.7)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}
