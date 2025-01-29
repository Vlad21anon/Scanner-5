import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Premium Subscription'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => _showSubscriptionDialog(context),
          ),
          ListTile(
            title: const Text('Rate App'),
            onTap: _rateApp,
          ),
          ListTile(
            title: const Text('Restore Purchases'),
            onTap: _restorePurchases,
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Go Premium'),
        content: const Text('Unlock all features'),
        actions: [
          TextButton(
            onPressed: () => _purchaseSubscription(),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseSubscription() async {
    // final iap = InAppPurchase.instance;
    // final products = await iap.queryProductDetails({'premium_monthly'});
    // if (products.isNotEmpty) {
    //   await iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: products.first));
    // }
  }

  Future<void> _restorePurchases() async {
    //await InAppPurchase.instance.restorePurchases();
  }

  void _rateApp() {
    // App Store rating logic
  }
}