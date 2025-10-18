import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String description;
  final String? subDescription;
  final String? amount;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color? iconColor;
  final String timeAndDate;

  const NotificationItem({
    required this.title,
    required this.description,
    this.subDescription,
    this.amount,
    required this.icon,
    required this.iconBackgroundColor,
    this.iconColor,
    required this.timeAndDate,
  });
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  final List<Map<String, List<NotificationItem>>> groupedNotifications = const [
    {
      'Today': [
        NotificationItem(
          title: 'Reminder!',
          description: 'Set up your automatic savings to meet your savings goal...',
          icon: Icons.notifications_none_rounded,
          iconBackgroundColor: Color(0xFFFEECEF), // Light pink for icon background
          timeAndDate: '17:00 - April 24',
        ),
        NotificationItem(
          title: 'New Update',
          description: 'Set up your automatic savings to meet your savings goal...',
          icon: Icons.star_border_rounded,
          iconBackgroundColor: Color(0xFFFAEBE7), // Another light pink/orange shade
          timeAndDate: '17:00 - April 24',
        ),
      ]
    },
    {
      'Yesterday': [
        NotificationItem(
          title: 'Transactions',
          description: 'A new transaction has been registered',
          subDescription: 'Groceries | Pantry',
          amount: '- ₹100.00',
          icon: Icons.attach_money_rounded,
          iconBackgroundColor: Color(0xFFFAD7DD), // Muted pink
          iconColor: Color(0xFFD32F2F), // Red for negative amount
          timeAndDate: '17:00 - April 24',
        ),
        NotificationItem(
          title: 'Reminder!',
          description: 'Set up your automatic savings to meet your savings goal...',
          icon: Icons.notifications_none_rounded,
          iconBackgroundColor: Color(0xFFFEECEF), // Light pink
          timeAndDate: '17:00 - April 24',
        ),
      ]
    },
    {
      'This Weekend': [
        NotificationItem(
          title: 'Expense Record',
          description: 'We recommend that you be more attentive to your finances.',
          icon: Icons.arrow_downward_rounded,
          iconBackgroundColor: Color(0xFFFAEBE7), // Light pink/orange
          timeAndDate: '17:00 - April 24',
        ),
        NotificationItem(
          title: 'Transactions',
          description: 'A new transaction has been registered',
          subDescription: 'Food | Dinner',
          amount: '- ₹70.40',
          icon: Icons.attach_money_rounded,
          iconBackgroundColor: Color(0xFFFAD7DD), // Muted pink
          iconColor: Color(0xFFD32F2F), // Red for negative amount
          timeAndDate: '17:00 - April 23',
        ),
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Primary pinkish colors for the AppBar gradient
    const Color primaryPinkLight = Color(0xFFFEE4E7); // Lighter pink
    const Color primaryPinkDark = Color(0xFFFADCDC); // Slightly darker pink

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Consistent with HomePage background
      body: Column(
        children: [
          // Custom AppBar with pink gradient
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryPinkLight, primaryPinkDark], // Pink gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const Text(
                  'Notification',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
                  onPressed: () {
                    // Action for notification icon on notification page
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, groupIndex) {
                final entry = groupedNotifications[groupIndex].entries.first;
                final String groupTitle = entry.key;
                final List<NotificationItem> notifications = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        groupTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ...notifications.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.iconBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: item.iconColor ?? Colors.black87),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (item.subDescription != null || item.amount != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (item.subDescription != null)
                                          Text(
                                            item.subDescription!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        if (item.subDescription != null && item.amount != null)
                                          const Text(' | ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (item.amount != null)
                                          Text(
                                            item.amount!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: item.amount!.startsWith('-') ? Colors.red : Colors.green,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                item.timeAndDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}