import 'package:flutter/material.dart';
import 'centers_screen.dart';
import 'categories_screen.dart';
import 'tests_screen.dart';
import 'pricing_centers_screen.dart';
import 'admin_all_bookings_screen.dart';
import 'manage_notice_screen.dart';



class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item(context, 'Centers & Logins', const CentersScreen()),
          _item(context, 'Categories', const CategoriesScreen()),
          _item(context, 'Tests', const TestsScreen()),
          _item(context, 'Pricing (Center Wise)', const PricingCentersScreen()),
          _item(context, 'All Center Bookings', const AdminAllBookingsScreen()),
          _item(context, 'Manage Home Notice', const ManageNoticeScreen()),


        ],
      ),
    );
  }

  Widget _item(BuildContext context, String title, Widget page) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}
