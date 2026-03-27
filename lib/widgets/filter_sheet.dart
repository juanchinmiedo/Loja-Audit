// lib/widgets/filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/audit_entry.dart';
import '../services/audit_data_service.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.current,
    required this.performers,
    required this.workers,
    required this.onApply,
  });

  final AuditFilter current;
  final List<({String uid, String name})> performers;
  final List<({String id, String name})> workers;
  final void Function(AuditFilter) onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late AuditFilter _filter;

  static const _kBlue   = Color(0xFF4285F4);
  static const _kGrey   = Color(0xFF5F6368);

  static const _actions = [
    ('appointment_created',            'Cita creada'),
    ('appointment_edited',             'Cita editada'),
    ('appointment_deleted',            'Cita eliminada'),
    ('appointment_status_changed',     'Estado cambiado'),
    ('appointment_final_price_set',    'Precio final añadido'),
    ('appointment_final_price_edited', 'Precio final editado'),
    ('appointment_final_price_cleared','Precio final eliminado'),
    ('client_created',                 'Cliente creado'),
    ('client_edited',                  'Cliente editado'),
    ('client_deleted',                 'Cliente eliminado'),
    ('booking_request_created',        'Solicitud creada'),
    ('booking_request_edited',         'Solicitud editada'),
    ('booking_request_deleted',        'Solicitud eliminada'),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDADCE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Text('Filtros', style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w600,
                color: const Color(0xFF202124),
              )),
              const Spacer(),
              if (!_filter.isEmpty)
                TextButton(
                  onPressed: () => setState(() =>
                      _filter = const AuditFilter()),
                  child: Text('Limpiar', style: GoogleFonts.nunito(
                    color: _kBlue, fontWeight: FontWeight.w500,
                  )),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Category ───────────────────────────────────────────
                  _sectionLabel('Categoría'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _chip(
                        label: 'Citas',
                        selected: _filter.category == ActionCategory.appointment,
                        onTap: () => setState(() => _filter = _filter.copyWith(
                          category: _filter.category == ActionCategory.appointment
                              ? null : ActionCategory.appointment,
                          action: null,
                        )),
                      ),
                      _chip(
                        label: 'Clientes',
                        selected: _filter.category == ActionCategory.client,
                        onTap: () => setState(() => _filter = _filter.copyWith(
                          category: _filter.category == ActionCategory.client
                              ? null : ActionCategory.client,
                          action: null,
                        )),
                      ),
                      _chip(
                        label: 'Solicitudes',
                        selected: _filter.category == ActionCategory.bookingRequest,
                        onTap: () => setState(() => _filter = _filter.copyWith(
                          category: _filter.category == ActionCategory.bookingRequest
                              ? null : ActionCategory.bookingRequest,
                          action: null,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Specific action ────────────────────────────────────
                  _sectionLabel('Acción específica'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _actions.map((a) => _chip(
                      label: a.$2,
                      selected: _filter.action == a.$1,
                      onTap: () => setState(() => _filter = _filter.copyWith(
                        action: _filter.action == a.$1 ? null : a.$1,
                        category: null,
                      )),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Performer ──────────────────────────────────────────
                  if (widget.performers.isNotEmpty) ...[
                    _sectionLabel('Realizado por'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: widget.performers.map((p) => _chip(
                        label: p.name.split(' ').first,
                        selected: _filter.performedBy == p.uid,
                        onTap: () => setState(() => _filter = _filter.copyWith(
                          performedBy: _filter.performedBy == p.uid
                              ? null : p.uid,
                        )),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Worker ─────────────────────────────────────────────
                  if (widget.workers.isNotEmpty) ...[
                    _sectionLabel('Worker'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: widget.workers.map((w) => _chip(
                        label: w.name.split(' ').first,
                        selected: _filter.workerId == w.id,
                        onTap: () => setState(() => _filter = _filter.copyWith(
                          workerId: _filter.workerId == w.id ? null : w.id,
                        )),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Date range ─────────────────────────────────────────
                  _sectionLabel('Rango de fechas'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _dateButton(
                        label: _filter.dateFrom != null
                            ? _fmt(_filter.dateFrom!) : 'Desde',
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _filter.dateFrom ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() =>
                              _filter = _filter.copyWith(dateFrom: d));
                        },
                        hasValue: _filter.dateFrom != null,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _dateButton(
                        label: _filter.dateTo != null
                            ? _fmt(_filter.dateTo!) : 'Hasta',
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _filter.dateTo ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() =>
                              _filter = _filter.copyWith(dateTo: d));
                        },
                        hasValue: _filter.dateTo != null,
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(_filter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: Text(
                _filter.isEmpty ? 'Aplicar' : 'Aplicar (${_filter.activeCount})',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF9AA0A6),
      letterSpacing: 0.5,
    ),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kBlue : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _kBlue : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF5F6368),
          ),
        ),
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFE8F0FE) : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue ? _kBlue.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14,
                color: hasValue ? _kBlue : const Color(0xFF9AA0A6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: hasValue ? _kBlue : const Color(0xFF9AA0A6),
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
