import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _loading = false;
  Map<String, dynamic>? _report;
  int _page = 0;
  static const int _pageSize = 20;

  Future<void> _loadSummaryDetail() async {
    setState(() {
      _loading = true;
      _page = 0; // reset pagination on load
    });
    try {
      final data = await ApiService().getSummaryDetailReport();
      setState(() => _report = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSummaryDetailDialog() async {
    await _loadSummaryDetail();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        final headings = List<String>.from(_report?['headings'] ?? []);
        final rows = List<Map<String, dynamic>>.from(_report?['rows'] ?? []);
        final total = rows.length;
        final start = (_page * _pageSize).clamp(0, total);
        final end = (start + _pageSize).clamp(0, total);
        final pageRows = start < end ? rows.sublist(start, end) : <Map<String, dynamic>>[];
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_chart, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    const Text('Summary Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    // Pagination controls
                    Text(
                      total == 0
                          ? '0-0 of 0'
                          : '${start + 1}-$end of $total',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Previous',
                      onPressed: (start == 0)
                          ? null
                          : () {
                              setState(() {
                                _page = (_page - 1).clamp(0, (total / _pageSize).ceil());
                              });
                            },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next',
                      onPressed: (end >= total)
                          ? null
                          : () {
                              setState(() {
                                _page = _page + 1;
                              });
                            },
                      icon: const Icon(Icons.chevron_right),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _SummaryDetailTable(headings: headings, rows: pageRows),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _ReportCard(
              title: 'Summary Detail',
              subtitle: 'Trips, Vehicles, Drivers',
              icon: Icons.summarize_outlined,
              onTap: _openSummaryDetailDialog,
            ),
            _ReportCard(
              title: 'Fuel / POL Report',
              subtitle: 'Consumption, cost & efficiency',
              icon: Icons.local_gas_station_outlined,
              onTap: _openFuelPolDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _openFuelPolDialog() {
    showDialog(
      context: context,
      builder: (_) => const _FuelPolDialog(),
    );
  }
}

class _SummaryDetailTable extends StatelessWidget {
  final List<String> headings;
  final List<Map<String, dynamic>> rows;
  const _SummaryDetailTable({required this.headings, required this.rows});

  TableRow _buildHeaderRow(double fontSize) {
    return TableRow(
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6)),
      children: headings
          .map((h) => _cell(h, header: true, fontSize: fontSize))
          .toList(),
    );
  }

  Widget _cell(dynamic value, {bool header = false, double fontSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        '$value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
        ),
        softWrap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth >= 1400 ? 12.0 : (screenWidth >= 1000 ? 11.0 : 10.0);

    // Assign compact flex widths to fit screen
    final widths = <int, TableColumnWidth>{};
    for (var i = 0; i < headings.length; i++) {
      final h = headings[i].toLowerCase();
      double flex = 1.0; // default
      if (h.contains('sr.no')) flex = 0.6;
      else if (h.contains('date')) flex = 0.9;
      else if (h.contains('vehic') || h.contains('reg')) flex = 1.1;
      else if (h.contains('officer') || h.contains('driver')) flex = 1.2;
      else if (h.contains('destination')) flex = 1.2;
      else if (h.contains('time')) flex = 0.9;
      else if (h.contains('meter')) flex = 0.8;
      else if (h == 'kms' || h == 'ave' || h == 'ltrs') flex = 0.7;
      else if (h.contains('coes')) flex = 0.9;
      else if (h.contains('duty')) flex = 1.0;
      widths[i] = FlexColumnWidth(flex);
    }

    return Scrollbar(
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder.all(color: const Color(0xFF9CA3AF), width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: widths,
          children: [
            _buildHeaderRow(fontSize),
            ...rows.map((r) => TableRow(
                  children: headings
                      .map((h) => _cell(r[h] ?? '', fontSize: fontSize))
                      .toList(),
                )),
          ],
        ),
      ),
    );
  }
}

class _FuelPolDialog extends StatefulWidget {
  const _FuelPolDialog({super.key});
  @override
  State<_FuelPolDialog> createState() => _FuelPolDialogState();
}

class _FuelPolDialogState extends State<_FuelPolDialog> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  List<String> _headings = [];
  Map<String, dynamic> _aggr = {};
  Map<String, dynamic> _charts = {};

  // Filters
  String? _vehicleId;
  String? _month; // YYYY-MM
  String? _fuelType;
  String? _station;
  List<Map<String, dynamic>> _vehicles = [];

  // Pagination
  int _page = 0;
  static const int _pageSize = 20;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      // Load vehicles for filter
      _vehicles = await _api.getVehicles();
      await _load();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getFuelPolReport(
        vehicleId: _vehicleId,
        month: _month,
        fuelType: _fuelType,
        station: _station,
      );
      _rows = List<Map<String, dynamic>>.from(data['rows'] ?? []);
      _headings = List<String>.from(data['headings'] ?? []);
      _aggr = Map<String, dynamic>.from(data['aggregates'] ?? {});
      _charts = Map<String, dynamic>.from(data['charts'] ?? {});
      _page = 0;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _rows.length;
    final start = (_page * _pageSize).clamp(0, total);
    final end = (start + _pageSize).clamp(0, total);
    final pageRows = start < end ? _rows.sublist(start, end) : <Map<String, dynamic>>[];

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header + Filters
            Row(
              children: [
                const Icon(Icons.local_gas_station, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Text('Fuel / POL Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(total == 0 ? '0-0 of 0' : '${start + 1}-$end of $total', style: const TextStyle(color: Colors.grey)),
                IconButton(
                  onPressed: start == 0 ? null : () => setState(() => _page = (_page - 1).clamp(0, (total / _pageSize).ceil())),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: end >= total ? null : () => setState(() => _page = _page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            _buildFilters(),
            const SizedBox(height: 8),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1565C0),
              tabs: const [
                Tab(text: 'Table'),
                Tab(text: 'Charts'),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Table
                        _SummaryDetailTable(headings: _headings, rows: pageRows),

                        // Charts
                        _FuelCharts(aggregates: _aggr, charts: _charts),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final vehicleItems = [
      const DropdownMenuItem<String?>(value: null, child: Text('All Vehicles')),
      ..._vehicles.map((v) => DropdownMenuItem<String?>(
            value: v['id']?.toString(),
            child: Text(v['registration_number']?.toString() ?? v['make_type']?.toString() ?? 'Vehicle'),
          )),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<String?>(
          value: _vehicleId,
          items: vehicleItems,
          onChanged: (val) => setState(() => _vehicleId = val),
        ),
        // Month (YYYY-MM)
        SizedBox(
          width: 140,
          child: TextField(
            decoration: const InputDecoration(labelText: 'Month (YYYY-MM)', border: OutlineInputBorder()),
            onSubmitted: (v) => setState(() => _month = v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            decoration: const InputDecoration(labelText: 'Fuel Type', border: OutlineInputBorder()),
            onSubmitted: (v) => setState(() => _fuelType = v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            decoration: const InputDecoration(labelText: 'Station', border: OutlineInputBorder()),
            onSubmitted: (v) => setState(() => _station = v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

class _FuelCharts extends StatelessWidget {
  final Map<String, dynamic> aggregates;
  final Map<String, dynamic> charts;
  const _FuelCharts({required this.aggregates, required this.charts});

  @override
  Widget build(BuildContext context) {
    final monthly = List<Map<String, dynamic>>.from(aggregates['monthly'] ?? []);
    final eff = List<Map<String, dynamic>>.from(charts['efficiency_scatter'] ?? []);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChartCard(
            title: 'Monthly Litres',
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= monthly.length) return const SizedBox.shrink();
                      return Transform.rotate(
                        angle: -0.8,
                        child: Text(monthly[idx]['month'] ?? '', style: const TextStyle(fontSize: 10)),
                      );
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                  ),
                  minX: 0,
                  maxX: (monthly.length - 1).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < monthly.length; i++) FlSpot(i.toDouble(), (monthly[i]['litres'] as num?)?.toDouble() ?? 0),
                      ],
                      isCurved: true,
                      color: const Color(0xFF1565C0),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Monthly Cost per KM',
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= monthly.length) return const SizedBox.shrink();
                      return Transform.rotate(
                        angle: -0.8,
                        child: Text(monthly[idx]['month'] ?? '', style: const TextStyle(fontSize: 10)),
                      );
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                  ),
                  minX: 0,
                  maxX: (monthly.length - 1).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < monthly.length; i++) FlSpot(i.toDouble(), (monthly[i]['cost_per_km'] as num?)?.toDouble() ?? 0),
                      ],
                      isCurved: true,
                      color: const Color(0xFF059669),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Efficiency (KM/L) by Vehicle',
            child: SizedBox(
              height: 220,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: [
                    for (var i = 0; i < eff.length; i++)
ScatterSpot(i.toDouble(), (eff[i]['km_per_litre'] as num?)?.toDouble() ?? 0)
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= eff.length) return const SizedBox.shrink();
                      return Transform.rotate(angle: -0.8, child: Text(eff[idx]['vehicle_reg'] ?? '', style: const TextStyle(fontSize: 10)));
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ReportCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1565C0)),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}