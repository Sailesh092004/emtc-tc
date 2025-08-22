import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mpr.dart';
import '../services/db_service.dart';
import 'mpr_form.dart'; // Import MPRFormScreen for editing

class MPRListScreen extends StatefulWidget {
  const MPRListScreen({super.key});
  @override
  State<MPRListScreen> createState() => _MPRListScreenState();
}

class _MPRListScreenState extends State<MPRListScreen> {
  List<MPR> _mprList = [];
  bool _isLoading = true;
  String? _currentLoPhone;

  @override
  void initState() {
    super.initState();
    _loadCurrentLoAndMPRs();
  }

  Future<void> _loadCurrentLoAndMPRs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLoPhone = prefs.getString('lo_phone');
      
      if (_currentLoPhone != null) {
        await _loadMPRs();
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMPRs() async {
    if (_currentLoPhone == null) return;
    
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final mprs = await dbService.getMPRsByLo(_currentLoPhone!);
      setState(() {
        _mprList = mprs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading MPRs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editMPR(MPR mpr) async {
    // Check if current LO owns this record
    if (_currentLoPhone != null && mpr.loPhone != _currentLoPhone) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only edit records you created'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MPRFormScreen(editingMPR: mpr), // Pass MPR for editing
      ),
    ).then((_) {
      _loadMPRs(); // Refresh list on return
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MPR Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMPRs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mprList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No MPR records found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submit your first MPR to see it here',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMPRs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mprList.length,
                    itemBuilder: (context, index) {
                      final mpr = _mprList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mpr.nameAndAddress,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Return No: ${mpr.returnNo} | Centre: ${mpr.centreCode}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editMPR(mpr),
                                icon: const Icon(Icons.edit, color: Color(0xFFD84315)),
                                tooltip: 'Edit MPR',
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mpr.districtStateTel,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Family Size: ${mpr.familySize} | Income Group: ${mpr.incomeGroup}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Items: ${mpr.items.length} | Month: ${mpr.monthAndYear}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Submitted: ${_formatDate(mpr.createdAt)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    mpr.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                                    size: 16,
                                    color: mpr.isSynced ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mpr.isSynced ? 'Synced' : 'Pending Sync',
                                    style: TextStyle(
                                      color: mpr.isSynced ? Colors.green : Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
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