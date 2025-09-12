import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  final List<Widget>? actions;

  const CustomHeader({
    super.key,
    required this.pageTitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            // Page title absolutely centered across entire width
            Center(
              child: Text(
                pageTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // "Meal Mate" positioned on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: const Text(
                  'Meal Mate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Logout button positioned on the right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                  icon: const Icon(Icons.logout, size: 22),
                  tooltip: 'Sign out',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
