import 'package:flutter/material.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;

  const ChartCard({
    super.key,
    required this.title,
    required this.data,
  });

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
                      title,
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
              height: 200,
              child: data.isEmpty
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
    final maxValue = data.map((d) => d['cost'] as double).reduce((a, b) => a > b ? a : b);
    
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
      children: data.map((item) {
        final cost = item['cost'] as double;
        final date = item['date'] as String;
        final height = (cost / maxValue) * 150;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  height: height + 20, // Minimum height of 20
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF3B82F6),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Label
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                // Value
                Text(
                  'Rs ${cost.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}