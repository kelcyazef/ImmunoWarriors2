import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel model;
  
  GeminiService({required this.apiKey}) {
    // Use the Gemini 2.0 Flash model as specified in the curl command
    model = GenerativeModel(
      model: 'gemini-2.0-flash',  // Updated to the newer model
      apiKey: apiKey,
      // Add optional configuration for better results
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 250,
      ),
    );
  }

  // Generate battle chronicles
  Future<String> generateBattleChronicle(Map<String, dynamic> battleData) async {
    try {
      print('Generating battle chronicle with data: ${battleData.toString()}');
      
      // Check for required fields
      if (battleData['playerUnits'] == null || battleData['enemyUnits'] == null) {
        print('Warning: Missing required battle data fields');
        return "Battle chronicle unavailable - missing data.";
      }
      
      final prompt = _createBattleChroniclePrompt(battleData);
      print('Generated prompt: $prompt');
      
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "Failed to generate battle chronicle.";
    } catch (e) {
      print('Error generating battle chronicle: $e');
      return "Error generating battle chronicle: ${e.toString()}.";
    }
  }

  // Generate tactical advice
  Future<String> generateTacticalAdvice(Map<String, dynamic> playerState, Map<String, dynamic> enemyBase) async {
    try {
      print('Generating tactical advice with data:');
      print('PlayerState: ${playerState.toString()}');
      print('EnemyBase: ${enemyBase.toString()}');
      
      // Validate input data
      if (playerState['resources'] == null || playerState['availableUnits'] == null) {
        print('Warning: Missing required player state fields');
        return _generateLocalTacticalAdvice(playerState, enemyBase);
      }
      
      if (enemyBase['units'] == null) {
        print('Warning: Missing required enemy base fields');
        return _generateLocalTacticalAdvice(playerState, enemyBase);
      }
      
      // Check if we should use mock data (quota exceeded or in development)
      String errorMessage = '';
      try {
        // Generate prompt with full context
        final prompt = _createTacticalAdvicePrompt(playerState, enemyBase);
        print('Generated prompt: $prompt');
        
        // Call Gemini API with proper error handling
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        final advice = response.text;
        
        // Validate response
        if (advice == null || advice.isEmpty) {
          print('Warning: Empty response from API');
          return _generateLocalTacticalAdvice(playerState, enemyBase);
        }
        
        print('Received tactical advice: $advice');
        return advice;
      } catch (apiError) {
        errorMessage = apiError.toString();
        print('API error: $errorMessage');
        
        // Check specifically for quota exceeded errors
        if (errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
          print('Using local tactical advice due to quota limit');
        }
        
        // Fall back to local tactical advice generation
        return _generateLocalTacticalAdvice(playerState, enemyBase);
      }
    } catch (e) {
      print('Error in tactical advice generation flow: $e');
      return _generateLocalTacticalAdvice(playerState, enemyBase);
    }
  }
  
  // Generate tactical advice locally when API is unavailable
  String _generateLocalTacticalAdvice(Map<String, dynamic> playerState, Map<String, dynamic> enemyBase) {
    // Extract enemy information
    final List<dynamic> enemies = enemyBase['units'] as List? ?? [];
    final List<String> enemyNames = [];
    final List<String> enemyTypes = [];
    
    for (var enemy in enemies) {
      if (enemy is Map && enemy.containsKey('name') && enemy.containsKey('type')) {
        enemyNames.add(enemy['name'] as String);
        enemyTypes.add(enemy['type'] as String);
      }
    }
    
    // Default enemy name if not found
    final String primaryEnemyName = enemyNames.isNotEmpty ? enemyNames[0] : 'pathogens';
    final String primaryEnemyType = enemyTypes.isNotEmpty ? enemyTypes[0] : 'unknown';
    
    // Create tactical advice based on enemy type
    if (primaryEnemyType.toLowerCase().contains('virus')) {
      return _getRandomVirusAdvice(primaryEnemyName);
    } else if (primaryEnemyType.toLowerCase().contains('bact')) {
      return _getRandomBacteriaAdvice(primaryEnemyName);
    } else if (primaryEnemyType.toLowerCase().contains('fung')) {
      return _getRandomFungusAdvice(primaryEnemyName);
    } else {
      return _getRandomGenericAdvice(primaryEnemyName);
    }
  }
  
  // Generate specific advice for virus enemies
  String _getRandomVirusAdvice(String enemyName) {
    final adviceList = [
      "Deploy Killer Cells against $enemyName. Use Lymphocytes T for backup.",
      "Prioritize Lymphocytes T against $enemyName. Their viral proteins are vulnerable.",
      "$enemyName weak against Killer Cells. Use Macrophages to absorb damage.",
      "Counter $enemyName with Killer Cells in front, Lymphocytes B for support.",
    ];
    return adviceList[Random().nextInt(adviceList.length)];
  }
  
  // Generate specific advice for bacterial enemies
  String _getRandomBacteriaAdvice(String enemyName) {
    final adviceList = [
      "Deploy Macrophages against $enemyName. Follow with Lymphocytes for cleanup.",
      "$enemyName's cell walls vulnerable to Macrophages. Use in force.",
      "Surround $enemyName with Macrophages. Support with Lymphocytes B.",
      "Counter $enemyName with balanced Macrophage and Killer Cell formation.",
    ];
    return adviceList[Random().nextInt(adviceList.length)];
  }
  
  // Generate specific advice for fungal enemies
  String _getRandomFungusAdvice(String enemyName) {
    final adviceList = [
      "Deploy Lymphocytes B against $enemyName. Their antifungal properties are effective.",
      "$enemyName vulnerable to Lymphocytes B. Support with Killer Cells.",
      "Counter $enemyName with Macrophages front line, Lymphocytes B support.",
      "Use mixed formation against $enemyName: Lymphocytes B and Killer Cells.",
    ];
    return adviceList[Random().nextInt(adviceList.length)];
  }
  
  // Generate generic advice for unknown enemy types
  String _getRandomGenericAdvice(String enemyName) {
    final adviceList = [
      "Deploy balanced team against $enemyName: Killer Cells, Macrophages, Lymphocytes.",
      "Use Killer Cells against $enemyName. Support with Macrophages and Lymphocytes.",
      "$enemyName requires strategic approach. Mix all cell types.",
      "Counter $enemyName with Lymphocytes T front, Macrophages for support.",
    ];
    return adviceList[Random().nextInt(adviceList.length)];
  }

  // Private helper methods to create prompts
  String _createBattleChroniclePrompt(Map<String, dynamic> battleData) {
    return '''
You are the AI Analyst for ImmunoWarriors, a game about biological warfare in a digital world.
Write an immersive battle report (200-300 words) for the following combat data:

Player units: ${_formatUnits(battleData['playerUnits'])}
Enemy units: ${_formatUnits(battleData['enemyUnits'])}
Key events: ${_formatEvents(battleData['events'])}
Battle outcome: ${battleData['outcome']}

Use vivid biological and technological language. Emphasize heroic moments and dramatic turns.
''';
  }

  String _createTacticalAdvicePrompt(Map<String, dynamic> playerState, Map<String, dynamic> enemyBase) {
    return '''
System: You are the AI Tactical Advisor for ImmunoWarriors, a mobile game where players command antibodies and immune cells to fight against pathogens. The game simulates the human immune system's battle against infections.

Game Context: In ImmunoWarriors, players deploy different types of antibodies (Lymphocyte T, Killer Cell, Macrophage, Lymphocyte B) against enemy pathogens. Each unit has different strengths:
- Lymphocyte T: Balanced combat unit with good damage and HP
- Killer Cell: High damage assault unit with lower HP
- Macrophage: Tank unit with high HP but lower damage
- Lymphocyte B: Support unit with medium stats

Current Battle Information:
- Player's resources: ${_formatResources(playerState['resources'])}
- Player's available units: ${_formatUnits(playerState['availableUnits'])}
- Player's research level: ${playerState['researchLevel']}
- Enemy pathogens: ${_formatUnits(enemyBase['units'])}
- Known enemy weaknesses: ${enemyBase['weaknesses']}

Task: Provide extremely concise tactical advice (maximum 25 words) focused only on which specific units to deploy against which specific enemies. Use short, direct sentences. Do not explain your reasoning.
''';
  }

  // Helper formatting methods
  String _formatUnits(List<dynamic>? units) {
    if (units == null || units.isEmpty) {
      return "None";
    }
    try {
      return units.map((unit) => "${unit['name'] ?? 'Unknown'} (${unit['type'] ?? 'Unknown'}, HP: ${unit['hp'] ?? '?'})").join(", ");
    } catch (e) {
      print('Error formatting units: $e');
      return units.toString();
    }
  }

  String _formatEvents(List<dynamic>? events) {
    if (events == null || events.isEmpty) {
      return "No significant events recorded";
    }
    try {
      return events.join("; ");
    } catch (e) {
      print('Error formatting events: $e');
      return events.toString();
    }
  }

  String _formatResources(Map<String, dynamic>? resources) {
    if (resources == null || resources.isEmpty) {
      return "No resources available";
    }
    try {
      return resources.entries.map((e) => "${e.key}: ${e.value}").join(", ");
    } catch (e) {
      print('Error formatting resources: $e');
      return resources.toString();
    }
  }
}
