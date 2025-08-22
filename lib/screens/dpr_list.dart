import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dpr.dart';
import '../services/db_service.dart';
import 'dpr_form.dart'; // Import DPRFormScreen for editing

class DPRListScreen extends StatefulWidget {
  const DPRListScreen({super.key});
  @override
  State<DPRListScreen> createState() => _DPRListScreenState();
}

class _DPRListScreenState extends State<DPRListScreen> {
  List<DPR> _dprList = [];
  bool _isLoading = true;
  String? _currentLoPhone;

  @override
  void initState() {
    super.initState();
    _loadCurrentLoAndDPRs();
  }

  Future<void> _loadCurrentLoAndDPRs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLoPhone = prefs.getString('lo_phone');
      
      if (_currentLoPhone != null) {
        await _loadDPRs();
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

  Future<void> _loadDPRs() async {
    if (_currentLoPhone == null) return;
    
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dprs = await dbService.getDPRsByLo(_currentLoPhone!);
      setState(() {
        _dprList = dprs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading DPRs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editDPR(DPR dpr) async {
    // Check if current LO owns this record
    if (_currentLoPhone != null && dpr.loPhone != _currentLoPhone) {
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
        builder: (context) => DPRFormScreen(editingDPR: dpr), // Pass DPR for editing
      ),
    ).then((_) {
      _loadDPRs(); // Refresh list on return
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DPR Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDPRs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dprList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No DPR records found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submit your first DPR to see it here',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDPRs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _dprList.length,
                    itemBuilder: (context, index) {
                      final dpr = _dprList[index];
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
                                      dpr.nameAndAddress,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Return No: ${dpr.returnNo} | Centre: ${dpr.centreCode}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editDPR(dpr),
                                icon: const Icon(Icons.edit, color: Color(0xFFD84315)),
                                tooltip: 'Edit DPR',
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
                                    '${dpr.district}, ${dpr.state}',
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
                                    'Family Size: ${dpr.familySize} | Income Group: ${dpr.incomeGroup}',
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
                                    'Submitted: ${_formatDate(dpr.createdAt)}',
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
                                    dpr.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                                    size: 16,
                                    color: dpr.isSynced ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dpr.isSynced ? 'Synced' : 'Pending Sync',
                                    style: TextStyle(
                                      color: dpr.isSynced ? Colors.green : Colors.orange,
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