import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String displayName;
  final int currentEnergie;
  final int currentBiomateriaux;
  final List<String> immuneMemorySignatures;
  final int researchPoints;
  final int victories;
  final DateTime lastLogin;

  UserProfile({
    required this.id,
    required this.displayName,
    this.currentEnergie = 100,
    this.currentBiomateriaux = 50,
    this.immuneMemorySignatures = const [],
    this.researchPoints = 0,
    this.victories = 0,
    required this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'currentEnergie': currentEnergie,
      'currentBiomateriaux': currentBiomateriaux,
      'immuneMemorySignatures': immuneMemorySignatures,
      'researchPoints': researchPoints,
      'victories': victories,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Safely handle immuneMemorySignatures which might come as a Map or List
    List<String> signatures = [];
    final signaturesData = map['immuneMemorySignatures'];
    
    if (signaturesData != null) {
      if (signaturesData is List) {
        signatures = List<String>.from(signaturesData);
      } else if (signaturesData is Map) {
        // If it's a map, extract values as strings
        signatures = signaturesData.values.map((e) => e.toString()).toList();
      }
    }
    
    // Safely handle id and displayName
    final String id = map['id']?.toString() ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    String displayName = map['displayName']?.toString() ?? 'Player';
    
    // Safely handle lastLogin
    DateTime lastLogin;
    try {
      final loginData = map['lastLogin'];
      if (loginData is String) {
        lastLogin = DateTime.parse(loginData);
      } else if (loginData is Timestamp) {
        lastLogin = loginData.toDate();
      } else {
        lastLogin = DateTime.now();
      }
    } catch (e) {
      lastLogin = DateTime.now();
    }
    
    return UserProfile(
      id: id,
      displayName: displayName,
      currentEnergie: map['currentEnergie'] as int? ?? 100,
      currentBiomateriaux: map['currentBiomateriaux'] as int? ?? 50,
      immuneMemorySignatures: signatures,
      researchPoints: map['researchPoints'] as int? ?? 0,
      victories: map['victories'] as int? ?? 0,
      lastLogin: lastLogin,
    );
  }

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = {};
    
    // Safely handle document data
    try {
      data = doc.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      // If casting fails, use an empty map
      print('Error reading document data: $e');
    }
    
    return UserProfile.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    int? currentEnergie,
    int? currentBiomateriaux,
    List<String>? immuneMemorySignatures,
    int? researchPoints,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      currentEnergie: currentEnergie ?? this.currentEnergie,
      currentBiomateriaux: currentBiomateriaux ?? this.currentBiomateriaux,
      immuneMemorySignatures: immuneMemorySignatures ?? this.immuneMemorySignatures,
      researchPoints: researchPoints ?? this.researchPoints,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
