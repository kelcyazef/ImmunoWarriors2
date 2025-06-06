import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'auth_providers.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  
  return ref.watch(firestoreServiceProvider).getUserProfile(user.uid);
});

// Provider for enemy viral bases
final enemyBasesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).getEnemyBases(user.uid);
});

// Provider for battle history
final battleHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).getBattleHistory(user.uid);
});
