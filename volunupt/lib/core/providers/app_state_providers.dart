import 'package:flutter_riverpod/flutter_riverpod.dart';

final appInitializationProvider = StateNotifierProvider<AppInitializationNotifier, AppInitializationState>((ref) {
  return AppInitializationNotifier();
});

class AppInitializationNotifier extends StateNotifier<AppInitializationState> {
  AppInitializationNotifier() : super(const AppInitializationState());

  void markAsInitialized() {
    state = state.copyWith(hasShownSplash: true);
  }

  void reset() {
    state = const AppInitializationState();
  }
}

class AppInitializationState {
  final bool hasShownSplash;

  const AppInitializationState({
    this.hasShownSplash = false,
  });

  AppInitializationState copyWith({
    bool? hasShownSplash,
  }) {
    return AppInitializationState(
      hasShownSplash: hasShownSplash ?? this.hasShownSplash,
    );
  }
}