import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslationManagementWidget extends StatefulWidget {
  const TranslationManagementWidget({super.key});

  @override
  State<TranslationManagementWidget> createState() => _TranslationManagementWidgetState();
}

class _TranslationManagementWidgetState extends State<TranslationManagementWidget> {
  List<Map<String, dynamic>> _translations = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _chineseController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final translations = await TranslationService.getAllTranslations();
      final stats = await TranslationService.getTranslationStats();
      
      setState(() {
        _translations = translations;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _addTranslation() async {
    if (_englishController.text.isEmpty || _chineseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both English and Chinese names')),
      );
      return;
    }

    try {
      await TranslationService.addIngredientTranslation(
        englishName: _englishController.text.trim(),
        chineseName: _chineseController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      );

      _englishController.clear();
      _chineseController.clear();
      _categoryController.clear();
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translation added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding translation: $e')),
        );
      }
    }
  }

  Future<void> _applyRetroactiveTranslations() async {
    setState(() => _isLoading = true);
    
    try {
      final count = await TranslationService.applyRetroactiveTranslations();
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Applied $count retroactive translations!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying retroactive translations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Translation Statistics',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Total Translations',
                                _stats['total_translations']?.toString() ?? '0',
                                scheme.primary,
                              ),
                              _buildStatCard(
                                'With Chinese',
                                _stats['ingredients_with_chinese']?.toString() ?? '0',
                                scheme.secondary,
                              ),
                              _buildStatCard(
                                'Missing',
                                _stats['missing_translations']?.toString() ?? '0',
                                scheme.tertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Add Translation Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Translation',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _englishController,
                            decoration: const InputDecoration(
                              labelText: 'English Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _chineseController,
                            decoration: const InputDecoration(
                              labelText: 'Chinese Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _addTranslation,
                                child: const Text('Add Translation'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _applyRetroactiveTranslations,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                ),
                                child: const Text('Apply Retroactive Translations'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Translations List
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Translations (${_translations.length})',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              IconButton(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_translations.isEmpty)
                            const Center(
                              child: Text('No translations found'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _translations.length,
                              itemBuilder: (context, index) {
                                final translation = _translations[index];
                                return ListTile(
                                  leading: const Icon(Icons.translate),
                                  title: Text(translation['english_name'] ?? ''),
                                  subtitle: Text(translation['chinese_name'] ?? ''),
                                  trailing: translation['category'] != null
                                      ? Chip(
                                          label: Text(
                                            translation['category'],
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _englishController.dispose();
    _chineseController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
