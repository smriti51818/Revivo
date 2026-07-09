import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/confirm_code_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/buyer/buyer_market_screen.dart';
import '../../features/buyer/buyer_orders_screen.dart';
import '../../features/buyer/buyer_ending_soon_screen.dart';
import '../../features/buyer/cart_screen.dart';
import '../../features/buyer/checkout_screen.dart';
import '../../features/buyer/domain/offer.dart';
import '../../features/buyer/domain/order.dart';
import '../../features/buyer/order_confirmed_screen.dart';
import '../../features/buyer/order_details_screen.dart';
import '../../features/buyer/order_tracking_screen.dart';
import '../../features/buyer/product_details_screen.dart';
import '../../features/buyer/rescue_map_screen.dart';
import '../../features/buyer/vendor_profile_screen.dart';
import '../../features/impact/impact_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/rescue/rescue_board_screen.dart';
import '../../features/seller/add_listing_screen.dart';
import '../../features/seller/domain/listing.dart';
import '../../features/seller/seller_dashboard_screen.dart';
import '../../features/seller/seller_documents_screen.dart';
import '../../features/seller/seller_edit_profile_screen.dart';
import '../../features/seller/seller_insights_screen.dart';
import '../../features/seller/seller_listings_screen.dart';
import '../../features/seller/seller_order_details_screen.dart';
import '../../features/seller/seller_reviews_screen.dart';

import '../../features/seller/seller_orders_screen.dart';
import '../../features/seller/update_stock_screen.dart';
import '../../features/shared/account_details_screen.dart';
import '../../features/shared/help_screen.dart';
import '../../features/shared/profile_screen.dart';
import '../../features/shared/refer_screen.dart';
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
      GoRoute(
        path: '/confirm-code',
        builder: (_, state) =>
            ConfirmCodeScreen(args: state.extra as ConfirmCodeArgs),
      ),

      // Buyer flow screens presented above the shell (full-page, with back).
      GoRoute(
        path: '/buyer/product',
        builder: (_, state) =>
            ProductDetailsScreen(offer: state.extra as Offer),
      ),
      GoRoute(
        path: '/buyer/vendor',
        builder: (_, state) =>
            VendorProfileScreen(vendorName: state.extra as String),
      ),
      GoRoute(path: '/buyer/map', builder: (_, _) => const RescueMapScreen()),
      GoRoute(path: '/buyer/cart', builder: (_, _) => const CartScreen()),
      GoRoute(
        path: '/account',
        builder: (_, _) => const AccountDetailsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationCenterScreen(),
      ),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(path: '/refer', builder: (_, _) => const ReferScreen()),
      GoRoute(path: '/rescues', builder: (_, _) => const RescueBoardScreen()),
      GoRoute(
        path: '/seller/order',
        builder: (_, state) =>
            SellerOrderDetailsScreen(order: state.extra as Order),
      ),
      GoRoute(
        path: '/buyer/checkout',
        builder: (_, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/buyer/order-confirmed',
        builder: (_, state) =>
            OrderConfirmedScreen(orders: state.extra as List<Order>),
      ),
      GoRoute(
        path: '/buyer/order',
        builder: (_, state) => OrderDetailsScreen(order: state.extra as Order),
      ),
      GoRoute(
        path: '/buyer/track',
        builder: (_, state) => OrderTrackingScreen(order: state.extra as Order),
      ),
      GoRoute(
        path: '/buyer/ending-soon',
        builder: (_, _) => const BuyerEndingSoonScreen(),
      ),

      // ─── Seller shell ───────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNavBar(
          navigationShell: shell,
          destinations: const [
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedHome11),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedHome11),
              label: 'Home',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedInvoice01),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedInvoice01),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedPlusSign),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedPlusSign),
              label: 'List',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedChartLineData01),
              selectedIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedChartLineData01,
              ),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle),
              label: 'Profile',
            ),
          ],
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/dashboard',
                builder: (_, _) => const SellerDashboardScreen(),
              ),
              GoRoute(
                path: '/seller/listings',
                builder: (_, _) => const SellerListingsScreen(),
              ),
            ],
          ),
          _branch('/seller/orders', const SellerOrdersScreen()),
          _branch('/seller/add', const AddListingScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/insights',
                builder: (_, _) => const SellerInsightsScreen(),
              ),
              GoRoute(
                path: '/seller/update-stock',
                builder: (_, state) =>
                    UpdateStockScreen(listing: state.extra as Listing),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
              GoRoute(
                path: '/seller/profile/edit',
                builder: (_, _) => const SellerEditProfileScreen(),
              ),
              GoRoute(
                path: '/seller/profile/documents',
                builder: (_, _) => const SellerDocumentsScreen(),
              ),
              GoRoute(
                path: '/seller/profile/reviews',
                builder: (_, _) => const SellerReviewsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─── Buyer shell ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNavBar(
          navigationShell: shell,
          destinations: const [
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedStore01),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedStore01),
              label: 'Market',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedInvoice01),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedInvoice01),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedLeaf02),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedLeaf02),
              label: 'Impact',
            ),
            NavigationDestination(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedUser),
              selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedUser),
              label: 'Profile',
            ),
          ],
        ),
        branches: [
          _branch('/buyer/home', const BuyerMarketScreen()),
          _branch('/buyer/orders', const BuyerOrdersScreen()),
          _branch('/buyer/impact', const ImpactScreen()),
          _branch('/buyer/profile', const ProfileScreen()),
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
