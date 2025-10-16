import 'package:flutter/material.dart';

class ChartCard extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> data;

  const ChartCard({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Simple Bar Chart
            SizedBox(
              height: 220,
              child: widget.data.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 48,
                            color: Color(0xFFE5E7EB),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No data available',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildSimpleBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart() {
    final maxValue = widget.data.map((d) => d['cost'] as double).reduce((a, b) => a > b ? a : b);
    
    if (maxValue == 0) {
      return const Center(
        child: Text(
          'No fuel costs in the selected period',
          style: TextStyle(
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.data.length, (index) {
        final item = widget.data[index];
        final cost = item['cost'] as double;
        final date = item['date'] as String;
        final height = (cost / maxValue) * 150;
        final isHovered = _hoveredIndex == index;
        
        return Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: 'Date: $date\nCost: Rs ${cost.toStringAsFixed(2)}',
              preferBelow: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: height + 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isHovered
                              ? [
                                  const Color(0xFF1565C0),
                                  const Color(0xFF64B5F6),
                                ]
                              : [
                                  const Color(0xFF1E3A8A),
                                  const Color(0xFF3B82F6),
                                ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isHovered ? const Color(0xFF1565C0) : const Color(0xFF6B7280),
                        fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Value
                    Text(
                      'Rs ${cost.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isHovered ? const Color(0xFF1565C0) : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}