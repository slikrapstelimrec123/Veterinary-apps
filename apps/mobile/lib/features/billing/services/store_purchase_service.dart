import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../data/billing_repository.dart';

class LappoProducts {
  static const proMonthly = 'lappo_pro_monthly';
  static const proYearly = 'lappo_pro_yearly';
  static const proPlusMonthly = 'lappo_pro_plus_monthly';
  static const proPlusYearly = 'lappo_pro_plus_yearly';
  static const listingStandard = 'lappo_listing_standard';
  static const listingTop7 = 'lappo_listing_top_7';
  static const listingTop15 = 'lappo_listing_top_15';

  static const all = <String>{
    proMonthly,
    proYearly,
    proPlusMonthly,
    proPlusYearly,
    listingStandard,
    listingTop7,
    listingTop15,
  };

  static bool isListing(String id) => id.startsWith('lappo_listing_');
}

class StorePurchaseService {
  StorePurchaseService({BillingRepository? repository})
      : _repository = repository ?? BillingRepository();

  final BillingRepository _repository;
  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _updates = StreamController<StorePurchaseUpdate>.broadcast();

  Stream<StorePurchaseUpdate> get updates => _updates.stream;

  Future<List<ProductDetails>> initialize() async {
    _subscription ??= _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        _updates.add(StorePurchaseUpdate.error(error.toString()));
      },
    );
    if (!await _store.isAvailable()) return const [];
    final response = await _store.queryProductDetails(LappoProducts.all);
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    final result = response.productDetails.toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    return result;
  }

  Future<bool> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    if (LappoProducts.isListing(product.id)) {
      return _store.buyConsumable(
        purchaseParam: param,
        autoConsume: false,
      );
    }
    return _store.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _store.restorePurchases();

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _updates.add(StorePurchaseUpdate.pending(purchase.productID));
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        _updates.add(StorePurchaseUpdate.error(
          purchase.error?.message ?? 'Помилка магазину.',
        ));
      } else if (purchase.status == PurchaseStatus.canceled) {
        _updates.add(StorePurchaseUpdate.cancelled(purchase.productID));
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await _repository.verifyPurchase(
            productId: purchase.productID,
            verificationData: purchase.verificationData.serverVerificationData,
            source: Platform.isIOS ? 'apple' : 'google',
            transactionDate:
                purchase.transactionDate ?? DateTime.now().toIso8601String(),
          );
          if (Platform.isAndroid &&
              LappoProducts.isListing(purchase.productID)) {
            final addition = _store.getPlatformAddition<
                InAppPurchaseAndroidPlatformAddition>();
            await addition.consumePurchase(purchase);
          }
          _updates.add(StorePurchaseUpdate.completed(purchase.productID));
        } catch (error) {
          _updates.add(StorePurchaseUpdate.error(
            'Покупку отримано, але не вдалося підтвердити. '
            'Вона буде відновлена автоматично.',
          ));
          continue;
        }
      }
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _updates.close();
  }
}

class StorePurchaseUpdate {
  const StorePurchaseUpdate._(this.state, this.productId, this.message);

  final StorePurchaseState state;
  final String? productId;
  final String? message;

  factory StorePurchaseUpdate.pending(String id) =>
      StorePurchaseUpdate._(StorePurchaseState.pending, id, null);
  factory StorePurchaseUpdate.completed(String id) =>
      StorePurchaseUpdate._(StorePurchaseState.completed, id, null);
  factory StorePurchaseUpdate.cancelled(String id) =>
      StorePurchaseUpdate._(StorePurchaseState.cancelled, id, null);
  factory StorePurchaseUpdate.error(String message) =>
      StorePurchaseUpdate._(StorePurchaseState.error, null, message);
}

enum StorePurchaseState { pending, completed, cancelled, error }
