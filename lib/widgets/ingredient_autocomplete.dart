import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_providers.dart';
import '../utils/text_formatter.dart';

class IngredientAutocomplete extends ConsumerStatefulWidget {
  const IngredientAutocomplete({
    super.key,
    required this.controller,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.validator,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;

  @override
  ConsumerState<IngredientAutocomplete> createState() => _IngredientAutocompleteState();
}

class _IngredientAutocompleteState extends ConsumerState<IngredientAutocomplete> {
  bool _showSuggestions = false;
  String _lastQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                      setState(() => _showSuggestions = false);
                    },
                  )
                : null,
          ),
          validator: widget.validator,
          onChanged: (value) {
            // Use a safer approach - don't modify the controller during onChanged
            // Let the parent handle the formatting
            final formatted = TextFormatter.toTitleCase(value);
            
            widget.onChanged(formatted);
            
            setState(() {
              _showSuggestions = formatted.length >= 2;
              _lastQuery = formatted;
            });
          },
          onTap: () {
            setState(() {
              _showSuggestions = widget.controller.text.length >= 2;
            });
          },
          onFieldSubmitted: (value) {
            setState(() => _showSuggestions = false);
            // On mobile, when user presses "Done" or "Enter", 
            // they want to create the ingredient if it doesn't exist
            if (value.trim().isNotEmpty) {
              widget.controller.text = value.trim();
              widget.onChanged(value.trim());
              FocusScope.of(context).unfocus();
            }
          },
        ),
        if (_showSuggestions && _lastQuery.isNotEmpty)
          _buildSuggestions(),
      ],
    );
  }

  Widget _buildSuggestions() {
    final suggestionsAsync = ref.watch(searchIngredientsProvider(_lastQuery));
    
    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No existing ingredients found',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.controller.text = _lastQuery;
                      widget.onChanged(_lastQuery);
                      setState(() => _showSuggestions = false);
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('Create "$_lastQuery"'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: suggestions.map((ingredient) {
              final name = ingredient['name'] as String;
              final category = ingredient['category'] as String?;
              final defaultUnit = ingredient['default_unit'] as String?;
              final matchedTerm = ingredient['matched_term'] as String?;
              final locale = ingredient['locale'] as String?;
              
              // Show matched term if different from name (indicates bilingual match)
              final showBilingualMatch = matchedTerm != null && matchedTerm != name;
              
              return InkWell(
                onTap: () {
                  widget.controller.text = name;
                  widget.onChanged(name);
                  setState(() => _showSuggestions = false);
                  // Remove focus from the text field
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: suggestions.indexOf(ingredient) < suggestions.length - 1
                        ? Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (showBilingualMatch) ...[
                                  const SizedBox(width: 8),
                                  Builder(
                                    builder: (context) {
                                      final colorScheme = Theme.of(context).colorScheme;
                                      final isChineseLocale = locale == 'zh';
                                      final containerColor = isChineseLocale
                                          ? colorScheme.primaryContainer
                                          : colorScheme.secondaryContainer;
                                      final textColor = isChineseLocale
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSecondaryContainer;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: containerColor.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isChineseLocale ? '中' : 'EN',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                            if (showBilingualMatch)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Matched: "$matchedTerm"',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            if (category != null || defaultUnit != null)
                              Text(
                                [
                                  if (category != null) category,
                                  if (defaultUnit != null) 'Default: $defaultUnit',
                                ].join(' • '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Searching ingredients...'),
          ],
        ),
      ),
      error: (error, stack) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error loading suggestions: $error',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
