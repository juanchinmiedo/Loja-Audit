// lib/widgets/audit_entry_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/audit_entry.dart';

class AuditEntryCard extends StatelessWidget {
  const AuditEntryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  final AuditEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color  = _colorFor(entry);
    final icon   = _iconFor(entry);
    final detail = _detailLine(entry);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon chip
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action label + time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.actionLabel,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF202124),
                            ),
                          ),
                        ),
                        Text(
                          _timeLabel(entry.createdAt),
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: const Color(0xFF9AA0A6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Detail line (client name, service, etc.)
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: const Color(0xFF5F6368),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),

                    // Performer chip
                    Row(
                      children: [
                        Icon(
                          entry.workerId != null
                              ? Icons.badge_outlined
                              : Icons.manage_accounts_outlined,
                          size: 13,
                          color: const Color(0xFF9AA0A6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.performedByName,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF9AA0A6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (entry.workerId != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'worker',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: const Color(0xFF4285F4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'admin',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: const Color(0xFF5F6368),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFor(AuditEntry e) {
    if (e.isDestructive) return const Color(0xFFEA4335);
    if (e.isCreate)      return const Color(0xFF34A853);
    switch (e.category) {
      case ActionCategory.appointment:    return const Color(0xFF4285F4);
      case ActionCategory.client:         return const Color(0xFFFBBC04);
      case ActionCategory.bookingRequest: return const Color(0xFF9C27B0);
      case ActionCategory.other:          return const Color(0xFF9AA0A6);
    }
  }

  IconData _iconFor(AuditEntry e) {
    switch (e.action) {
      case 'appointment_created':            return Icons.event_available_outlined;
      case 'appointment_edited':             return Icons.edit_calendar_outlined;
      case 'appointment_deleted':            return Icons.event_busy_outlined;
      case 'appointment_status_changed':     return Icons.swap_horiz_rounded;
      case 'appointment_final_price_set':    return Icons.euro_outlined;
      case 'appointment_final_price_edited': return Icons.edit_outlined;
      case 'appointment_final_price_cleared':return Icons.money_off_outlined;
      case 'client_created':                 return Icons.person_add_outlined;
      case 'client_edited':                  return Icons.manage_accounts_outlined;
      case 'client_deleted':                 return Icons.person_remove_outlined;
      case 'booking_request_created':        return Icons.notifications_active_outlined;
      case 'booking_request_edited':         return Icons.notifications_outlined;
      case 'booking_request_deleted':        return Icons.notifications_off_outlined;
      default:                               return Icons.history_outlined;
    }
  }

  String _detailLine(AuditEntry e) {
    final d = e.details;
    final clientName  = (d['clientName']  ?? '').toString().trim();
    final serviceName = (d['serviceName'] ?? '').toString().trim();
    final oldStatus   = (d['oldStatus']   ?? '').toString().trim();
    final newStatus   = (d['newStatus']   ?? '').toString().trim();
    final newPrice    = d['newPrice'];
    final oldPrice    = d['oldPrice'];

    if (e.action == 'appointment_status_changed') {
      return '$clientName · $oldStatus → $newStatus';
    }
    if (e.action.contains('final_price')) {
      final parts = <String>[];
      if (clientName.isNotEmpty) parts.add(clientName);
      if (oldPrice != null) parts.add('€$oldPrice → €${newPrice ?? '—'}');
      else if (newPrice != null) parts.add('€$newPrice');
      return parts.join(' · ');
    }

    final parts = <String>[];
    if (clientName.isNotEmpty) parts.add(clientName);
    if (serviceName.isNotEmpty) parts.add(serviceName);
    return parts.join(' · ');
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return DateFormat('d MMM', 'es').format(dt);
  }
}
