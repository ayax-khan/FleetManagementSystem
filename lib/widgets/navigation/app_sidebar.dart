import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  bool _isCollapsed = false;
  String _selectedItem = 'Dashboard';

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      id: 'dashboard',
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: '/dashboard',
    ),
    NavigationItem(
      id: 'vehicles',
      title: 'Vehicles',
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car,
      route: '/vehicles',
    ),
    NavigationItem(
      id: 'drivers',
      title: 'Drivers',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: '/drivers',
    ),
    NavigationItem(
      id: 'jobs',
      title: 'Job Management',
      icon: Icons.work_outline,
      activeIcon: Icons.work,
      route: '/jobs',
    ),
    NavigationItem(
      id: 'attendance',
      title: 'Attendance',
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time,
      route: '/attendance',
    ),
    NavigationItem(
      id: 'fuel',
      title: 'Fuel Management',
      icon: Icons.local_gas_station_outlined,
      activeIcon: Icons.local_gas_station,
      route: '/fuel',
    ),
    NavigationItem(
      id: 'maintenance',
      title: 'Maintenance',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      route: '/maintenance',
      isComingSoon: true,
    ),
    NavigationItem(
      id: 'routes',
      title: 'Routes',
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
      route: '/routes',
      isComingSoon: true,
    ),
    NavigationItem(
      id: 'import',
      title: 'Import Data',
      icon: Icons.file_upload_outlined,
      activeIcon: Icons.file_upload,
      route: '/import',
    ),
    NavigationItem(
      id: 'reports',
      title: 'Reports',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      route: '/reports',
      isComingSoon: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 80 : 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                return _buildNavigationItem(item);
              },
            ),
          ),
          
          // Collapse Button
          _buildCollapseButton(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet Management',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final isSelected = _selectedItem == item.title;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: item.isComingSoon ? null : () => _onItemTap(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: item.isComingSoon 
                      ? const Color(0xFF9CA3AF)
                      : isSelected
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF6B7280),
                  size: 24,
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: item.isComingSoon 
                            ? const Color(0xFF9CA3AF)
                            : isSelected
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF6B7280),
                        fontSize: 15,
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (item.isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _isCollapsed = !_isCollapsed;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: _isCollapsed 
                  ? MainAxisAlignment.center 
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  _isCollapsed 
                      ? Icons.keyboard_arrow_right 
                      : Icons.keyboard_arrow_left,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Collapse',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTap(NavigationItem item) {
    setState(() {
      _selectedItem = item.title;
    });

    // Navigate to the appropriate screen
    switch (item.id) {
      case 'dashboard':
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 'vehicles':
        Navigator.pushReplacementNamed(context, '/vehicles');
        break;
      case 'drivers':
        Navigator.pushReplacementNamed(context, '/drivers');
        break;
      case 'jobs':
        Navigator.pushReplacementNamed(context, '/jobs');
        break;
      case 'attendance':
        Navigator.pushReplacementNamed(context, '/attendance');
        break;
      case 'fuel':
        Navigator.pushReplacementNamed(context, '/fuel');
        break;
      case 'import':
        Navigator.pushReplacementNamed(context, '/import');
        break;
      case 'reports':
        Navigator.pushReplacementNamed(context, '/reports');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} - Coming Soon!'),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }
}

class NavigationItem {
  final String id;
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool isComingSoon;

  NavigationItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.isComingSoon = false,
  });
}