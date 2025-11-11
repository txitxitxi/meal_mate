import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_providers.dart';
import '../models/recipe.dart';
class RecipeSearchPage extends ConsumerStatefulWidget {
  const RecipeSearchPage({super.key});

  @override
  ConsumerState<RecipeSearchPage> createState() => _RecipeSearchPageState();
}

class _RecipeSearchPageState extends ConsumerState<RecipeSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isChinese(String text) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Recipes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by ingredient (e.g., "beef" or "牛肉")',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentSearchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _currentSearchTerm = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _currentSearchTerm = value.trim());
              },
              onSubmitted: (value) {
                setState(() => _currentSearchTerm = value.trim());
              },
            ),
          ),

          // Search results
          Expanded(
            child: _currentSearchTerm.isEmpty
                ? _buildEmptyState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for recipes by ingredient',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for "beef", "chicken", "牛肉", or "鸡肉"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final recipesAsync = ref.watch(searchRecipesByIngredientProvider(_currentSearchTerm));
    final scheme = Theme.of(context).colorScheme;
    final zhContainer = scheme.primaryContainer;
    final zhOnContainer = scheme.onPrimaryContainer;

    return Column(
      children: [
        // Search info header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Search results for: "$_currentSearchTerm"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_isChinese(_currentSearchTerm)) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: zhContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '中文',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: zhOnContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Results
        Expanded(
          child: recipesAsync.when(
            data: (recipes) {
              if (recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recipes found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try searching for a different ingredient',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return _buildRecipeCard(recipe);
                },
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching recipes...'),
                ],
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search failed',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Recipe image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant_menu),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant_menu),
                      ),
              ),
              const SizedBox(width: 16),

              // Recipe info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (recipe.description != null)
                      Text(
                        recipe.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(Icons.people, '${recipe.servings} servings'),
                        const SizedBox(width: 8),
                        if (recipe.cookTimeMin != null)
                          _buildInfoChip(Icons.timer, '${recipe.cookTimeMin} min'),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe.title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recipe.imageUrl!,
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              if (recipe.description != null) ...[
                Text(
                  'Description:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(recipe.description!),
                const SizedBox(height: 16),
              ],
              Text(
                'Details:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Servings: ${recipe.servings}'),
              if (recipe.prepTimeMin != null)
                Text('Prep time: ${recipe.prepTimeMin} minutes'),
              if (recipe.cookTimeMin != null)
                Text('Cook time: ${recipe.cookTimeMin} minutes'),
              if (recipe.cuisine != null)
                Text('Cuisine: ${recipe.cuisine}'),
              Text('Protein: ${recipe.protein.name}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
