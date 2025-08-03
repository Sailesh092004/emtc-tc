import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dpr.dart';
import '../services/db_service.dart';
import 'dpr_form.dart';

class DPRListScreen extends StatefulWidget {
  const DPRListScreen({super.key});

  @override
  State<DPRListScreen> createState() => _DPRListScreenState();
}

class _DPRListScreenState extends State<DPRListScreen> {
  List<DPR> _dprList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDPRs();
  }

  Future<void> _loadDPRs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dprs = await dbService.getAllDPR();
      
      setState(() {
        _dprList = dprs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading DPR records: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editDPR(DPR dpr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DPRFormScreen(editingDPR: dpr),
      ),
    ).then((_) {
      // Refresh the list when returning from edit
      _loadDPRs();
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
                                icon: const Icon(Icons.edit, color: Colors.blue),
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