class ScoreUtils {
  ScoreUtils._();

  /// Calculate score from correct answers
  static int calculateScore({
    required int correctCount,
    required int totalQuestions,
    int pointsPerCorrect = 10,
    int perfectBonus = 50,
  }) {
    final baseScore = correctCount * pointsPerCorrect;
    final bonus = correctCount == totalQuestions ? perfectBonus : 0;
    return baseScore + bonus;
  }

  /// Calculate accuracy as percentage (0-100)
  static double calculateAccuracy(int correct, int total) {
    if (total == 0) return 0.0;
    return (correct / total) * 100.0;
  }

  /// Get performance message based on accuracy
  static String getPerformanceMessage(double accuracy) {
    if (accuracy >= 90) return 'Excellent Work! 🎉';
    if (accuracy >= 75) return 'Great Job! 👏';
    if (accuracy >= 60) return 'Good Effort! 💪';
    if (accuracy >= 40) return 'Keep Practicing! 📚';
    return 'Don\'t Give Up! 🔥';
  }

  /// Get performance level as string
  static String getPerformanceLevel(double accuracy) {
    if (accuracy >= 90) return 'Excellent';
    if (accuracy >= 75) return 'Great';
    if (accuracy >= 60) return 'Good';
    if (accuracy >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  /// Format points with + prefix
  static String formatPoints(int points) {
    return '+$points pts';
  }

  /// Format accuracy as percentage string
  static String formatAccuracy(double accuracy) {
    return '${accuracy.toStringAsFixed(1)}%';
  }

  /// Format large numbers with commas
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Get rank suffix (1st, 2nd, 3rd, 4th, etc.)
  static String getRankSuffix(int rank) {
    if (rank >= 11 && rank <= 13) return '${rank}th';
    switch (rank % 10) {
      case 1:
        return '${rank}st';
      case 2:
        return '${rank}nd';
      case 3:
        return '${rank}rd';
      default:
        return '${rank}th';
    }
  }

  /// Check if score qualifies for perfect bonus
  static bool isPerfectScore(int correct, int total) {
    return correct == total && total > 0;
  }
}
