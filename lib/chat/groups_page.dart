import 'package:flutter/material.dart';
import 'group_details_page.dart'; // Import the details page

// --- COLORS (from your other files for consistency) ---
const Color primaryColor = Color(0xFF7BAFFC);
const Color secondaryColor = Color(0xFFD6A8FF);
const Color accentColor = Color(0xFFEAEFFF);

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Dummy Data (Replace with Firestore later) ---
  final List<Map<String, dynamic>> _groups = [
    {
      'name': 'Goa Trip 2025',
      'imageUrl': 'https://i.pravatar.cc/150?img=5',
      'totalSpent': 15000.0,
      'myShare': 800.0, // Positive means I am owed
    },
    {
      'name': 'Team Lunch',
      'imageUrl': 'https://i.pravatar.cc/150?img=11',
      'totalSpent': 3200.0,
      'myShare': -250.0, // Negative means I owe
    },
  ];

  // Data for the "Overall" tab's detailed list
  final List<Map<String, dynamic>> _overallDebts = [
    {
      'person': 'Aditi',
      'amount': 250.0,
      'youOwe': true, // You owe her
      'group': 'Team Lunch',
    },
    {
      'person': 'Riya',
      'amount': 800.0,
      'youOwe': false, // She owes you
      'group': 'Goa Trip 2025',
    },
    {
      'person': 'Sarah Rollins',
      'amount': 120.0,
      'youOwe': false, // She owes you
      'group': 'Weekend Hangout',
    },
  ];

  // Summary data for the "Overall" tab
  final double _totalOwedToMe = 920.0; // 800 + 120
  final double _totalIOwe = 250.0;
  // --- End Dummy Data ---

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Groups",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        // MODIFICATION: Removed 'automaticallyImplyLeading: false' to show back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: "GROUPS"),
            Tab(text: "OVERALL"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildOverallTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Link to a new "Create Group" page
          print("Add new group");
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.group_add),
      ),
    );
  }

  // --- Tab 1: List of all groups (Unchanged) ---
  Widget _buildGroupsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final myShare = group['myShare'];
        final String shareText = myShare > 0
            ? 'You are owed ₹${myShare.abs().toStringAsFixed(0)}'
            : 'You owe ₹${myShare.abs().toStringAsFixed(0)}';
        final Color shareColor = myShare > 0 ? Colors.green : Colors.red;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(group['imageUrl']),
            ),
            title: Text(
              group['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              shareText,
              style: TextStyle(color: shareColor, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailsPage(
                    groupName: group['name'],
                    groupImageUrl: group['imageUrl'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- Tab 2: Overall Summary (NEW FULLY REPLACED WIDGET) ---
  Widget _buildOverallTab() {
    // Summary calculations
    final netBalance = _totalOwedToMe - _totalIOwe;
    final String netText = netBalance > 0
        ? 'You are owed ₹${netBalance.abs().toStringAsFixed(0)} overall'
        : 'You owe ₹${netBalance.abs().toStringAsFixed(0)} overall';
    final Color netColor = netBalance > 0 ? Colors.green : Colors.red;

    // Filter the detailed lists
    final youOweList =
        _overallDebts.where((debt) => debt['youOwe'] == true).toList();
    final owedToYouList =
        _overallDebts.where((debt) => debt['youOwe'] == false).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Summary Section ---
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Your Overall Balance",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                netText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: netColor,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // --- Detailed Lists Section ---
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 16),
            children: [
              // --- "You Owe" List ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "YOU OWE",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red),
                ),
              ),
              if (youOweList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("You don't owe anyone. Great!",
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...youOweList.map((debt) {
                  return _buildDebtListItem(
                    person: debt['person'],
                    group: debt['group'],
                    amount: debt['amount'],
                    youOwe: true,
                  );
                }).toList(),

              const SizedBox(height: 20),

              // --- "You Are Owed" List ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "YOU ARE OWED",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green),
                ),
              ),
              if (owedToYouList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No one owes you anything right now.",
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...owedToYouList.map((debt) {
                  return _buildDebtListItem(
                    person: debt['person'],
                    group: debt['group'],
                    amount: debt['amount'],
                    youOwe: false,
                  );
                }).toList(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // --- NEW HELPER WIDGET for the debt list items ---
  Widget _buildDebtListItem(
      {required String person,
      required String group,
      required double amount,
      required bool youOwe}) {
    final Color color = youOwe ? Colors.red : Colors.green;
    final String text = youOwe
        ? 'You owe ₹${amount.abs().toStringAsFixed(0)}'
        : 'Owes you ₹${amount.abs().toStringAsFixed(0)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            person.isNotEmpty ? person[0] : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          person,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'From group: $group',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}