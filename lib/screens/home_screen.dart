import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import 'dpr_form.dart';
import 'mpr_form.dart';

import 'dpr_list.dart';
import 'mpr_list.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'forwarding_proforma.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final stats = await dbService.getDatabaseStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('e-MTC TC - Home'),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.home,
                            size: 48,
                            color: Color(0xFFD84315),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome to e-MTC TC',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Data Collection App',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Database Statistics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total DPR',
                                  value: _stats['totalDPR']?.toString() ?? '0',
                                  icon: Icons.description,
                                  color: const Color(0xFFD84315),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Total MPR',
                                  value: _stats['totalMPR']?.toString() ?? '0',
                                  icon: Icons.shopping_cart,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Pending DPR',
                                  value: _stats['unsyncedDPR']?.toString() ?? '0',
                                  icon: Icons.cloud_upload,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Pending MPR',
                                  value: _stats['unsyncedMPR']?.toString() ?? '0',
                                  icon: Icons.cloud_upload,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total FP',
                                  value: _stats['totalFP']?.toString() ?? '0',
                                  icon: Icons.location_on,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Pending FP',
                                  value: _stats['unsyncedFP']?.toString() ?? '0',
                                  icon: Icons.cloud_upload,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Navigation Section
                  const Text(
                    'Data Collection Forms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DPR Form Button
                  _FormCard(
                    title: 'Demographic Purchase Return (DPR)',
                    subtitle: 'Annual household demographic data collection',
                    icon: Icons.people,
                    color: const Color(0xFFD84315),
                    onTap: () => _navigateToForm(context, 'dpr'),
                  ),
                  const SizedBox(height: 12),

                  // MPR Form Button
                  _FormCard(
                    title: 'Monthly Purchase Return (MPR)',
                    subtitle: 'Bi-monthly purchase data collection',
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF795548), // Brown 600
                    onTap: () => _navigateToForm(context, 'mpr'),
                  ),
                  const SizedBox(height: 12),

                  // Dashboard Button
                  _FormCard(
                    title: 'Dashboard',
                    subtitle: 'View statistics and analytics',
                    icon: Icons.analytics,
                    color: const Color(0xFF8D6E63), // Brown 400
                    onTap: () => _navigateToForm(context, 'dashboard'),
                  ),
                  const SizedBox(height: 12),

                  // Forwarding Proforma Button
                  _FormCard(
                    title: 'Forwarding Proforma',
                    subtitle: 'Summary & submission to Regional Office',
                    icon: Icons.location_on,
                    color: const Color(0xFFAB47BC), // Purple 400
                    onTap: () => _navigateToForm(context, 'forwarding_proforma'),
                  ),
                                     const SizedBox(height: 32), // Extra padding at bottom
                 ],
               ),
             ),
           ),
    );
  }

  void _navigateToForm(BuildContext context, String formType) {
    switch (formType) {
      case 'dpr':
        _showDPROptions(context);
        break;
      case 'mpr':
        _showMPROptions(context);
        break;
      case 'dashboard':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;

      case 'forwarding_proforma':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForwardingProformaScreen()),
        ).then((_) => _loadStats()); // Refresh stats when returning
        break;
      default:
        break;
    }
  }

  void _showDPROptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DPR Options'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DPRFormScreen()),
              ).then((_) => _loadStats());
            },
            child: const Text('New DPR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DPRListScreen()),
              ).then((_) => _loadStats());
            },
            child: const Text('View/Edit DPRs'),
          ),
        ],
      ),
    );
  }

  void _showMPROptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('MPR Options'),
          content: const Text('Choose an option:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MPRFormScreen()),
                );
              },
              child: const Text('New MPR'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MPRListScreen()),
                );
              },
              child: const Text('View/Edit MPRs'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lo_phone');
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 