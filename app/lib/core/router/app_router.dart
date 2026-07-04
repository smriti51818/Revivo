import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/shared/placeholder_screen.dart';
import '../models/user_role.dart';
import '../widgets/scaffold_with_nav_bar.dart';

/// App router. Auth screens are top-level; each role gets a stateful shell
/// with its own bottom navigation. Feature tabs land in later modules and
/// currently render a styled placeholder.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/role', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(role: state.extra as UserRole?),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterScreen(role: state.extra as UserRole?),
      ),

      // ─── Seller shell ───────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNavBar(
          navigationShell: shell,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'List'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Insights'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
        branches: [
          _branch('/seller/dashboard', const PlaceholderScreen(
              title: 'Seller dashboard',
              icon: Icons.dashboard_outlined,
              message: 'Your inventory, sales, and listings land here in M4.')),
          _branch('/seller/orders', const PlaceholderScreen(
              title: 'Order requests',
              icon: Icons.receipt_long_outlined,
              message: 'Approve or reject incoming orders — coming in M5.')),
          _branch('/seller/add', const PlaceholderScreen(
              title: 'Add listing',
              icon: Icons.add_circle_outline,
              message: 'Photo → AI ID → freshness band → publish (M4).')),
          _branch('/seller/insights', const PlaceholderScreen(
              title: 'Vendor insights',
              icon: Icons.insights_outlined,
              message: 'Demand prediction and impact insights (M11).')),
          _branch('/seller/profile', const PlaceholderScreen(
              title: 'Profile',
              icon: Icons.person_outline,
              message: 'Account, trust badge, and settings.')),
        ],
      ),

      // ─── Buyer shell ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNavBar(
          navigationShell: shell,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Market'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders'),
            NavigationDestination(
                icon: Icon(Icons.eco_outlined),
                selectedIcon: Icon(Icons.eco),
                label: 'Impact'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
        branches: [
          _branch('/buyer/home', const PlaceholderScreen(
              title: 'Nearby surplus',
              icon: Icons.storefront_outlined,
              message: 'Nearby & aggregated listings with freshness bands (M5).')),
          _branch('/buyer/orders', const PlaceholderScreen(
              title: 'My orders',
              icon: Icons.receipt_long_outlined,
              message: 'Current and past orders (M5).')),
          _branch('/buyer/impact', const PlaceholderScreen(
              title: 'Impact',
              icon: Icons.eco_outlined,
              message: 'Savings vs market price and surplus utilised (M10).')),
          _branch('/buyer/profile', const PlaceholderScreen(
              title: 'Profile',
              icon: Icons.person_outline,
              message: 'Account and settings.')),
        ],
      ),

      // ─── Cook / NGO shell ───────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNavBar(
          navigationShell: shell,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox),
                label: 'Rescues'),
            NavigationDestination(
                icon: Icon(Icons.eco_outlined),
                selectedIcon: Icon(Icons.eco),
                label: 'Impact'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
        branches: [
          _branch('/cook/inbox', const PlaceholderScreen(
              title: 'Rescue inbox',
              icon: Icons.inbox_outlined,
              message: 'Incoming rescues with Bedrock explanations (M8).')),
          _branch('/cook/impact', const PlaceholderScreen(
              title: 'Impact',
              icon: Icons.eco_outlined,
              message: 'Rescues accepted, kg transformed, meals served (M10).')),
          _branch('/cook/profile', const PlaceholderScreen(
              title: 'Profile',
              icon: Icons.person_outline,
              message: 'Kitchen capacity, hours, and preferences.')),
        ],
      ),

      // ─── Volunteer shell ────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNavBar(
          navigationShell: shell,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: 'Pickups'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
        branches: [
          _branch('/volunteer/tasks', const PlaceholderScreen(
              title: 'Pickup tasks',
              icon: Icons.local_shipping_outlined,
              message: 'Two-tap pickup: Picked up → Delivered (M9).')),
          _branch('/volunteer/profile', const PlaceholderScreen(
              title: 'Profile',
              icon: Icons.person_outline,
              message: 'NSS unit and documented service hours.')),
        ],
      ),
    ],
  );
});

/// Builds a single-route shell branch.
StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => screen)],
  );
}
