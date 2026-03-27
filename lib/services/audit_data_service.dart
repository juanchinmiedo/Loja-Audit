// lib/services/audit_data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_entry.dart';

class AuditFilter {
  const AuditFilter({
    this.performedBy,
    this.workerId,
    this.category,
    this.action,
    this.dateFrom,
    this.dateTo,
    this.searchText,
  });

  final String? performedBy;   // uid
  final String? workerId;      // worker doc id
  final ActionCategory? category;
  final String? action;        // specific action string
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? searchText;    // client name, service name

  bool get isEmpty =>
      performedBy == null &&
      workerId == null &&
      category == null &&
      action == null &&
      dateFrom == null &&
      dateTo == null &&
      (searchText == null || searchText!.isEmpty);

  int get activeCount {
    int c = 0;
    if (performedBy != null) c++;
    if (workerId != null) c++;
    if (category != null) c++;
    if (action != null) c++;
    if (dateFrom != null || dateTo != null) c++;
    if (searchText != null && searchText!.isNotEmpty) c++;
    return c;
  }

  AuditFilter copyWith({
    Object? performedBy   = _sentinel,
    Object? workerId      = _sentinel,
    Object? category      = _sentinel,
    Object? action        = _sentinel,
    Object? dateFrom      = _sentinel,
    Object? dateTo        = _sentinel,
    Object? searchText    = _sentinel,
  }) =>
      AuditFilter(
        performedBy: performedBy  == _sentinel ? this.performedBy  : performedBy  as String?,
        workerId:    workerId     == _sentinel ? this.workerId     : workerId     as String?,
        category:    category     == _sentinel ? this.category     : category     as ActionCategory?,
        action:      action       == _sentinel ? this.action       : action       as String?,
        dateFrom:    dateFrom     == _sentinel ? this.dateFrom     : dateFrom     as DateTime?,
        dateTo:      dateTo       == _sentinel ? this.dateTo       : dateTo       as DateTime?,
        searchText:  searchText   == _sentinel ? this.searchText   : searchText   as String?,
      );

  static const _sentinel = Object();
}

class AuditDataService {
  final _db = FirebaseFirestore.instance;

  /// Streams audit entries ordered by createdAt desc, with optional filters.
  Stream<List<AuditEntry>> streamEntries({
    AuditFilter filter = const AuditFilter(),
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('audit_log')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // Server-side filters (Firestore)
    if (filter.performedBy != null) {
      q = q.where('performedBy', isEqualTo: filter.performedBy);
    }
    if (filter.workerId != null) {
      q = q.where('workerId', isEqualTo: filter.workerId);
    }
    if (filter.action != null) {
      q = q.where('action', isEqualTo: filter.action);
    } else if (filter.category != null) {
      q = q.where('entityType', isEqualTo: _entityTypeFor(filter.category!));
    }
    if (filter.dateFrom != null) {
      q = q.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filter.dateFrom!));
    }
    if (filter.dateTo != null) {
      final end = DateTime(
        filter.dateTo!.year, filter.dateTo!.month, filter.dateTo!.day,
        23, 59, 59,
      );
      q = q.where('createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    return q.snapshots().map((snap) {
      var entries = snap.docs
          .map((d) => AuditEntry.fromDoc(d))
          .toList();

      // Client-side text filter
      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        final q = filter.searchText!.toLowerCase();
        entries = entries.where((e) {
          final clientName = (e.details['clientName'] ?? '').toString().toLowerCase();
          final serviceName = (e.details['serviceName'] ?? '').toString().toLowerCase();
          return clientName.contains(q) || serviceName.contains(q) ||
              e.performedByName.toLowerCase().contains(q);
        }).toList();
      }

      return entries;
    });
  }

  /// Fetch distinct performers (uid + name) for filter UI.
  Future<List<({String uid, String name})>> fetchPerformers() async {
    final snap = await _db
        .collection('users')
        .orderBy('displayName')
        .get();
    return snap.docs.map((d) => (
      uid:  d.id,
      name: (d.data()['displayName'] ?? d.data()['name'] ?? d.id).toString(),
    )).toList();
  }

  /// Fetch workers for filter UI.
  Future<List<({String id, String name})>> fetchWorkers() async {
    final snap = await _db.collection('workers').orderBy('nameShown').get();
    return snap.docs.map((d) => (
      id:   d.id,
      name: (d.data()['nameShown'] ?? d.data()['name'] ?? d.id).toString(),
    )).toList();
  }

  String _entityTypeFor(ActionCategory cat) {
    switch (cat) {
      case ActionCategory.appointment:    return 'appointment';
      case ActionCategory.client:         return 'client';
      case ActionCategory.bookingRequest: return 'booking_request';
      case ActionCategory.other:          return '';
    }
  }
}
