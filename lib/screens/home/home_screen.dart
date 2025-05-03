import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../models/notification.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/game_providers.dart';
import '../../providers/notification_providers.dart';
import '../../services/data_sync_service.dart';
import '../../services/game_state_storage.dart';
import '../laboratory/laboratory_screen.dart';
import '../bioforge/bioforge_screen.dart';
import 'home_screen_energy.dart';
import '../archives/archives_screen.dart';
import '../combat/combat_preparation_screen.dart';
import '../scanner/scanner_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget?> _screens = [
    null, // Dashboard
    const ScannerScreen(),
    const BioForgeScreen(),
    const LaboratoryScreen(),
    const ArchivesScreen(),
    null, // Combat (handled via navigation)
  ];
  
  // Timer for periodic data sync
  Timer? _syncTimer;
  
  @override
  void initState() {
    super.initState();
    // Set up periodic data sync every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncDataToFirestore());
  }
  
  @override
  void dispose() {
    // Cancel timer when widget is disposed
    _syncTimer?.cancel();
    // Final sync when leaving the app
    _syncDataToFirestore();
    super.dispose();
  }
  
  // Sync local state to Firestore
  Future<void> _syncDataToFirestore() async {
    final dataSyncService = ref.read(dataSyncServiceProvider);
    await dataSyncService.syncToFirestore();
  }
  
  /// Build a notification item widget
  Widget _buildNotificationItem(
    BuildContext context, 
    GameNotification notification, 
  ) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          if (!notification.isRead && user != null) {
            ref.read(firestoreServiceProvider).markNotificationAsRead(user.uid, notification.id);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification type icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(notification.icon, color: notification.color, size: 20),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Format a timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      // Format as date if older than a week
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      // Format as days ago
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      // Format as hours ago
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      // Format as minutes ago
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      // Just now
      return 'à l\'instant';
    }
  }
  
  // Reset game data to default values (both locally and in Firestore)
  Future<void> _resetGameData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userId == null || userEmail == null) return;
      
      // Get services and providers
      final firestoreService = ref.read(firestoreServiceProvider);
      final resources = ref.read(resourcesProvider);
      final memoireImmunitaire = ref.read(memoireImmunitaireProvider);
      final laboratoireRecherche = ref.read(laboratoireRechercheProvider);
      
      // 1. Reset all in-memory app state
      // Reset resources to default values
      resources.updateEnergie(100);
      resources.updateBiomateriaux(50);
      
      // Reset research points
      memoireImmunitaire.setResearchPoints(0);
      
      // Reset immune memory signatures
      memoireImmunitaire.clearAllSignatures();
      
      // Reset research progress
      laboratoireRecherche.cancelAllResearch();
      
      // 2. Reset local storage completely
      await GameStateStorage.resetAllData();
      
      // 3. Reset all Firestore data comprehensively
      // This will delete all battles, viral bases, and reset the user profile
      await firestoreService.resetUserData(userId, userEmail);
      
      // 4. Force refresh providers that might be watching Firestore
      // We can safely ignore the AsyncValue results since we just want to trigger a refresh
      final _ = ref.refresh(userProfileProvider);
      final __ = ref.refresh(battleHistoryProvider);
      
      print('Game data completely reset for user: $userId (both locally and online)');
    } catch (e) {
      print('Error resetting game data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final resources = ref.watch(resourcesProvider);
    final memoireImmunitaire = ref.watch(memoireImmunitaireProvider);
    final researchPoints = ref.watch(researchPointsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant

    // If a non-dashboard tab is selected (except Attack), show that screen
    if (_currentIndex > 0 && _currentIndex < 5) {
      return _screens[_currentIndex]!;
    }

    // Always show Tactical Dashboard
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tactical Dashboard'),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
              } else if (value == 'reset') {
                // Show confirmation dialog
                final shouldReset = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Game Data'),
                    content: const Text(
                      'This will reset all your game progress including resources, research points, ' +
                      'immune memory, and battle history to default values. This action cannot be undone.\n\n' +
                      'Are you sure you want to reset your game?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('RESET'),
                      ),
                    ],
                  ),
                ) ?? false;
                
                if (shouldReset) {
                  await _resetGameData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Game data reset successfully')),
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(FirebaseAuth.instance.currentUser?.displayName ?? 'User'),
                  subtitle: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.refresh, color: Colors.orange),
                  title: Text('Reset Game'),
                  subtitle: Text('Reset all progress to default values'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (userProfile) => userProfile == null
            ? const Center(child: Text('User profile not found'))
            : _buildDashboardContent(context, userProfile, resources, memoireImmunitaire, researchPoints),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: Container(
        height: 70,
        padding: const EdgeInsets.only(top: 8),
        color: navyBlue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(Icons.radar, 'Scanner', colorScheme, 1),
            _buildBottomNavItem(Icons.biotech, 'Bio-Forge', colorScheme, 2),
            _buildBottomNavItem(Icons.science, 'Labo R&D', colorScheme, 3),
            _buildBottomNavItem(Icons.menu_book, 'Archives', colorScheme, 4),
            _buildBottomNavItem(Icons.security, 'Attack', colorScheme, 5),

          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, ColorScheme colorScheme, int index) {
    return InkWell(
      onTap: () {
        if (index == 5) {
          // Create a mock target base for quick combat access
          final mockTargetBase = {
            'id': 'quick-combat-${DateTime.now().millisecondsSinceEpoch}',
            'name': 'Base d\'Entraînement',
            'owner': 'Système',
            'ownerId': 'system',
            'threatLevel': 'Facile',
            'pathogens': ['Influenza Virus', 'Candida Albicans'],
            'rewards': {'energie': 20, 'biomateriaux': 15, 'points': 5},
          };
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CombatPreparationScreen(
                targetBase: mockTargetBase,
              ),
            ),
          );
          return;
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, UserProfile userProfile, resources, memoireImmunitaire, int researchPoints) {
    final textTheme = Theme.of(context).textTheme;
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Dashboard Title Section
        Card(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: navyBlue.withOpacity(0.1),
                  child: Icon(Icons.dashboard, color: navyBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${userProfile.displayName.isNotEmpty ? userProfile.displayName : "Commander"}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Système de défense immunitaire numérique',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bio-Resources Card (First Card - as in screenshot)
        Card(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F8FF), // Light blue background
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bolt,
                          color: Color(0xFFFFD700), // Yellow icon
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bio-ressources',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        // Navigate to edit resources
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LaboratoryScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4FD1C5), // Teal color for edit button
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Resources values
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Energy
                    Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFAE6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.bolt,
                                  color: Color(0xFFFFC107),
                                  size: 30,
                                ),
                                // Add small + button to indicate energy can be refilled
                                Positioned(
                                  right: -6,
                                  bottom: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${resources.currentEnergie}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Energie',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    // Bio-materiaux
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showEnergyRefillOptions(context);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.science,
                                color: Color(0xFF4CAF50),
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${resources.currentBiomateriaux}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bio-matériaux',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Immune Memory (Second Card - as in screenshot)
        Card(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD), // Light blue background
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.memory,
                          color: Color(0xFF2196F3), // Blue icon
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mémoire Immunitaire',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Resources values
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Signatures connues
                    Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.memory,
                              color: Color(0xFF2196F3),
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${memoireImmunitaire.signatures.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Signatures connues',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    // Points Recherche
                    Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.science,
                              color: Color(0xFF9C27B0),
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$researchPoints',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Points Recherche',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Alerts Card (Third Card - as in screenshot)
        Card(
          color: const Color(0xFFF3F4F6), // Light gray background
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Text('Alertes / Notifications',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    // Notification count badge
                    Consumer(builder: (context, ref, _) {
                      final unreadCount = ref.watch(unreadNotificationsCountProvider);
                      if (unreadCount > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                // Notifications stream
                Consumer(builder: (context, ref, _) {
                  final notificationsAsync = ref.watch(notificationsProvider);
                  final firestoreService = ref.read(firestoreServiceProvider);
                  
                  return notificationsAsync.when(
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return const Text('Aucune nouvelle alerte.');
                      }
                      
                      // Show the most recent 3 notifications
                      return Column(
                        children: [
                          ...notifications.take(3).map((notification) => 
                            _buildNotificationItem(context, notification)
                          ),
                          if (notifications.length > 3) ...[  
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // Show all notifications in a full-screen dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Toutes les notifications'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: notifications.length,
                                        itemBuilder: (context, index) => _buildNotificationItem(
                                          context, notifications[index]
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('FERMER'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final user = FirebaseAuth.instance.currentUser;
                                          if (user != null) {
                                            await firestoreService.markAllNotificationsAsRead(user.uid);
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        child: const Text('TOUT MARQUER COMME LU'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Voir toutes les notifications'),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Erreur: $error'),
                  );
                }),
              ],
            ),
          ),
        ),

        // Gemini Briefing Card (Fourth Card - as in screenshot)
        Card(
          color: const Color(0xFFF8E9FC), // Light purple background
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and analytics icon
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.purple[700], size: 24),
                    const SizedBox(width: 12),
                    Text('Briefing Analyste IA (Gemini)',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_graph, color: Colors.purple[700], size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Main content section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analytics visualization container
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.purple[700],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Simulated analytics graph
                          Positioned(
                            bottom: 15,
                            left: 15,
                            right: 15,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                5,
                                (index) => Container(
                                  width: 6,
                                  height: 10.0 + (index * 5.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7 + (index * 0.05)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Analytics icon overlay
                          const Icon(Icons.analytics, color: Colors.white, size: 40),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber[700]),
                              const SizedBox(width: 8),
                              Text('Analyse Tactique',
                                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text("En attente d'un briefing tactique...",
                            style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.refresh, size: 14, color: Colors.purple[400]),
                              const SizedBox(width: 4),
                              Text('Mise à jour: maintenant',
                                style: TextStyle(fontSize: 12, color: Colors.purple[400])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
