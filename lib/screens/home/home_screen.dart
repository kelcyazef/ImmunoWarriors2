import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/game_providers.dart';
import '../laboratory/laboratory_screen.dart';
import '../bioforge/bioforge_screen.dart';
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
              if (value == 'logout') await FirebaseAuth.instance.signOut();
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CombatPreparationScreen(
                enemyBaseName: 'Enemy Base',
                enemyPathogens: [],
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
    final colorScheme = Theme.of(context).colorScheme;
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
                          child: const Center(
                            child: Icon(
                              Icons.bolt,
                              color: Color(0xFFFFC107),
                              size: 30,
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
                        Container(
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
                  children: [
                    const Icon(Icons.notifications, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Text('Alertes / Notifications',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Aucune nouvelle alerte.'),
              ],
            ),
          ),
        ),

        // Gemini Briefing Card (Fourth Card - as in screenshot)
        Card(
          color: const Color(0xFFF8E9FC), // Light purple background
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // This would be a screenshot from the dashboard as shown in the image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Briefing Analyste IA (Gemini)',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("En attente d'un briefing tactique...",
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
