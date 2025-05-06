import 'package:flutter/foundation.dart';
import 'agent_pathogene.dart';

/// Represents a pathogen signature stored in immune memory
class PathogenSignature {
  final String id;
  final String pathogenId;
  final String pathogenName;
  final String pathogenType; // Virus, Bacterie, Champignon
  final AttackType attackType;
  final Map<AttackType, double> resistanceFactors;
  final DateTime discoveryDate;
  int encounterCount; // How many times this pathogen has been encountered
  
  // Bonus factors applied when fighting this pathogen again
  double damageBonus = 0.2;  // Initial 20% damage increase
  double costReduction = 0.1; // Initial 10% cost reduction
  
  PathogenSignature({
    required this.id,
    required this.pathogenId,
    required this.pathogenName,
    required this.pathogenType,
    required this.attackType,
    required this.resistanceFactors,
    required this.discoveryDate,
    this.encounterCount = 1,
    this.damageBonus = 0.2,
    this.costReduction = 0.1,
  });
  
  // Factory constructor already defined below
  
  /// Increase bonuses when encountering the same pathogen again
  void updateBonuses() {
    encounterCount++;
    
    // Diminishing returns for bonuses
    damageBonus = 0.2 + (0.05 * (encounterCount - 1)); // Each encounter adds 5% up to a cap
    damageBonus = damageBonus.clamp(0.0, 0.5); // Cap at 50% bonus
    
    costReduction = 0.1 + (0.025 * (encounterCount - 1)); // Each encounter adds 2.5% up to a cap
    costReduction = costReduction.clamp(0.0, 0.3); // Cap at 30% reduction
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pathogenId': pathogenId,
      'pathogenName': pathogenName,
      'pathogenType': pathogenType,
      'attackType': attackType.toString(),
      'resistanceFactors': resistanceFactors.map((k, v) => MapEntry(k.toString(), v)),
      'discoveryDate': discoveryDate.toIso8601String(),
      'encounterCount': encounterCount,
      'damageBonus': damageBonus,
      'costReduction': costReduction,
    };
  }
  
  /// Create from map from storage
  factory PathogenSignature.fromMap(Map<String, dynamic> map) {
    return PathogenSignature(
      id: map['id'],
      pathogenId: map['pathogenId'],
      pathogenName: map['pathogenName'],
      pathogenType: map['pathogenType'],
      attackType: AttackType.values.firstWhere(
        (e) => e.toString() == map['attackType'],
        orElse: () => AttackType.physical,
      ),
      resistanceFactors: (map['resistanceFactors'] as Map).map(
        (k, v) => MapEntry(
          AttackType.values.firstWhere(
            (e) => e.toString() == k,
            orElse: () => AttackType.physical,
          ),
          (v as num).toDouble(),
        ),
      ),
      discoveryDate: DateTime.parse(map['discoveryDate']),
      encounterCount: map['encounterCount'] ?? 1,
      damageBonus: map['damageBonus'] ?? 0.2,
      costReduction: map['costReduction'] ?? 0.1,
    );
  }
  
  /// Create from a pathogen
  factory PathogenSignature.fromPathogen(AgentPathogene pathogen) {
    return PathogenSignature(
      id: 'sig_${DateTime.now().millisecondsSinceEpoch}',
      pathogenId: pathogen.id,
      pathogenName: pathogen.name,
      pathogenType: pathogen.runtimeType.toString(),
      attackType: pathogen.attackType,
      resistanceFactors: Map.from(pathogen.resistanceFactors),
      discoveryDate: DateTime.now(),
    );
  }
}

/// Manages the player's immune memory system
class MemoireImmunitaire with ChangeNotifier {
  MemoireImmunitaire();
  final List<PathogenSignature> _signatures = [];
  int _researchPoints = 0;
  
  // Getters
  List<PathogenSignature> get signatures => List.unmodifiable(_signatures);
  int get researchPoints => _researchPoints;
  int get signatureCount => _signatures.length;
  
  /// Add a new pathogen signature to memory from a pathogen object
  void addPathogenSignature(AgentPathogene pathogen) {
    // Check if pathogen is already known
    final existingIndex = _signatures.indexWhere((sig) => sig.pathogenId == pathogen.id);
    
    if (existingIndex >= 0) {
      // Update existing signature
      _signatures[existingIndex].updateBonuses();
    } else {
      // Add new signature
      _signatures.add(PathogenSignature.fromPathogen(pathogen));
      
      // Award research points for new discovery
      _researchPoints += 5; // Base points for new pathogen
    }
    
    notifyListeners();
  }
  
  /// Add a signature from a string name (used for data sync from Firestore)
  void addSignatureFromName(String pathogenName) {
    // Only add if not already present by name
    if (!_signatures.any((sig) => sig.pathogenName == pathogenName)) {
      // Create a basic signature with default values
      final signature = PathogenSignature(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pathogenId: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        pathogenName: pathogenName,
        pathogenType: _determineTypeFromName(pathogenName),
        attackType: AttackType.physical, // Default
        resistanceFactors: {
          AttackType.physical: 1.0,
          AttackType.chemical: 1.0,
          AttackType.energetic: 1.0, // Fixed to use valid AttackType
        },
        discoveryDate: DateTime.now(),
      );
      
      _signatures.add(signature);
      notifyListeners();
    }
  }
  
  /// Add a signature from a string name and return whether it was newly added
  /// Returns true if a new signature was added, false if it already existed
  bool addSignature(String pathogenName) {
    // Check if already present by name
    if (_signatures.any((sig) => sig.pathogenName == pathogenName)) {
      return false; // Already exists
    }
    
    // Create a basic signature with default values
    final signature = PathogenSignature(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pathogenId: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      pathogenName: pathogenName,
      pathogenType: _determineTypeFromName(pathogenName),
      attackType: AttackType.physical, // Default
      resistanceFactors: {
        AttackType.physical: 1.0,
        AttackType.chemical: 1.0,
        AttackType.energetic: 1.0,
      },
      discoveryDate: DateTime.now(),
    );
    
    _signatures.add(signature);
    
    // Award research points for new discovery
    _researchPoints += 5;
    
    notifyListeners();
    return true; // New signature added
  }
  
  /// Determine pathogen type from name
  String _determineTypeFromName(String name) {
    if (name.contains('Virus')) return 'Virus';
    if (name.contains('Staphylococcus') || name.contains('E. Coli') || name.contains('Bacterie')) return 'Bacterie';
    if (name.contains('Candida') || name.contains('Champignon')) return 'Champignon';
    return 'Unknown';
  }
  
  /// Find a signature by pathogen ID
  PathogenSignature? findSignature(String pathogenId) {
    try {
      return _signatures.firstWhere((sig) => sig.pathogenId == pathogenId);
    } catch (e) {
      return null;
    }
  }
  
  /// Find all signatures of a certain pathogen type
  List<PathogenSignature> findSignaturesByType(String pathogenType) {
    return _signatures.where((sig) => sig.pathogenType == pathogenType).toList();
  }
  
  /// Add research points
  void addResearchPoints(int points) {
    if (points > 0) {
      _researchPoints += points;
      notifyListeners();
    }
  }
  
  /// Set research points (used for data sync)
  void setResearchPoints(int points) {
    if (points >= 0) {
      _researchPoints = points;
      notifyListeners();
    }
  }
  
  /// Spend research points
  /// Returns true if successful, false if insufficient points
  bool spendResearchPoints(int points) {
    if (_researchPoints >= points) {
      _researchPoints -= points;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Calculate damage bonus against a specific pathogen
  double getDamageBonus(String pathogenId) {
    final signature = findSignature(pathogenId);
    return signature?.damageBonus ?? 0.0;
  }
  
  /// Calculate cost reduction for antibodies against a specific pathogen
  double getCostReduction(String pathogenId) {
    final signature = findSignature(pathogenId);
    return signature?.costReduction ?? 0.0;
  }
  
  /// Clear all pathogen signatures from memory
  void clearAllSignatures() {
    _signatures.clear();
    notifyListeners();
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'researchPoints': _researchPoints,
      'signatures': _signatures.map((s) => s.toMap()).toList(),
    };
  }
  
  /// Create from map from storage
  factory MemoireImmunitaire.fromMap(Map<String, dynamic> map) {
    final memory = MemoireImmunitaire();
    
    // Load signatures
    if (map.containsKey('signatures')) {
      final sigList = map['signatures'] as List;
      memory._signatures.addAll(
        sigList.map((sigMap) => PathogenSignature.fromMap(sigMap as Map<String, dynamic>))
      );
    }
    
    // Load research points
    if (map.containsKey('researchPoints')) {
      memory._researchPoints = map['researchPoints'];
    }
    
    return memory;
  }
}
