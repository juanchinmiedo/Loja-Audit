// lib/screens/audit_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audit_entry.dart';
import '../services/audit_data_service.dart';
import '../services/auth_service.dart';
import '../widgets/audit_entry_card.dart';
import '../widgets/filter_sheet.dart';
import 'entry_detail_screen.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key, required this.user});
  final User user;

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  static const _kBlue  = Color(0xFF4285F4);
  static const _kGrey  = Color(0xFF5F6368);

  final _dataService  = AuditDataService();
  final _searchCtrl   = TextEditingController();

  AuditFilter _filter = const AuditFilter();
  bool _searchVisible = false;

  List<({String uid, String name})> _performers = [];
  List<({String id, String name})>  _workers    = [];
  bool _metaLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    final p = await _dataService.fetchPerformers();
    final w = await _dataService.fetchWorkers();
    if (mounted) setState(() {
      _performers  = p;
      _workers     = w;
      _metaLoaded  = true;
    });
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        current:    _filter,
        performers: _performers,
        workers:    _workers,
        onApply:    (f) => setState(() => _filter = f),
      ),
    );
  }

  void _clearFilters() => setState(() {
    _filter = const AuditFilter();
    _searchCtrl.clear();
  });

  String get _displayName {
    final name = widget.user.displayName ?? widget.user.email ?? 'Owner';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFilter = _searchCtrl.text.trim().isEmpty
        ? _filter
        : _filter.copyWith(searchText: _searchCtrl.text.trim());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _searchVisible
                  ? _buildSearchField()
                  : Row(
                      children: [
                        // Google-style 4-dot logo
                        _buildDotLogo(),
                        const SizedBox(width: 10),
                        Text(
                          'Audit Log',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF202124),
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              // Search toggle
              IconButton(
                icon: Icon(
                  _searchVisible ? Icons.close : Icons.search,
                  color: _kGrey,
                ),
                onPressed: () => setState(() {
                  _searchVisible = !_searchVisible;
                  if (!_searchVisible) _searchCtrl.clear();
                }),
              ),
              // Filter button with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: _kGrey),
                    onPressed: _openFilters,
                  ),
                  if (_filter.activeCount > 0)
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: _kBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_filter.activeCount}',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Avatar + signout
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _showSignOutDialog,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _kBlue.withOpacity(0.12),
                    backgroundImage: widget.user.photoURL != null
                        ? NetworkImage(widget.user.photoURL!)
                        : null,
                    child: widget.user.photoURL == null
                        ? Text(
                            _displayName[0].toUpperCase(),
                            style: GoogleFonts.nunito(
                              color: _kBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: const Color(0xFFE8EAED),
              ),
            ),
          ),

          // ── Active filters chips ──────────────────────────────────────────
          if (!effectiveFilter.isEmpty)
            SliverToBoxAdapter(
              child: _buildActiveFiltersBanner(effectiveFilter),
            ),

          // ── List ──────────────────────────────────────────────────────────
          StreamBuilder<List<AuditEntry>>(
            stream: _dataService.streamEntries(filter: effectiveFilter),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _kBlue, strokeWidth: 2,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Error: ${snap.error}',
                        style: GoogleFonts.nunito(color: Colors.red)),
                  ),
                );
              }

              final entries = snap.data ?? [];
              if (entries.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return _buildAnimatedCard(e, i);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Animated card entry ───────────────────────────────────────────────────

  Widget _buildAnimatedCard(AuditEntry entry, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(entry.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index.clamp(0, 10) * 30)),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: AuditEntryCard(
        entry: entry,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntryDetailScreen(entry: entry),
          ),
        ),
      ),
    );
  }

  // ── Active filters banner ─────────────────────────────────────────────────

  Widget _buildActiveFiltersBanner(AuditFilter f) {
    return Container(
      color: const Color(0xFFE8F0FE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded,
              size: 16, color: _kBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${f.activeCount} filtro${f.activeCount > 1 ? 's' : ''} activo${f.activeCount > 1 ? 's' : ''}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: _kBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: Text(
              'Limpiar',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: _kBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search field ──────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      autofocus: true,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF202124)),
      decoration: InputDecoration(
        hintText: 'Buscar cliente, servicio...',
        hintStyle: GoogleFonts.nunito(
            fontSize: 15, color: const Color(0xFF9AA0A6)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_outlined,
              size: 56, color: const Color(0xFFDADCE0)),
          const SizedBox(height: 16),
          Text(
            'Sin actividad',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9AA0A6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay eventos con los filtros actuales',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFFBDC1C6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Google-style 4-dot logo ───────────────────────────────────────────────

  Widget _buildDotLogo() {
    const dots = [
      Color(0xFF4285F4),
      Color(0xFFEA4335),
      Color(0xFFFBBC04),
      Color(0xFF34A853),
    ];
    return SizedBox(
      width: 20, height: 20,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: dots.map((c) => Container(
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        )).toList(),
      ),
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> _showSignOutDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        content: Text('¿Salir de $_displayName?',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: _kGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Salir',
                style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await AuthService().signOut();
    }
  }
}
