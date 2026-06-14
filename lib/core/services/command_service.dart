import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucifax_cdm/core/constants/command_types.dart';
import 'package:lucifax_cdm/core/services/firebase_service.dart';
import 'package:lucifax_cdm/models/command_model.dart';
import 'package:uuid/uuid.dart';

final commandServiceProvider = Provider<CommandService>((ref) {
  return CommandService();
});

class CommandService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  Future<void> sendCommand({
    required String targetDeviceId,
    required String senderId,
    required String senderDeviceName,
    required CommandType type,
    Map<String, dynamic>? payload,
  }) async {
    final String commandId = const Uuid().v4();
    final command = CommandModel(
      id: commandId,
      deviceId: targetDeviceId,
      senderId: senderId,
      senderDeviceName: senderDeviceName,
      type: type,
      payload: payload,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('commands').doc(commandId).set(command.toJson());
  }

  Stream<List<CommandModel>> streamPendingCommands(String deviceId) {
    return _firestore
        .collection('commands')
        .where('deviceId', isEqualTo: deviceId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandModel.fromJson(doc.data()))
          .toList();
    });
  }

  Stream<List<CommandModel>> streamCommandHistory(String deviceId) {
    return _firestore
        .collection('commands')
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandModel.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> updateCommandStatus(
    String commandId,
    String status, {
    Map<String, dynamic>? result,
  }) async {
    final Map<String, dynamic> updates = {
      'status': status,
      'completedAt': DateTime.now().toIso8601String(),
    };
    if (result != null) updates['result'] = result;

    await _firestore.collection('commands').doc(commandId).update(updates);
  }
}
