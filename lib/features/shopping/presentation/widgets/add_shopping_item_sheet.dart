import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/item_suggestion.dart';
import '../../data/shopping_service.dart';
import '../../data/suggestions_service.dart';
import '../providers/shopping_providers.dart';
import 'auto_close_date_range_picker.dart';

/// Bottom sheet for adding a new shopping item
class AddShoppingItemSheet extends ConsumerStatefulWidget {
  final String homeId;
  final String userId;

  const AddShoppingItemSheet({
    super.key,
    required this.homeId,
    required this.userId,
  });

  @override
  ConsumerState<AddShoppingItemSheet> createState() =>
      _AddShoppingItemSheetState();
}

class _AddShoppingItemSheetState extends ConsumerState<AddShoppingItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _nameFocusNode = FocusNode();

  String? _selectedStoreId;
  bool _important = false;
  bool _lookoutFor = false;
  DateTime? _discountStart;
  DateTime? _discountEnd;
  bool _isLoading = false;

  // Suggestions state
  List<ItemSuggestion> _matchingSuggestions = [];
  bool _showSuggestions = false;

  // Duplicate warning state
  bool _showDuplicateWarning = false;
  String? _duplicateStoreName;

  @override
  void initState() {
    super.initState();
    // Set default store from last used
    _selectedStoreId = ref.read(lastUsedStoreIdProvider);

    // Set default discount range from last used
    final lastDiscountRange = ref.read(lastUsedDiscountRangeProvider);
    if (lastDiscountRange != null) {
      _discountStart = lastDiscountRange.start;
      _discountEnd = lastDiscountRange.end;
    }

    // Listen to name changes for suggestions
    _nameController.addListener(_onNameChanged);

    // Listen to focus changes for duplicate check
    _nameFocusNode.addListener(_onNameFocusChanged);

    // Note: On Web/PWA, keyboard cannot be opened programmatically
    // The user must tap the input field directly to open the keyboard
    // We still request focus to highlight the field visually
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_nameFocusNode);
        }
      });
    });
  }

  void _onNameChanged() {
    _updateSuggestions(_nameController.text);
    // Clear duplicate warning when user changes the name
    if (_showDuplicateWarning) {
      setState(() {
        _showDuplicateWarning = false;
        _duplicateStoreName = null;
      });
    }
  }

  void _onNameFocusChanged() {
    // Only check for duplicates when focus is lost (user clicks away)
    if (!_nameFocusNode.hasFocus) {
      _checkForDuplicateItem();
    }
  }

  void _checkForDuplicateItem() {
    final inputName = _nameController.text.trim();
    if (inputName.isEmpty) return;

    // Get active (non-completed) shopping items
    final activeItems = ref.read(activeShoppingItemsProvider).valueOrNull ?? [];

    // Normalize input for comparison (lowercase, trim)
    final normalizedInput = inputName.toLowerCase();

    // Find matching item (exact or fuzzy match)
    ShoppingItem? duplicateItem;
    for (final item in activeItems) {
      final normalizedItemName = item.name.toLowerCase();

      // Check for exact match or close match (Levenshtein-like simple check)
      if (_isSimilarName(normalizedInput, normalizedItemName)) {
        duplicateItem = item;
        break;
      }
    }

    if (duplicateItem != null) {
      // Get store name for the duplicate item
      String? storeName;
      if (duplicateItem.storeId != null) {
        final store = ref.read(storeByIdProvider(duplicateItem.storeId!));
        storeName = store?.name;
      }

      setState(() {
        _showDuplicateWarning = true;
        _duplicateStoreName = storeName;
      });

      // Show toast notification
      _showDuplicateToast(duplicateItem.name, storeName);
    } else {
      setState(() {
        _showDuplicateWarning = false;
        _duplicateStoreName = null;
      });
    }
  }

  /// Check if two names are similar (exact match or close enough)
  bool _isSimilarName(String input, String itemName) {
    // Exact match
    if (input == itemName) return true;

    // One contains the other
    if (input.contains(itemName) || itemName.contains(input)) return true;

    // Simple fuzzy match using edit distance threshold
    // Allow 1-2 character differences for short words, more for longer words
    final maxDistance = input.length <= 4 ? 1 : 2;
    final distance = _levenshteinDistance(input, itemName);

    return distance <= maxDistance;
  }

  /// Calculate Levenshtein edit distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }

      final temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  void _showDuplicateToast(String itemName, String? storeName) {
    final storeText = storeName != null
        ? '${AppStrings.duplicateItemAt} $storeName'
        : AppStrings.duplicateItemNoStore;

    // Use an overlay to show the toast above the bottom sheet
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _DuplicateToastOverlay(
        itemName: itemName,
        storeText: storeText,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _updateSuggestions(String query) async {
    debugPrint('🔍 _updateSuggestions called with query: "$query"');
    if (query.trim().isEmpty) {
      setState(() {
        _matchingSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final allSuggestions = ref.read(itemSuggestionsProvider).valueOrNull ?? [];
    debugPrint('🔍 All suggestions available: ${allSuggestions.length}');
    for (final s in allSuggestions) {
      debugPrint('   - ${s.displayName} (count: ${s.useCount})');
    }

    // Filter and sort by match score
    final matches = allSuggestions.where((s) {
      final matches = s.matchesQuery(query);
      debugPrint('   Testing "${s.displayName}" against "$query": $matches');
      return matches;
    }).toList()
      ..sort((a, b) => b.matchScore(query).compareTo(a.matchScore(query)));

    debugPrint('🔍 Matching suggestions: ${matches.length}');

    setState(() {
      _matchingSuggestions = matches.take(3).toList();
      _showSuggestions = _matchingSuggestions.isNotEmpty;
    });
    debugPrint('🔍 Show suggestions: $_showSuggestions');
  }

  void _selectSuggestion(ItemSuggestion suggestion) {
    _nameController.text = suggestion.displayName;
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.displayName.length),
    );
    setState(() {
      _showSuggestions = false;
      _matchingSuggestions = [];
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameFocusNode.removeListener(_onNameFocusChanged);
    _nameController.dispose();
    _amountController.dispose();
    _nameFocusNode.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleStoreSelected(String? storeId) {
    setState(() {
      _selectedStoreId = storeId;
      // Business rule: if store is selected, lookoutFor must be off
      if (storeId != null) {
        _lookoutFor = false;
      }
    });
    // Update last used store
    if (storeId != null) {
      ref.read(lastUsedStoreIdProvider.notifier).state = storeId;
    }
  }

  void _handleLookoutForChanged(bool value) {
    setState(() {
      _lookoutFor = value;
      // Business rule: if lookoutFor is on, store must be null
      if (value) {
        _selectedStoreId = null;
      }
    });
  }

  Future<void> _selectDiscountDates() async {
    final now = DateTime.now();
    final result = await showAutoCloseDateRangePicker(
      context: context,
      initialStart: _discountStart,
      initialEnd: _discountEnd,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (result != null) {
      setState(() {
        _discountStart = result.start;
        _discountEnd = result.end;
      });
    }
  }

  void _clearDiscountDates() {
    setState(() {
      _discountStart = null;
      _discountEnd = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🛒 Creating shopping item...');
      debugPrint('   homeId: ${widget.homeId}');
      debugPrint('   userId: ${widget.userId}');
      debugPrint('   name: ${_nameController.text.trim()}');

      final itemName = _nameController.text.trim();

      final item = ShoppingItem.create(
        name: itemName,
        homeId: widget.homeId,
        createdBy: widget.userId,
        storeId: _selectedStoreId,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text.replaceAll(',', '.'))
            : null,
        amount: _amountController.text.isNotEmpty
            ? int.tryParse(_amountController.text)
            : null,
        important: _important,
        lookoutFor: _lookoutFor,
        discountStart: _discountStart,
        discountEnd: _discountEnd,
      );

      debugPrint('   item.id: ${item.id}');
      debugPrint('   Calling addItem...');

      await ref.read(shoppingServiceProvider).addItem(item);

      // Record item usage for suggestions
      debugPrint('🔄 Recording item usage for suggestions...');
      try {
        await ref
            .read(suggestionsServiceProvider)
            .recordItemUsage(widget.homeId, itemName);
        debugPrint('✅ Item usage recorded');
      } catch (e) {
        debugPrint('❌ Failed to record item usage: $e');
      }

      // Save discount range for next time (if set)
      if (_discountStart != null && _discountEnd != null) {
        ref.read(lastUsedDiscountRangeProvider.notifier).state = (
          start: _discountStart!,
          end: _discountEnd!,
        );
      }

      debugPrint('✅ Item added successfully!');

      HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      debugPrint('❌ Error adding item: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorGeneric} ($e)')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    AppStrings.addItem,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Name field with suggestions overlay
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        autofocus: true, // Helps on native, visual cue on web
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: AppStrings.itemName,
                          hintText: AppStrings.itemNameHint,
                          suffixIcon: _showDuplicateWarning
                              ? Tooltip(
                                  message: _duplicateStoreName != null
                                      ? '${AppStrings.duplicateItemWarning} ${AppStrings.duplicateItemAt} $_duplicateStoreName'
                                      : '${AppStrings.duplicateItemWarning} ${AppStrings.duplicateItemNoStore}',
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.warning,
                                    size: 24,
                                  ),
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.errorRequired;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          // Hide suggestions when pressing enter
                          setState(() => _showSuggestions = false);
                        },
                      ),

                      // Suggestions dropdown - positioned below the text field
                      if (_showSuggestions && _matchingSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMedium),
                            border: Border.all(color: AppColors.lightGray),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _matchingSuggestions
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final suggestion = entry.value;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    debugPrint(
                                        '👆 Suggestion tapped: ${suggestion.displayName}');
                                    _selectSuggestion(suggestion);
                                  },
                                  borderRadius: BorderRadius.vertical(
                                    top: index == 0
                                        ? const Radius.circular(
                                            AppSpacing.radiusMedium)
                                        : Radius.zero,
                                    bottom:
                                        index == _matchingSuggestions.length - 1
                                            ? const Radius.circular(
                                                AppSpacing.radiusMedium)
                                            : Radius.zero,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      border: index <
                                              _matchingSuggestions.length - 1
                                          ? Border(
                                              bottom: BorderSide(
                                                  color: AppColors.lightGray
                                                      .withOpacity(0.5)))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 16,
                                          color: AppColors.gray,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            suggestion.displayName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '${suggestion.useCount}x',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.gray,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Amount and Price row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            labelText: AppStrings.itemAmount,
                            hintText: '1',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]')),
                          ],
                          decoration: InputDecoration(
                            labelText: AppStrings.itemPrice,
                            hintText: '0,00',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Store selection
                  Text(
                    AppStrings.selectStore,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer(
                    builder: (context, ref, _) {
                      final stores =
                          ref.watch(storesProvider).valueOrNull ?? [];
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _buildStoreChip(null, AppStrings.noStore, null),
                          ...stores.map((store) => _buildStoreChip(
                              store.id, store.name, store.emoji)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Discount date range
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.discountPeriod,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      if (_discountStart != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearDiscountDates,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: _selectDiscountDates,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGray),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: _discountStart != null
                                ? AppColors.primaryPurple
                                : AppColors.gray,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _discountStart != null && _discountEnd != null
                                ? '${DateFormat('d/M').format(_discountStart!)} - ${DateFormat('d/M').format(_discountEnd!)}'
                                : 'Vælg datoer',
                            style: TextStyle(
                              color: _discountStart != null
                                  ? AppColors.black
                                  : AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Important and Lookout toggles
                  Row(
                    children: [
                      Expanded(
                        child: _buildToggleOption(
                          icon: Icons.priority_high_rounded,
                          label: AppStrings.markImportant,
                          value: _important,
                          onChanged: (v) => setState(() => _important = v),
                          activeColor: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildToggleOption(
                          icon: Icons.visibility_outlined,
                          label: AppStrings.lookoutFor,
                          value: _lookoutFor,
                          onChanged: _handleLookoutForChanged,
                          activeColor: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      text: AppStrings.add,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreChip(String? storeId, String label, String? emoji) {
    final isSelected = _selectedStoreId == storeId;

    return GestureDetector(
      onTap: () => _handleStoreSelected(storeId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.1) : AppColors.white,
          border: Border.all(
            color: value ? activeColor : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? activeColor : AppColors.gray,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? activeColor : AppColors.gray,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              color: value ? activeColor : AppColors.lightGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Toast overlay widget for duplicate item warning
class _DuplicateToastOverlay extends StatefulWidget {
  final String itemName;
  final String storeText;
  final VoidCallback onDismiss;

  const _DuplicateToastOverlay({
    required this.itemName,
    required this.storeText,
    required this.onDismiss,
  });

  @override
  State<_DuplicateToastOverlay> createState() => _DuplicateToastOverlayState();
}

class _DuplicateToastOverlayState extends State<_DuplicateToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.lg,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '"${widget.itemName}" ${AppStrings.duplicateItemWarning} ${widget.storeText}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
