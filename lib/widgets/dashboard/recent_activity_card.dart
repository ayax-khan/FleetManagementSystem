import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/fuel.dart';

class RecentActivityCard extends StatelessWidget {
  final List<FuelRecord> fuelRecords;

  const RecentActivityCard({
    super.key,
    required this.fuelRecords,
  });

  @override
  Widget build(BuildContext context) {
    final recentRecords = fuelRecords.take(5).toList();
    
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
                  const Expanded(
                    child: Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Activity List
            SizedBox(
              height: 200,
              child: recentRecords.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Color(0xFFE5E7EB),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No recent activity',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: recentRecords.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = recentRecords[index];
                        return _buildActivityItem(record);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(FuelRecord record) {
    return _HoverableActivityCard(
      record: record,
    );
  }
}

// Hoverable wrapper widget for activity cards
class _HoverableActivityCard extends StatefulWidget {
  final FuelRecord record;
  
  const _HoverableActivityCard({
    required this.record,
  });

  @override
  State<_HoverableActivityCard> createState() => _HoverableActivityCardState();
}

class _HoverableActivityCardState extends State<_HoverableActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
    
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFE0F2FE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05 + (0.15 * _shadowAnimation.value)),
                      blurRadius: 4 + (12 * _shadowAnimation.value),
                      offset: Offset(0, 2 + (8 * _shadowAnimation.value)),
                    ),
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.05 + (0.15 * _shadowAnimation.value)),
                      blurRadius: 2 + (8 * _shadowAnimation.value),
                      offset: Offset(0, 1 + (4 * _shadowAnimation.value)),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Fuel type icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.record.fuelType.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        widget.record.fuelType.iconData,
                        color: widget.record.fuelType.color,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.record.vehicleName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.record.quantity.toStringAsFixed(1)}L • ${widget.record.fuelStationName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Amount and date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs ${NumberFormat('#,##0').format(widget.record.totalCost)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(widget.record.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
