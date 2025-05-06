import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immunowarriors/services/gemini_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  throw UnimplementedError('Provider needs to be overridden in main.dart');
});

// Provider for battle chronicles
final battleChronicleProvider = FutureProvider.family<String, Map<String, dynamic>>((ref, battleData) {
  final geminiService = ref.watch(geminiServiceProvider);
  return geminiService.generateBattleChronicle(battleData);
});

// Timeout provider for tactical advice - auto-cancels after 6 seconds
final tacticalAdviceTimeoutProvider = Provider<void>((ref) {
  // Create a timer that automatically throws a timeout after 6 seconds
  final timer = Timer(const Duration(seconds: 6), () {
    ref.invalidate(tacticalAdviceProvider);
  });
  
  // Dispose timer when provider is removed
  ref.onDispose(() {
    timer.cancel();
  });
});

// Provider for tactical advice with timeout
final tacticalAdviceProvider = FutureProvider.family<String, Map<String, dynamic>>((ref, data) {
  final geminiService = ref.watch(geminiServiceProvider);
  
  // Create a default fallback message based on enemy data
  String fallbackMessage = 'Deploy Killer Cells against enemies. Use Macrophages as tanks and Lymphocytes for support.';
  
  // If we have enemy data, customize the fallback message
  if (data.containsKey('enemyBase') && 
      data['enemyBase'] != null && 
      data['enemyBase']['units'] is List && 
      (data['enemyBase']['units'] as List).isNotEmpty) {
    final firstEnemy = (data['enemyBase']['units'] as List)[0];
    if (firstEnemy.containsKey('name')) {
      fallbackMessage = 'Deploy Killer Cells against ${firstEnemy['name']}. Use Macrophages as tanks and Lymphocytes for support.';
    }
  }
  
  // Make API call with better error handling
  return geminiService.generateTacticalAdvice(data['playerState'], data['enemyBase'])
    .timeout(
      const Duration(seconds: 5),
      onTimeout: () => fallbackMessage,
    )
    .catchError((error) {
      print('Tactical advice error: $error');
      return fallbackMessage;
    });
});
