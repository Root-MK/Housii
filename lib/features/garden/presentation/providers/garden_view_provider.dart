import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the state of the Garden Visual Tab view.
/// This allows MainShellScreen to control and observe the Garden's edit mode.

class GardenViewState {
  final bool isEditMode;
  final int tabIndex; // 0 = List, 1 = Visual

  const GardenViewState({
    this.isEditMode = false,
    this.tabIndex = 0,
  });

  GardenViewState copyWith({
    bool? isEditMode,
    int? tabIndex,
  }) {
    return GardenViewState(
      isEditMode: isEditMode ?? this.isEditMode,
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }
}

class GardenViewNotifier extends StateNotifier<GardenViewState> {
  GardenViewNotifier() : super(const GardenViewState());

  void setTabIndex(int index) {
    state = state.copyWith(tabIndex: index);
  }

  void toggleEditMode() {
    state = state.copyWith(isEditMode: !state.isEditMode);
  }

  void setEditMode(bool value) {
    state = state.copyWith(isEditMode: value);
  }

  void exitEditMode() {
    state = state.copyWith(isEditMode: false);
  }
}

final gardenViewProvider = StateNotifierProvider<GardenViewNotifier, GardenViewState>((ref) {
  return GardenViewNotifier();
});
