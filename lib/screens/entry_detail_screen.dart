// lib/screens/entry_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/audit_entry.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entry});
  final AuditEntry entry;

  static const _kBlue = Color(0xFF4285F4);
  static const _kGrey = Color(0xFF5F6368);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGrey),
        title: Text(
          entry.actionLabel,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF202124),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8EAED)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Timestamp card ─────────────────────────────────────────────
          _card(children: [
            _row(
              icon: Icons.access_time_outlined,
              label: 'Fecha y hora',
              value: DateFormat('EEEE, d MMM yyyy · HH:mm', 'es')
                  .format(entry.createdAt),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Who ───────────────────────────────────────────────────────
          _card(children: [
            _row(
              icon: Icons.person_outline_rounded,
              label: 'Realizado por',
              value: entry.performedByName,
            ),
            const Divider(height: 1, color: Color(0xFFE8EAED)),
            _row(
              icon: Icons.fingerprint_outlined,
              label: 'UID',
              value: entry.performedBy,
              mono: true,
            ),
            if (entry.workerId != null) ...[
              const Divider(height: 1, color: Color(0xFFE8EAED)),
              _row(
                icon: Icons.badge_outlined,
                label: 'Worker ID',
                value: entry.workerId!,
                mono: true,
              ),
            ],
          ]),
          const SizedBox(height: 12),

          // ── What ──────────────────────────────────────────────────────
          _card(children: [
            _row(
              icon: Icons.label_outline_rounded,
              label: 'Acción',
              value: entry.action,
              mono: true,
            ),
            const Divider(height: 1, color: Color(0xFFE8EAED)),
            _row(
              icon: Icons.folder_outlined,
              label: 'Tipo de entidad',
              value: entry.entityType,
            ),
            const Divider(height: 1, color: Color(0xFFE8EAED)),
            _row(
              icon: Icons.tag_outlined,
              label: 'ID del documento',
              value: entry.entityId,
              mono: true,
            ),
          ]),
          const SizedBox(height: 12),

          // ── Details ───────────────────────────────────────────────────
          if (entry.details.isNotEmpty) ...[
            Text(
              'DETALLES',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9AA0A6),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _card(
              children: entry.details.entries
                  .where((e) => e.value != null)
                  .map((e) => Column(
                        children: [
                          _row(
                            icon: _iconForDetailKey(e.key),
                            label: _labelForKey(e.key),
                            value: _valueForDetail(e.key, e.value),
                          ),
                          if (e.key != entry.details.keys.last)
                            const Divider(height: 1, color: Color(0xFFE8EAED)),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
    bool mono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9AA0A6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: const Color(0xFF9AA0A6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: mono
                      ? TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: const Color(0xFF202124),
                        )
                      : GoogleFonts.nunito(
                          fontSize: 14,
                          color: const Color(0xFF202124),
                          fontWeight: FontWeight.w400,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForDetailKey(String key) {
    switch (key) {
      case 'clientName':      return Icons.person_outline;
      case 'serviceName':
      case 'serviceNameKey':  return Icons.spa_outlined;
      case 'appointmentDate': return Icons.event_outlined;
      case 'workerId':        return Icons.badge_outlined;
      case 'total':
      case 'newPrice':
      case 'oldPrice':        return Icons.euro_outlined;
      case 'oldStatus':
      case 'newStatus':       return Icons.swap_horiz_rounded;
      default:                return Icons.info_outline;
    }
  }

  String _labelForKey(String key) {
    const map = {
      'clientId':       'ID cliente',
      'clientName':     'Cliente',
      'serviceName':    'Servicio',
      'serviceNameKey': 'Clave de servicio',
      'appointmentDate':'Fecha de la cita',
      'workerId':       'Worker',
      'total':          'Total',
      'oldStatus':      'Estado anterior',
      'newStatus':      'Estado nuevo',
      'oldPrice':       'Precio anterior',
      'newPrice':       'Precio nuevo',
    };
    return map[key] ?? key;
  }

  String _valueForDetail(String key, dynamic value) {
    if (value == null) return '—';
    if (key == 'appointmentDate' && value.runtimeType.toString().contains('Timestamp')) {
      try {
        final ts = value as dynamic;
        final dt = ts.toDate() as DateTime;
        return DateFormat('d MMM yyyy · HH:mm', 'es').format(dt);
      } catch (_) {}
    }
    if (key == 'total' || key == 'newPrice' || key == 'oldPrice') {
      return value == null ? '—' : '€$value';
    }
    return value.toString();
  }
}
