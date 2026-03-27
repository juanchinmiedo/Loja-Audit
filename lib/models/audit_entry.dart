// lib/models/audit_entry.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.entityId,
    required this.entityType,
    required this.performedBy,
    required this.performedByName,
    this.workerId,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String entityId;
  final String entityType;
  final String performedBy;
  final String performedByName;
  final String? workerId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  factory AuditEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return AuditEntry(
      id:              doc.id,
      action:          (d['action']          ?? '').toString(),
      entityId:        (d['entityId']         ?? '').toString(),
      entityType:      (d['entityType']       ?? '').toString(),
      performedBy:     (d['performedBy']      ?? '').toString(),
      performedByName: (d['performedByName']  ?? '').toString(),
      workerId:        d['workerId'] as String?,
      details:         (d['details'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt:       ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  // ── Display helpers ──────────────────────────────────────────────────────────

  String get actionLabel {
    switch (action) {
      case 'appointment_created':           return 'Cita creada';
      case 'appointment_edited':            return 'Cita editada';
      case 'appointment_deleted':           return 'Cita eliminada';
      case 'appointment_status_changed':    return 'Estado cambiado';
      case 'appointment_final_price_set':   return 'Precio final añadido';
      case 'appointment_final_price_edited':return 'Precio final editado';
      case 'appointment_final_price_cleared':return 'Precio final eliminado';
      case 'client_created':               return 'Cliente creado';
      case 'client_edited':                return 'Cliente editado';
      case 'client_deleted':               return 'Cliente eliminado';
      case 'booking_request_created':      return 'Solicitud creada';
      case 'booking_request_edited':       return 'Solicitud editada';
      case 'booking_request_deleted':      return 'Solicitud eliminada';
      default:                             return action;
    }
  }

  ActionCategory get category {
    if (action.startsWith('appointment')) return ActionCategory.appointment;
    if (action.startsWith('client'))      return ActionCategory.client;
    if (action.startsWith('booking'))     return ActionCategory.bookingRequest;
    return ActionCategory.other;
  }

  bool get isDestructive =>
      action.contains('deleted') || action.contains('cleared');

  bool get isCreate => action.contains('created');
}

enum ActionCategory { appointment, client, bookingRequest, other }
