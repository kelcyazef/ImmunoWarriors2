import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/laboratoire_recherche.dart';
import '../../providers/game_providers.dart';
import '../../providers/firestore_providers.dart';
import '../../models/user_profile.dart';

/// Screen for researching new technologies and improvements
class LaboratoryScreen extends ConsumerWidget {
  const LaboratoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final laboratoire = ref.watch(laboratoireRechercheProvider);
    final researchPoints = ref.watch(researchPointsProvider);
    final activeResearch = ref.watch(activeResearchProvider);
    const navyBlue = Color(0xFF0A2342); // Navy blue color constant
    
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
        ),
        title: const Text('Laboratoire R&D'),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          // Info button to show laboratory purpose
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Laboratoire de Recherche'),
                  content: const Text(
                    'Le Laboratoire R&D vous permet de rechercher de nouvelles technologies pour améliorer vos anticorps, '
                    'augmenter votre production de ressources, renforcer votre immunité et développer votre Bio-Forge.\n\n'
                    'Dépensez vos points de recherche pour débloquer des avantages stratégiques contre les agents pathogènes.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Compris'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (userProfile) => _buildLaboratoryContent(
          context, 
          userProfile, 
          laboratoire, 
          researchPoints,
          activeResearch,
          ref
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error', style: const TextStyle(color: Colors.black87)),
        ),
      ),
    );
  }
  
  Widget _buildLaboratoryContent(
    BuildContext context, 
    UserProfile? userProfile, 
    LaboratoireRecherche laboratoire,
    int researchPoints,
    ResearchTech? activeResearch,
    WidgetRef ref
  ) {
    // Colors
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    
    // If profile is null, show a friendly message with retry button
    if (userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined, size: 64, color: primaryColor),
            const SizedBox(height: 16),
            const Text('Unable to load laboratory data', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            )
          ],
        ),
      );
    }
    
    // Get technologies by type
    final antibodyTechs = laboratoire.technologies
        .where((tech) => tech.type == ResearchType.antibody)
        .toList();
    
    final resourceTechs = laboratoire.technologies
        .where((tech) => tech.type == ResearchType.resources)
        .toList();
    
    final immunityTechs = laboratoire.technologies
        .where((tech) => tech.type == ResearchType.immunity)
        .toList();
    
    final bioforgeTechs = laboratoire.technologies
        .where((tech) => tech.type == ResearchType.bioforge)
        .toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Laboratory header with research points
        Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.science, size: 28, color: primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laboratoire de Recherche', 
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.psychology, size: 16, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Points de Recherche: $researchPoints',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Améliorez vos technologies pour renforcer votre système immunitaire',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Active research progress card
                if (activeResearch != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Recherche en cours:',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeResearch.name,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final progressAsync = ref.watch(researchProgressProvider);
                            return progressAsync.when(
                              data: (progress) => LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const LinearProgressIndicator(value: 0),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Temps restant: ${activeResearch.getRemainingTime()}s',
                                style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                laboratoire.cancelResearch();
                              },
                              icon: const Icon(Icons.cancel, size: 16),
                              label: const Text('Annuler'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        if (antibodyTechs.isNotEmpty)
          _buildCategoryCard(
            context,
            'Technologies Anticorps',
            'Améliorez vos anticorps et leurs capacités offensives.',
            Icons.local_hospital,
            Colors.red[700]!,
            antibodyTechs,
            researchPoints,
            laboratoire,
            ref,
          ),
        
        if (resourceTechs.isNotEmpty)
          _buildCategoryCard(
            context,
            'Technologies de Ressources',
            'Augmentez votre production et stockage de ressources.',
            Icons.account_balance,
            Colors.green[700]!,
            resourceTechs,
            researchPoints,
            laboratoire,
            ref,
          ),
        
        if (immunityTechs.isNotEmpty)
          _buildCategoryCard(
            context,
            'Technologies d\'Immunité',
            'Améliorez votre mémoire immunitaire et défenses passives.',
            Icons.shield,
            Colors.blue[700]!,
            immunityTechs,
            researchPoints,
            laboratoire,
            ref,
          ),
        
        if (bioforgeTechs.isNotEmpty)
          _buildCategoryCard(
            context,
            'Technologies Bio-Forge',
            'Améliorez les capacités de création et d\'évolution d\'anticorps.',
            Icons.build,
            Colors.amber[700]!,
            bioforgeTechs,
            researchPoints,
            laboratoire,
            ref,
          ),
      ],
    );
  }
  
  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    List<ResearchTech> technologies,
    int availablePoints,
    LaboratoireRecherche laboratoire,
    WidgetRef ref,
  ) {
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Technologies list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: technologies.map((tech) => _buildTechnologyItem(
                context, 
                tech, 
                color, 
                availablePoints,
                laboratoire,
                ref,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTechnologyItem(
    BuildContext context,
    ResearchTech tech,
    Color color,
    int availablePoints,
    LaboratoireRecherche laboratoire,
    WidgetRef ref,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Status styling
    IconData statusIcon;
    Color statusColor;
    bool canResearch = false;
    
    switch (tech.status) {
      case ResearchStatus.available:
        statusIcon = Icons.check_circle_outline;
        statusColor = Colors.green;
        canResearch = availablePoints >= tech.cost;
        break;
      case ResearchStatus.inProgress:
        statusIcon = Icons.hourglass_top;
        statusColor = Colors.orange;
        canResearch = false;
        break;
      case ResearchStatus.completed:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        canResearch = false;
        break;
      case ResearchStatus.locked:
        statusIcon = Icons.lock;
        statusColor = Colors.grey;
        canResearch = false;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tech.status == ResearchStatus.locked 
            ? Colors.grey[300]! 
            : color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tech.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tech.status == ResearchStatus.locked 
                      ? Colors.grey 
                      : primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tech.description,
                  style: TextStyle(
                    fontSize: 12, 
                    color: tech.status == ResearchStatus.locked 
                      ? Colors.grey 
                      : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science,
                          size: 14,
                          color: color.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Coût: ${tech.cost} points',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (tech.status == ResearchStatus.available)
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: canResearch ? () {
                            if (laboratoire.startResearch(tech.id, availablePoints)) {
                              // Simply refresh the providers and let the UI update naturally
                              // No need to store the return values as we're just forcing a UI refresh
                              ref.invalidate(activeResearchProvider);
                              ref.invalidate(laboratoireRechercheProvider);
                              // Log the change
                              debugPrint('Research started on: ${tech.name}');
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(canResearch ? 'Rechercher' : 'Points Insuffisants'),
                        ),
                      )
                    else if (tech.status == ResearchStatus.inProgress)
                      Text(
                        'En cours...',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else if (tech.status == ResearchStatus.completed)
                      Text(
                        'Recherche Terminée',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        'Verrouillé',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
