import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resources.dart';
import '../models/memoire_immunitaire.dart';
import '../models/laboratoire_recherche.dart';
import '../models/combat_manager.dart';

// Resources provider
final resourcesProvider = ChangeNotifierProvider<ResourcesDefensive>((ref) {
  return ResourcesDefensive(
    currentEnergie: 100,
    maxEnergie: 100,
    energieRegenerationRate: 5,
    currentBiomateriaux: 50,
    maxBiomateriaux: 100,
    biomateriauxRegenerationRate: 3,
  );
});

// Immune memory provider
final memoireImmunitaireProvider = ChangeNotifierProvider<MemoireImmunitaire>((ref) {
  return MemoireImmunitaire();
});

// Research lab provider
final laboratoireRechercheProvider = ChangeNotifierProvider<LaboratoireRecherche>((ref) {
  return LaboratoireRecherche();
});

// Combat manager provider
final combatManagerProvider = ChangeNotifierProvider<CombatManager>((ref) {
  final combatManager = CombatManager();
  // Connect to immune memory system
  combatManager.setMemoireImmunitaire(ref.watch(memoireImmunitaireProvider));
  return combatManager;
});

// Provider for active research
final activeResearchProvider = Provider<ResearchTech?>((ref) {
  final laboratoire = ref.watch(laboratoireRechercheProvider);
  return laboratoire.currentResearch;
});

// Provider for research progress
final researchProgressProvider = StreamProvider.autoDispose<double>((ref) {
  final activeResearch = ref.watch(activeResearchProvider);
  
  // If no active research, return 0 progress
  if (activeResearch == null) {
    return Stream.value(0.0);
  }
  
  // Create a stream that updates every second with current progress
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final totalTime = activeResearch.researchTime;
    final remainingTime = activeResearch.getRemainingTime();
    
    // Calculate progress percentage
    if (totalTime <= 0) return 1.0;
    return (totalTime - remainingTime) / totalTime;
  });
});

// Provider for the number of known signatures
final signatureCountProvider = Provider<int>((ref) {
  final memoire = ref.watch(memoireImmunitaireProvider);
  return memoire.signatureCount;
});

// Provider for research points
final researchPointsProvider = Provider<int>((ref) {
  final memoire = ref.watch(memoireImmunitaireProvider);
  return memoire.researchPoints;
});
