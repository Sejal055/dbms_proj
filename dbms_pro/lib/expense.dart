import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'package:dbms_pro/home_page.dart';

// class ExpenseForm extends StatefulWidget {
//   @override
//   _ExpenseFormState createState() => _ExpenseFormState();
// }

// class _ExpenseFormState extends State<ExpenseForm> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _amountInAccountController = TextEditingController();
//   final TextEditingController _monthBudgetController = TextEditingController();

//   // Function to add expense to Firestore
//   Future<void> _addExpense() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         await FirebaseFirestore.instance.collection('expenses').add({
//           'amountInAccount': double.parse(_amountInAccountController.text.trim()),
//           'monthBudget': double.parse(_monthBudgetController.text.trim()),
//           'createdAt': FieldValue.serverTimestamp(),
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Details saved successfully!")),
//         );

//         // Clear form after submit
//         _amountInAccountController.clear();
//         _monthBudgetController.clear();

//         // Navigate to the home page after successful submission
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => HomePage()),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: $e")),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _amountInAccountController.dispose();
//     _monthBudgetController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 50),
//               const Text(
//                 "Welcome to\nBudget Buddy!",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 "Let's make budgeting simple\nand fun.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 50),
//               const Text(
//                 "Enter your details",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE0E0E0),
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.3),
//                       spreadRadius: 2,
//                       blurRadius: 5,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       // Amount in Account
//                       TextFormField(
//                         controller: _amountInAccountController,
//                         decoration: InputDecoration(
//                           labelText: "Amount in Account",
//                           labelStyle: const TextStyle(color: Colors.black54),
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide.none,
//                           ),
//                           prefixText: "Rs. ",
//                         ),
//                         keyboardType: TextInputType.number,
//                         validator: (value) =>
//                             value == null || value.isEmpty ? "Enter amount" : null,
//                       ),

//                       const SizedBox(height: 16),

//                       // Monthly Budget
//                       TextFormField(
//                         controller: _monthBudgetController,
//                         decoration: InputDecoration(
//                           labelText: "Monthly Budget",
//                           labelStyle: const TextStyle(color: Colors.black54),
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide.none,
//                           ),
//                           prefixText: "Rs. ",
//                         ),
//                         keyboardType: TextInputType.number,
//                         validator: (value) =>
//                             value == null || value.isEmpty ? "Enter monthly budget" : null,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: _addExpense,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF86E3CE),
//                   padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   shadowColor: Colors.grey,
//                   elevation: 5,
//                 ),
//                 child: const Text(
//                   "Lets go!",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

/*class ExpensesPage extends StatelessWidget {
  final String category;
  const ExpensesPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('Expenses - $category')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('expenses')
            .where('category', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            //.where('timestamp', isNotEqualTo: null)
            .snapshots(),
        // builder: (context, snapshot) {
        //   if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        //   if (snapshot.data!.docs.isEmpty) return Center(child: Text('No expenses in "$category"'));
        //   return ListView(
        //     children: snapshot.data!.docs.map((doc) {
        //       final d = doc.data() as Map<String, dynamic>;
        //       return ListTile(
        //         title: Text(d['expense_name']),
        //         subtitle: Text(d['expense_type'] ?? 'Expense'),
        //         trailing: Text('₹${d['expense_amount']}', style: TextStyle(fontWeight: FontWeight.bold)),
        //       );
        //     }).toList(),
        //   );
        // },
        builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading expenses'));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        // Filter out documents without timestamp so ListView gets only valid data
        //final docs = snapshot.data!.docs.where((doc) => doc.data()['timestamp'] != null).toList();
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['timestamp'] != null;
        }).toList();

        
        if (docs.isEmpty) {
          return Center(child: Text('No expenses in "$category"'));
        }
        return ListView(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(d['expense_name']),
              subtitle: Text(d['expense_type'] ?? 'Expense'),
              trailing: Text('₹${d['expense_amount']}', style: TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
        );
      },

      ),
    );
  }
}*/

class ExpensesPage extends StatelessWidget {
  final String category;

  const ExpensesPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses - $category'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('expenses')
            .where('category', isEqualTo: category)
            //.orderBy('createdAtLocal', descending: true) // ✅ now safe
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Optional debug print
            print('Firestore error: ${snapshot.error}');
            return const Center(child: Text('Error loading expenses'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text('No expenses in "$category"'));
          }

          // ✅ Calculate total amount
          final double total = docs.fold(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = data['expense_amount'];
            return sum + ((amount is num) ? amount.toDouble() : 0);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Display total amount
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total: ₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['expense_name'] ?? 'Unnamed';
                    final type = data['expense_type'] ?? 'Expense';
                    final amount = data['expense_amount'];
                    final displayAmount =
                        (amount is num) ? amount.toString() : '0.00';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(type),
                      trailing: Text(
                        '₹$displayAmount',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
