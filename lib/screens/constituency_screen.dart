import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/constituency.dart';
import '../services/constituency_data_service.dart';
import '../services/database_service.dart';

class ConstituencyScreen extends StatefulWidget {
  const ConstituencyScreen({super.key});

  @override
  State<ConstituencyScreen> createState() => _ConstituencyScreenState();
}

class _ConstituencyScreenState extends State<ConstituencyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Constituency> _filteredConstituencies = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _filteredConstituencies = DatabaseService.instance.getAllConstituencies();
      _statistics = ConstituencyDataService.getConstituencyStatistics();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredConstituencies = ConstituencyDataService.searchConstituencies(
        query,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mauritius Constituencies'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'List'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Demographics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(),
          _buildStatisticsTab(),
          _buildDemographicsTab(),
        ],
      ),
    );
  }

  Widget _buildListTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'Search constituencies',
              hintText: 'Search by name, number, or ethnic group',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Constituency List
        Expanded(
          child: _filteredConstituencies.isEmpty
              ? const Center(child: Text('No constituencies found'))
              : ListView.builder(
                  itemCount: _filteredConstituencies.length,
                  itemBuilder: (context, index) {
                    final constituency = _filteredConstituencies[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${constituency.constituencyNo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          constituency.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Population: ${NumberFormat('#,###').format(constituency.electoralPopulation)}',
                            ),
                            Text(
                              'Ethnic Majority: ${constituency.ethnicMajority}',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    if (_statistics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final largest = _statistics['largestConstituency'] as Constituency;
    final smallest = _statistics['smallestConstituency'] as Constituency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        title: 'Total Constituencies',
                        value: '${_statistics['totalConstituencies']}',
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Total Population',
                        value: NumberFormat(
                          '#,###',
                        ).format(_statistics['totalElectoralPopulation']),
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StatCard(
                    title: 'Average Population',
                    value: NumberFormat(
                      '#,###',
                    ).format(_statistics['averagePopulation']),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Largest & Smallest
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Population Extremes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Largest
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Largest Constituency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text('${largest.constituencyNo}. ${largest.name}'),
                        Text(
                          'Population: ${NumberFormat('#,###').format(largest.electoralPopulation)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Smallest
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smallest Constituency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text('${smallest.constituencyNo}. ${smallest.name}'),
                        Text(
                          'Population: ${NumberFormat('#,###').format(smallest.electoralPopulation)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsTab() {
    if (_statistics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final ethnicBreakdown = _statistics['ethnicBreakdown'] as Map<String, int>;
    final sortedEthnicGroups = ethnicBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ethnic Majority Distribution',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ...sortedEthnicGroups.map((entry) {
                    final percentage =
                        (entry.value /
                        _statistics['totalConstituencies'] *
                        100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
