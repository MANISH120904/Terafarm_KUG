import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String selectedCategory = 'Global';
  final ScrollController _scrollController = ScrollController();
  bool isYouVisibleInView = false;

  final List<Map<String, dynamic>> globalUsers = [
    {"name": "Rahul", "points": 3000, "image": "assets/images/Boy1.png"},
    {"name": "Mugesh", "points": 2980, "image": "assets/images/Boy2.png"},
    {"name": "Manibai", "points": 2450, "image": "assets/images/Boy3.png"},
    {"name": "Deepika", "points": 2000, "image": "assets/images/Girl1.png"},
    {"name": "Gaylu", "points": 1990, "image": "assets/images/Boy4.png"},
    {"name": "Gian", "points": 1500, "image": "assets/images/Boy5.png"},
    {"name": "MaddyBabu", "points": 1490, "image": "assets/images/Boy6.png"},
    {"name": "Kowchick", "points": 1400, "image": "assets/images/Boy7.png"},
    {"name": "Krithick", "points": 1300, "image": "assets/images/Boy8.png"},
    {"name": "Gokyy", "points": 1250, "image": "assets/images/Boy9.png"},
    {
      "name": "Arjun Mehta",
      "points": 1220,
      "image": "assets/images/Boy10.png",
    },
  ];

  final List<Map<String, dynamic>> localUsers = [
    {"name": "Ram", "points": 1800, "image": "assets/images/Boy10.png"},
    {"name": "Sita", "points": 1700, "image": "assets/images/Girl2.png"},
    {"name": "Geetha", "points": 1650, "image": "assets/images/Girl3.png"},
    {"name": "Vikram", "points": 1600, "image": "assets/images/Boy11.png"},
    {"name": "Rani", "points": 1500, "image": "assets/images/Girl4.png"},
  ];

  final Map<String, dynamic> you = {
    "name": "You",
    "points": 1350,
    "image": "assets/images/Boy12.png",
  };

  late List<Map<String, dynamic>> users;
  int youIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    // Approximate height of one row
    const rowHeight = 80.0;

    final scrollOffset = _scrollController.offset;
    final screenHeight = MediaQuery.of(context).size.height - 200;

    final visibleStartIndex = (scrollOffset / rowHeight).floor();
    final visibleEndIndex = (scrollOffset + screenHeight) ~/ rowHeight;

    final visible =
        youIndex >= visibleStartIndex && youIndex <= visibleEndIndex;

    if (visible != isYouVisibleInView) {
      setState(() {
        isYouVisibleInView = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepare list
    final combined = selectedCategory == 'Global'
        ? [...globalUsers, you]
        : [...localUsers, you];

    combined.sort((a, b) => b['points'].compareTo(a['points']));
    youIndex = combined.indexWhere((u) => u['name'] == 'You');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Colors.green[800],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'LeaderBoard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ToggleButtons(
                  isSelected: [
                    selectedCategory == 'Global',
                    selectedCategory == 'Local',
                  ],
                  onPressed: (index) {
                    setState(() {
                      selectedCategory = index == 0 ? 'Global' : 'Local';
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  selectedColor: Colors.white,
                  fillColor: Colors.green,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.public),
                          SizedBox(width: 8),
                          Text("Global"),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.location_on),
                          SizedBox(width: 8),
                          Text("Local"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Scrollable leaderboard
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: combined.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final user = combined[index];
                    final isYou = user['name'] == 'You';
                    final isTopRank = index == 0;
                    final rankDisplay =
                        index + 1 <= 1000 ? (index + 1).toString() : "-";

                    final row = ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rankDisplay,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            backgroundImage: AssetImage(user['image']),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(user['name'])),
                          if (isTopRank)
                            const Icon(Icons.emoji_events, color: Colors.amber),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up, color: Colors.green),
                          const SizedBox(width: 4),
                          Text("${user['points']} pts"),
                        ],
                      ),
                    );

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isYou ? Colors.green[50] : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: row,
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating "You" row when not visible
          if (!isYouVisibleInView)
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        youIndex + 1 <= 1000 ? '${youIndex + 1}' : "-",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(backgroundImage: AssetImage(you['image'])),
                    ],
                  ),
                  title: const Text("You"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green),
                      const SizedBox(width: 4),
                      Text("${you['points']} pts"),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
