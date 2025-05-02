import 'dart:math';

/// Types of attacks that can be performed
enum AttackType {
  physical,   // Direct physical damage
  chemical,   // Chemical/toxin attacks
  energetic,  // Energy-based attacks
}

/// Base abstract class for all pathogenic agents
abstract class AgentPathogene {
  final String id;
  final String name;
  int healthPoints;
  final int maxHealthPoints;
  final double armor;
  final AttackType attackType;
  final int damage;
  final int initiative; // Higher goes first in combat
  
  // Resistance and weakness factors
  Map<AttackType, double> resistanceFactors;
  
  // Constructor
  AgentPathogene({
    required this.id,
    required this.name,
    required this.maxHealthPoints,
    required this.armor,
    required this.attackType,
    required this.damage,
    required this.initiative,
    required this.resistanceFactors,
  }) : healthPoints = maxHealthPoints;
  
  /// Calculate damage received based on resistance factors
  int receiveDamage(int incomingDamage, AttackType attackType) {
    // Get resistance factor for this attack type (default to 1.0 if not specified)
    final factor = resistanceFactors[attackType] ?? 1.0;
    
    // Apply armor reduction and resistance factor
    final reducedDamage = (incomingDamage * factor * (1 - (armor / 100))).round();
    final actualDamage = max(1, reducedDamage); // Minimum 1 damage
    
    // Apply damage to health
    healthPoints = max(0, healthPoints - actualDamage);
    
    return actualDamage;
  }
  
  /// Check if pathogen is defeated
  bool get isDefeated => healthPoints <= 0;
  
  /// Perform an attack (base implementation)
  int attack() {
    return damage;
  }
  
  /// Execute special capability (to be implemented by subclasses)
  void executeSpecialCapability();
  
  /// Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'healthPoints': healthPoints,
      'maxHealthPoints': maxHealthPoints,
      'armor': armor,
      'attackType': attackType.toString(),
      'damage': damage,
      'initiative': initiative,
      'resistanceFactors': resistanceFactors.map((k, v) => MapEntry(k.toString(), v)),
      'type': runtimeType.toString(),
    };
  }
}

/// Virus pathogen - specializes in quick mutations and evasion
class Virus extends AgentPathogene {
  bool _mutationActive = false;
  AttackType _originalAttackType;
  
  Virus({
    required String id,
    required String name,
    required int maxHealthPoints,
    required double armor,
    required AttackType attackType,
    required int damage,
    required int initiative,
    required Map<AttackType, double> resistanceFactors,
  }) : _originalAttackType = attackType,
       super(
         id: id,
         name: name,
         maxHealthPoints: maxHealthPoints,
         armor: armor,
         attackType: attackType,
         damage: damage,
         initiative: initiative,
         resistanceFactors: resistanceFactors,
       );
       
  /// Special capability: Rapid Mutation
  /// Changes attack type and can modify resistances temporarily
  @override
  void executeSpecialCapability() {
    if (_mutationActive) return; // Already mutated
    
    _mutationActive = true;
    
    // Create a list of attack types excluding current one
    final attackTypes = AttackType.values.where((type) => type != attackType).toList();
    
    // Randomly select a new attack type
    final random = Random();
    final newAttackType = attackTypes[random.nextInt(attackTypes.length)];
    
    // Store the original for reverting later
    _originalAttackType = attackType;
    
    // Adjust resistances temporarily
    for (final type in AttackType.values) {
      if (resistanceFactors.containsKey(type)) {
        if (type == newAttackType) {
          // Become more resistant to the new attack type
          resistanceFactors[type] = (resistanceFactors[type]! * 0.5); // 50% reduction
        } else {
          // Become more vulnerable to other types
          resistanceFactors[type] = (resistanceFactors[type]! * 1.2); // 20% increase
        }
      }
    }
  }
  
  /// Revert mutation after a few turns
  void revertMutation() {
    if (!_mutationActive) return;
    
    _mutationActive = false;
    // Restore original values (could be implemented)
  }
  
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['mutationActive'] = _mutationActive;
    map['originalAttackType'] = _originalAttackType.toString();
    return map;
  }
  
  factory Virus.fromMap(Map<String, dynamic> map) {
    return Virus(
      id: map['id'],
      name: map['name'],
      maxHealthPoints: map['maxHealthPoints'],
      armor: map['armor'],
      attackType: AttackType.values.firstWhere(
        (e) => e.toString() == map['attackType'],
        orElse: () => AttackType.physical,
      ),
      damage: map['damage'],
      initiative: map['initiative'],
      resistanceFactors: (map['resistanceFactors'] as Map).map(
        (k, v) => MapEntry(
          AttackType.values.firstWhere(
            (e) => e.toString() == k,
            orElse: () => AttackType.physical,
          ),
          (v as num).toDouble(),
        ),
      ),
    );
  }
}

/// Bacteria pathogen - specializes in shields and protection
class Bacterie extends AgentPathogene {
  bool _biofilmActive = false;
  double _biofilmDamageReduction = 0.4; // 40% damage reduction
  
  // Getter for private property
  bool get biofilmActive => _biofilmActive;
  
  Bacterie({
    required String id,
    required String name,
    required int maxHealthPoints,
    required double armor,
    required AttackType attackType,
    required int damage,
    required int initiative,
    required Map<AttackType, double> resistanceFactors,
    double? biofilmDamageReduction,
  }) : _biofilmDamageReduction = biofilmDamageReduction ?? 0.4,
       super(
         id: id,
         name: name,
         maxHealthPoints: maxHealthPoints,
         armor: armor,
         attackType: attackType,
         damage: damage,
         initiative: initiative,
         resistanceFactors: resistanceFactors,
       );
       
  /// Special capability: Biofilm Shield
  /// Creates a protective layer that reduces incoming damage
  @override
  void executeSpecialCapability() {
    if (!_biofilmActive) {
      _biofilmActive = true;
    }
  }
  
  /// Override receiveDamage to account for biofilm shield
  @override
  int receiveDamage(int incomingDamage, AttackType attackType) {
    if (_biofilmActive) {
      // Apply biofilm reduction
      incomingDamage = (incomingDamage * (1 - _biofilmDamageReduction)).round();
      
      // Biofilm has a chance to break after damage
      final random = Random();
      if (random.nextDouble() < 0.3) { // 30% chance to break
        _biofilmActive = false;
      }
    }
    
    // Use the parent class implementation for normal damage calculation
    return super.receiveDamage(incomingDamage, attackType);
  }
  
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['biofilmActive'] = _biofilmActive;
    map['biofilmDamageReduction'] = _biofilmDamageReduction;
    return map;
  }
  
  factory Bacterie.fromMap(Map<String, dynamic> map) {
    return Bacterie(
      id: map['id'],
      name: map['name'],
      maxHealthPoints: map['maxHealthPoints'],
      armor: map['armor'],
      attackType: AttackType.values.firstWhere(
        (e) => e.toString() == map['attackType'],
        orElse: () => AttackType.physical,
      ),
      damage: map['damage'],
      initiative: map['initiative'],
      resistanceFactors: (map['resistanceFactors'] as Map).map(
        (k, v) => MapEntry(
          AttackType.values.firstWhere(
            (e) => e.toString() == k,
            orElse: () => AttackType.physical,
          ),
          (v as num).toDouble(),
        ),
      ),
      biofilmDamageReduction: map['biofilmDamageReduction'],
    );
  }
}

/// Fungus pathogen - specializes in spore production and area effects
class Champignon extends AgentPathogene {
  bool _sporesReleased = false;
  int _sporesDamage = 2; // Per-turn damage when spores active
  
  // Getter for private property
  bool get sporesReleased => _sporesReleased;
  
  Champignon({
    required String id,
    required String name,
    required int maxHealthPoints,
    required double armor,
    required AttackType attackType,
    required int damage,
    required int initiative,
    required Map<AttackType, double> resistanceFactors,
    int? sporesDamage,
  }) : _sporesDamage = sporesDamage ?? 2,
       super(
         id: id,
         name: name,
         maxHealthPoints: maxHealthPoints,
         armor: armor,
         attackType: attackType,
         damage: damage,
         initiative: initiative,
         resistanceFactors: resistanceFactors,
       );
       
  /// Special capability: Corrosive Spores
  /// Releases spores that deal damage over time
  @override
  void executeSpecialCapability() {
    _sporesReleased = true;
  }
  
  /// Get the spore damage amount (for CombatManager to apply)
  int getSporesDamage() {
    return _sporesReleased ? _sporesDamage : 0;
  }
  
  /// Attack with additional spore damage if active
  @override
  int attack() {
    // Base damage plus spore damage if active
    return super.attack() + (_sporesReleased ? _sporesDamage : 0);
  }
  
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['sporesReleased'] = _sporesReleased;
    map['sporesDamage'] = _sporesDamage;
    return map;
  }
  
  factory Champignon.fromMap(Map<String, dynamic> map) {
    return Champignon(
      id: map['id'],
      name: map['name'], 
      maxHealthPoints: map['maxHealthPoints'],
      armor: map['armor'],
      attackType: AttackType.values.firstWhere(
        (e) => e.toString() == map['attackType'],
        orElse: () => AttackType.physical,
      ),
      damage: map['damage'],
      initiative: map['initiative'],
      resistanceFactors: (map['resistanceFactors'] as Map).map(
        (k, v) => MapEntry(
          AttackType.values.firstWhere(
            (e) => e.toString() == k,
            orElse: () => AttackType.physical,
          ),
          (v as num).toDouble(),
        ),
      ),
      sporesDamage: map['sporesDamage'],
    );
  }
}

/// Factory to create different pathogens
class PathogeenFactory {
  /// Create common virus variants
  static Virus createInfluenzaVirus() {
    return Virus(
      id: 'virus_influenza_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Influenza Virus',
      maxHealthPoints: 75,
      armor: 10.0,
      attackType: AttackType.chemical,
      damage: 15,
      initiative: 20, // Fast-acting
      resistanceFactors: {
        AttackType.physical: 1.2,    // Slightly resistant
        AttackType.chemical: 0.8,    // Slightly vulnerable 
        AttackType.energetic: 1.5,   // Very resistant
      },
    );
  }
  
  /// Create strong bacteria
  static Bacterie createStaphBacteria() {
    return Bacterie(
      id: 'bacteria_staph_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Staphylococcus',
      maxHealthPoints: 120,
      armor: 25.0,
      attackType: AttackType.physical,
      damage: 12,
      initiative: 10, // Slower
      resistanceFactors: {
        AttackType.physical: 0.7,    // Vulnerable
        AttackType.chemical: 1.3,    // Resistant
        AttackType.energetic: 1.0,   // Neutral
      },
      biofilmDamageReduction: 0.5,   // Strong biofilm
    );
  }
  
  /// Create fungal pathogen
  static Champignon createCandidaFungus() {
    return Champignon(
      id: 'fungus_candida_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Candida Albicans',
      maxHealthPoints: 90,
      armor: 15.0, 
      attackType: AttackType.energetic,
      damage: 10,
      initiative: 5, // Very slow
      resistanceFactors: {
        AttackType.physical: 1.1,    // Slightly resistant
        AttackType.chemical: 0.6,    // Very vulnerable
        AttackType.energetic: 1.2,   // Resistant
      },
      sporesDamage: 3,               // Moderate spore damage
    );
  }
}
