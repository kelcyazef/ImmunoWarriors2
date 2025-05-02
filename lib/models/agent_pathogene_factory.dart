import 'dart:math';
import 'agent_pathogene.dart';

/// Factory class for creating different types of pathogens
class AgentPathogeneFactory {
  static final Random _random = Random();
  
  /// Create a virus pathogen
  static AgentPathogene createVirus({String? name, int? healthPoints, int? damage}) {
    return Virus(
      id: 'virus_${_random.nextInt(10000)}',
      name: name ?? 'Influenza Virus',
      maxHealthPoints: healthPoints ?? 40,
      armor: 5.0,
      attackType: AttackType.physical,
      damage: damage ?? 12,
      initiative: 15,
      resistanceFactors: {
        AttackType.physical: 1.0,
        AttackType.chemical: 1.5, // Weak to chemical
        AttackType.energetic: 0.8, // Resistant to energetic
      },
    );
  }
  
  /// Create a bacteria pathogen
  static AgentPathogene createBacteria({String? name, int? healthPoints, int? damage}) {
    return Bacteria(
      id: 'bacteria_${_random.nextInt(10000)}',
      name: name ?? 'Staphylococcus',
      maxHealthPoints: healthPoints ?? 60,
      armor: 15.0,
      attackType: AttackType.chemical,
      damage: damage ?? 8,
      initiative: 10,
      resistanceFactors: {
        AttackType.physical: 0.8, // Resistant to physical
        AttackType.chemical: 1.0,
        AttackType.energetic: 1.5, // Weak to energetic
      },
    );
  }
  
  /// Create a fungus pathogen
  static AgentPathogene createFungus({String? name, int? healthPoints, int? damage}) {
    return Fungus(
      id: 'fungus_${_random.nextInt(10000)}',
      name: name ?? 'Candida Albicans',
      maxHealthPoints: healthPoints ?? 50,
      armor: 10.0,
      attackType: AttackType.energetic,
      damage: damage ?? 10,
      initiative: 8,
      resistanceFactors: {
        AttackType.physical: 1.5, // Weak to physical
        AttackType.chemical: 0.8, // Resistant to chemical
        AttackType.energetic: 1.0,
      },
    );
  }
}

/// Virus implementation
class Virus extends AgentPathogene {
  Virus({
    required super.id,
    required super.name,
    required super.maxHealthPoints,
    required super.armor,
    required super.attackType,
    required super.damage,
    required super.initiative,
    required super.resistanceFactors,
  });
  
  // Virus special ability: Mutation (chance to avoid damage)
  @override
  int receiveDamage(int incomingDamage, AttackType attackType) {
    // 20% chance to mutate and avoid damage
    if (Random().nextDouble() < 0.2) {
      return 0; // No damage taken
    }
    
    return super.receiveDamage(incomingDamage, attackType);
  }
  
  @override
  void executeSpecialCapability() {
    // Mutation is handled in receiveDamage
  }
  
  @override
  int attack() {
    return damage;
  }
}

/// Bacteria implementation
class Bacteria extends AgentPathogene {
  Bacteria({
    required super.id,
    required super.name,
    required super.maxHealthPoints,
    required super.armor,
    required super.attackType,
    required super.damage,
    required super.initiative,
    required super.resistanceFactors,
  });
  
  // Bacteria special ability: Biofilm (reduces damage)
  @override
  int receiveDamage(int incomingDamage, AttackType attackType) {
    // Biofilm reduces damage by 25%
    final reducedDamage = (incomingDamage * 0.75).round();
    return super.receiveDamage(reducedDamage, attackType);
  }
  
  @override
  void executeSpecialCapability() {
    // Biofilm is handled in receiveDamage
  }
  
  @override
  int attack() {
    return damage;
  }
}

/// Fungus implementation
class Fungus extends AgentPathogene {
  Fungus({
    required super.id,
    required super.name,
    required super.maxHealthPoints,
    required super.armor,
    required super.attackType,
    required super.damage,
    required super.initiative,
    required super.resistanceFactors,
  });
  
  // Fungus special ability: Spore Burst (chance for extra damage)
  @override
  int attack() {
    final baseDamage = super.attack();
    
    // 30% chance for spore burst (extra damage)
    if (Random().nextDouble() < 0.3) {
      final extraDamage = (damage * 0.5).round();
      return baseDamage + extraDamage;
    }
    
    return baseDamage;
  }
  
  @override
  void executeSpecialCapability() {
    // Spore Burst is handled in attack
  }
}
