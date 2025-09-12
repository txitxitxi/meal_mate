class TextFormatter {
  /// Converts text to proper title case
  /// Examples:
  /// - "BEEF" -> "Beef"
  /// - "green pepper" -> "Green Pepper"
  /// - "whole wheat bread" -> "Whole Wheat Bread"
  /// - "milk (2%)" -> "Milk (2%)"
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    // Split by spaces and format each word
    final words = text.trim().split(' ');
    final formattedWords = words.map((word) {
      if (word.isEmpty) return word;
      
      // Handle special cases like parentheses and percentages
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s%()]'), '');
      if (cleanWord.isEmpty) return word;
      
      return word.replaceRange(
        0,
        1,
        word[0].toUpperCase(),
      ).replaceRange(
        1,
        null,
        word.substring(1).toLowerCase(),
      );
    });
    
    return formattedWords.join(' ');
  }
  
  /// Formats recipe titles with special handling for common words
  static String toRecipeTitleCase(String text) {
    if (text.isEmpty) return text;
    
    final commonWords = {
      'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
      'the', 'a', 'an', 'from', 'as', 'is', 'was', 'are', 'were', 'be', 'been',
      'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should'
    };
    
    final words = text.trim().split(' ');
    final formattedWords = words.asMap().entries.map((entry) {
      final index = entry.key;
      final word = entry.value;
      
      if (word.isEmpty) return word;
      
      // Always capitalize first and last words
      if (index == 0 || index == words.length - 1) {
        return _capitalizeWord(word);
      }
      
      // Check if it's a common word (lowercase) or capitalize it
      final lowerWord = word.toLowerCase();
      if (commonWords.contains(lowerWord)) {
        return lowerWord;
      }
      
      return _capitalizeWord(word);
    });
    
    return formattedWords.join(' ');
  }
  
  static String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    
    // Handle special cases like parentheses and percentages
    final cleanWord = word.replaceAll(RegExp(r'[^\w\s%()]'), '');
    if (cleanWord.isEmpty) return word;
    
    return word.replaceRange(
      0,
      1,
      word[0].toUpperCase(),
    ).replaceRange(
      1,
      null,
      word.substring(1).toLowerCase(),
    );
  }
}
