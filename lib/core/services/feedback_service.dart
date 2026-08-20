import 'package:flutter/services.dart';

class FeedbackService {
  const FeedbackService();

  Future<void> scanSuccess() async {
    await HapticFeedback.mediumImpact();
  }

  Future<void> light() async {
    await HapticFeedback.selectionClick();
  }
}
