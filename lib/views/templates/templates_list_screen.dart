import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/app_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../models/legal_template_model.dart';
import '../webview/template_viewer_screen.dart';

class TemplatesListScreen extends ConsumerStatefulWidget {
  const TemplatesListScreen({super.key});

  @override
  ConsumerState<TemplatesListScreen> createState() => _TemplatesListScreenState();
}

class _TemplatesListScreenState extends ConsumerState<TemplatesListScreen> {
  final ApiClient _apiClient = ApiClient();
  List<LegalTemplateModel> _templates = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get(
        ApiConstants.templates,
        queryParameters: {
          if (_selectedCategory != null) 'category': _selectedCategory,
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
      );

      if (response.data['success'] == true) {
        final templates = response.data['data']['templates'] as List;
        setState(() {
          _templates = templates
              .map((json) => LegalTemplateModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to load templates';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Templates'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadTemplates();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.isEmpty) {
                  _loadTemplates();
                }
              },
              onSubmitted: (_) => _loadTemplates(),
            ),
          ),
          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _loadTemplates();
                  },
                ),
                const SizedBox(width: AppConstants.spacingS),
                ...['Contract', 'Agreement', 'Notice', 'Petition', 'Affidavit']
                    .map((category) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppConstants.spacingS,
                          ),
                          child: _CategoryChip(
                            label: category,
                            isSelected: _selectedCategory == category,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _loadTemplates();
                            },
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Templates List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            ElevatedButton(
                              onPressed: _loadTemplates,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _templates.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: AppConstants.spacingM),
                                Text(
                                  'No templates found',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTemplates,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppConstants.spacingM),
                              itemCount: _templates.length,
                              itemBuilder: (context, index) {
                                final template = _templates[index];
                                return AppCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TemplateViewerScreen(
                                          template: template,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              template.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                          ),
                                          Chip(
                                            label: Text(template.category),
                                            backgroundColor:
                                                AppTheme.primaryColor
                                                    .withValues(alpha: 0.2),
                                            labelStyle: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (template.description != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          template.description!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.visibility,
                                            size: 16,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${template.usageCount} uses',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
      ),
    );
  }
}

