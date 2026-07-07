import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Revivo credits — a loyalty balance where 1 credit = ₹1. Buyers earn 1 credit
/// for every ₹10 they save on an order and can redeem credits at checkout.
/// In-memory for the pilot (no wallet endpoint yet).
class WalletController extends Notifier<int> {
  @override
  int build() => 0;

  /// Credits earned from the rupees a buyer saved on an order (1 per ₹10).
  void earnFromSaved(double savedRupees) {
    final credits = (savedRupees / 10).floor();
    if (credits > 0) state = state + credits;
  }

  void spend(int amount) {
    if (amount <= 0) return;
    state = (state - amount).clamp(0, state);
  }
}

final walletProvider =
    NotifierProvider<WalletController, int>(WalletController.new);
