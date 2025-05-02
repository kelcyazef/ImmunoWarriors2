import 'package:flutter/foundation.dart';

/// Type of research technology
enum ResearchType {
  antibody,      // Antibody improvements
  resources,     // Resource generation and capacity
  immunity,      // Immune memory effectiveness
  bioforge,      // Base construction and defense
}

/// Status of research
enum ResearchStatus {
  available,     // Available to research
  inProgress,    // Currently being researched
  completed,     // Research completed
  locked,        // Not yet available (prerequisites not met)
}

/// Research technology that can be unlocked
class ResearchTech {
  final String id;
  final String name;
  final String description;
  final ResearchType type;
  final int cost;           // Research points cost
  final int researchTime;   // Time in seconds to complete
  final List<String> prerequisites; // IDs of tech required before this
  final Map<String, dynamic> effects; // Different effects based on tech
  
  ResearchStatus status;
  DateTime? startTime;
  DateTime? completionTime;
  
  ResearchTech({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    required this.researchTime,
    this.prerequisites = const [],
    required this.effects,
    this.status = ResearchStatus.locked,
  });
  
  /// Check if research is complete
  bool get isComplete => status == ResearchStatus.completed;
  
  /// Check if research can be started based on prerequisites
  bool canResearch(List<ResearchTech> completedTechs) {
    if (status != ResearchStatus.locked && status != ResearchStatus.available) {
      return false;
    }
    
    // If no prerequisites, always available
    if (prerequisites.isEmpty) {
      return true;
    }
    
    // Check if all prerequisites are completed
    for (final prereqId in prerequisites) {
      final prereq = completedTechs.where((tech) => tech.id == prereqId).toList();
      if (prereq.isEmpty || !prereq.first.isComplete) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Start research
  void startResearch() {
    if (status == ResearchStatus.available) {
      status = ResearchStatus.inProgress;
      startTime = DateTime.now();
      completionTime = startTime!.add(Duration(seconds: researchTime));
    }
  }
  
  /// Check if research has completed based on current time
  bool checkCompletion() {
    if (status == ResearchStatus.inProgress && completionTime != null) {
      if (DateTime.now().isAfter(completionTime!)) {
        status = ResearchStatus.completed;
        return true;
      }
    }
    return false;
  }
  
  /// Get remaining time in seconds
  int getRemainingTime() {
    if (status != ResearchStatus.inProgress || completionTime == null) {
      return 0;
    }
    
    final remaining = completionTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'cost': cost,
      'researchTime': researchTime,
      'prerequisites': prerequisites,
      'effects': effects,
      'status': status.toString(),
      'startTime': startTime?.toIso8601String(),
      'completionTime': completionTime?.toIso8601String(),
    };
  }
  
  /// Create from map from storage
  factory ResearchTech.fromMap(Map<String, dynamic> map) {
    final tech = ResearchTech(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: ResearchType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ResearchType.antibody,
      ),
      cost: map['cost'],
      researchTime: map['researchTime'],
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      effects: Map<String, dynamic>.from(map['effects'] ?? {}),
      status: ResearchStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ResearchStatus.locked,
      ),
    );
    
    if (map.containsKey('startTime') && map['startTime'] != null) {
      tech.startTime = DateTime.parse(map['startTime']);
    }
    
    if (map.containsKey('completionTime') && map['completionTime'] != null) {
      tech.completionTime = DateTime.parse(map['completionTime']);
    }
    
    return tech;
  }
}

/// Manages all research technologies and their progress
class LaboratoireRecherche with ChangeNotifier {
  final List<ResearchTech> _technologies = [];
  ResearchTech? _currentResearch;
  
  // Getters
  List<ResearchTech> get technologies => List.unmodifiable(_technologies);
  ResearchTech? get currentResearch => _currentResearch;
  
  // Filtered getters
  List<ResearchTech> get availableTechs => 
      _technologies.where((tech) => tech.status == ResearchStatus.available).toList();
  List<ResearchTech> get completedTechs => 
      _technologies.where((tech) => tech.status == ResearchStatus.completed).toList();
  bool get hasActiveResearch => _currentResearch != null;
  
  /// Initialize with default technologies
  LaboratoireRecherche() {
    _initializeDefaultTechnologies();
  }
  
  /// Initialize the basic research tree
  void _initializeDefaultTechnologies() {
    // Basic antibody research
    _technologies.add(ResearchTech(
      id: 'tech_antibody_basic',
      name: 'Basic Antibody Enhancements',
      description: 'Improves the basic capabilities of all antibodies.',
      type: ResearchType.antibody,
      cost: 10,
      researchTime: 60, // 1 minute
      prerequisites: [],
      effects: {
        'antibody_damage_bonus': 0.15, // 15% damage increase
      },
      status: ResearchStatus.available, // Initially available
    ));
    
    // Advanced antibody research
    _technologies.add(ResearchTech(
      id: 'tech_antibody_advanced',
      name: 'Advanced Antibody Capabilities',
      description: 'Unlocks specialized antibody abilities.',
      type: ResearchType.antibody,
      cost: 25,
      researchTime: 180, // 3 minutes
      prerequisites: ['tech_antibody_basic'],
      effects: {
        'antibody_special_cooldown_reduction': 0.2, // 20% cooldown reduction
      },
    ));
    
    // Basic resource management
    _technologies.add(ResearchTech(
      id: 'tech_resource_basic',
      name: 'Enhanced Resource Generation',
      description: 'Increases passive energy and bio-material generation rates.',
      type: ResearchType.resources,
      cost: 15,
      researchTime: 90, // 1.5 minutes
      prerequisites: [],
      effects: {
        'energy_regen_bonus': 2, // +2 energy per minute
        'biomaterial_regen_bonus': 1, // +1 biomaterial per minute
      },
      status: ResearchStatus.available, // Initially available
    ));
    
    // Advanced resource management
    _technologies.add(ResearchTech(
      id: 'tech_resource_capacity',
      name: 'Expanded Resource Capacity',
      description: 'Increases maximum energy and bio-material storage.',
      type: ResearchType.resources,
      cost: 20,
      researchTime: 120, // 2 minutes
      prerequisites: ['tech_resource_basic'],
      effects: {
        'energy_capacity_bonus': 50, // +50 max energy
        'biomaterial_capacity_bonus': 30, // +30 max biomaterial
      },
    ));
    
    // Basic immunity research
    _technologies.add(ResearchTech(
      id: 'tech_immunity_basic',
      name: 'Enhanced Memory Cells',
      description: 'Improves the effectiveness of immune memory against known pathogens.',
      type: ResearchType.immunity,
      cost: 20,
      researchTime: 150, // 2.5 minutes
      prerequisites: [],
      effects: {
        'memory_damage_bonus_multiplier': 0.25, // +25% to existing damage bonuses
      },
      status: ResearchStatus.available, // Initially available
    ));
    
    // Advanced immunity research
    _technologies.add(ResearchTech(
      id: 'tech_immunity_advanced',
      name: 'Cross-Reactive Memory',
      description: 'Memory against one pathogen provides partial benefits against related types.',
      type: ResearchType.immunity,
      cost: 35,
      researchTime: 240, // 4 minutes
      prerequisites: ['tech_immunity_basic'],
      effects: {
        'memory_cross_reactivity': true, // Enable cross-reactivity
      },
    ));
    
    // Basic bioforge research
    _technologies.add(ResearchTech(
      id: 'tech_bioforge_basic',
      name: 'Enhanced Defense Structures',
      description: 'Improves the defensive capabilities of your base.',
      type: ResearchType.bioforge,
      cost: 15,
      researchTime: 120, // 2 minutes
      prerequisites: [],
      effects: {
        'base_armor_bonus': 10, // +10% base armor
      },
      status: ResearchStatus.available, // Initially available
    ));
    
    // Advanced bioforge research
    _technologies.add(ResearchTech(
      id: 'tech_bioforge_advanced',
      name: 'Adaptive Barrier System',
      description: 'Adds an adaptive barrier that strengthens against repeated attacks of the same type.',
      type: ResearchType.bioforge,
      cost: 30,
      researchTime: 210, // 3.5 minutes
      prerequisites: ['tech_bioforge_basic'],
      effects: {
        'adaptive_barrier': true, // Enable adaptive barrier
      },
    ));
  }
  
  /// Update research status and check for completions
  void updateResearch() {
    bool hasUpdate = false;
    
    // Check current research for completion
    if (_currentResearch != null && _currentResearch!.checkCompletion()) {
      _currentResearch = null;
      hasUpdate = true;
    }
    
    // Update available technologies based on completed prereqs
    for (final tech in _technologies) {
      if (tech.status == ResearchStatus.locked) {
        if (tech.canResearch(completedTechs)) {
          tech.status = ResearchStatus.available;
          hasUpdate = true;
        }
      }
    }
    
    if (hasUpdate) {
      notifyListeners();
    }
  }
  
  /// Start researching a technology
  bool startResearch(String techId, int availablePoints) {
    // Can't start if already researching
    if (_currentResearch != null) {
      return false;
    }
    
    // Find the tech
    final techIndex = _technologies.indexWhere((tech) => tech.id == techId);
    if (techIndex < 0) {
      return false;
    }
    
    final tech = _technologies[techIndex];
    
    // Check if available and can afford
    if (tech.status != ResearchStatus.available || tech.cost > availablePoints) {
      return false;
    }
    
    // Start research
    tech.startResearch();
    _currentResearch = tech;
    notifyListeners();
    
    return true;
  }
  
  /// Cancel current research
  bool cancelResearch() {
    if (_currentResearch != null) {
      // Revert to available status
      final techIndex = _technologies.indexWhere((tech) => tech.id == _currentResearch!.id);
      if (techIndex >= 0) {
        _technologies[techIndex].status = ResearchStatus.available;
        _technologies[techIndex].startTime = null;
        _technologies[techIndex].completionTime = null;
      }
      
      _currentResearch = null;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Get the effects of all completed research
  Map<String, dynamic> getCompletedResearchEffects() {
    final effects = <String, dynamic>{};
    
    // Combine effects from all completed research
    for (final tech in completedTechs) {
      for (final entry in tech.effects.entries) {
        // Handle numeric values by adding them up
        if (entry.value is num) {
          final value = entry.value as num;
          if (effects.containsKey(entry.key)) {
            if (effects[entry.key] is num) {
              effects[entry.key] = (effects[entry.key] as num) + value;
            } else {
              effects[entry.key] = value;
            }
          } else {
            effects[entry.key] = value;
          }
        } 
        // Handle boolean values with OR logic
        else if (entry.value is bool) {
          final value = entry.value as bool;
          if (effects.containsKey(entry.key)) {
            if (effects[entry.key] is bool) {
              effects[entry.key] = (effects[entry.key] as bool) || value;
            } else {
              effects[entry.key] = value;
            }
          } else {
            effects[entry.key] = value;
          }
        }
        // For other types, just overwrite
        else {
          effects[entry.key] = entry.value;
        }
      }
    }
    
    return effects;
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'technologies': _technologies.map((tech) => tech.toMap()).toList(),
      'currentResearchId': _currentResearch?.id,
    };
  }
  
  /// Create from map from storage
  factory LaboratoireRecherche.fromMap(Map<String, dynamic> map) {
    final labo = LaboratoireRecherche();
    labo._technologies.clear();
    
    // Load technologies
    if (map.containsKey('technologies')) {
      final techList = map['technologies'] as List;
      labo._technologies.addAll(
        techList.map((techMap) => ResearchTech.fromMap(techMap as Map<String, dynamic>))
      );
    }
    
    // Set current research if any
    if (map.containsKey('currentResearchId') && map['currentResearchId'] != null) {
      final currentId = map['currentResearchId'];
      labo._currentResearch = labo._technologies.firstWhere(
        (tech) => tech.id == currentId,
        orElse: () => labo._technologies.first, // Return a default tech instead of null
      );
    }
    
    return labo;
  }
}
