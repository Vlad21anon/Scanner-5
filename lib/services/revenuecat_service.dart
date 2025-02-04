import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// для вызова покупки подписки
// ElevatedButton(
// onPressed: () async {
// await RevenueCatService().purchaseSubscription("your_package_identifier");
// // После покупки повторно проверяем статус подписки
// bool subscribed = await RevenueCatService().isUserSubscribed();
// if (subscribed) {
// print("Подписка оформлена, обновляем UI");
// }
// },
// child: Text("Оформить подписку"),
// ),

class RevenueCatService {
  // Синглтон для доступа из разных частей приложения
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  /// Инициализация RevenueCat с использованием нового метода configure()
  Future<void> init() async {
    try {
      // Включаем отладочные логи (удобно для разработки)
      await Purchases.setLogLevel(LogLevel.debug);

      // Создаём конфигурацию с вашим API-ключом RevenueCat
      final configuration = PurchasesConfiguration("REVENUECAT_API_KEY");
      // Дополнительно можно указать параметры, например:
      // configuration.appUserID = "optional_user_id";
      // configuration.observerMode = false;

      // Инициализируем SDK с новой конфигурацией
      await Purchases.configure(configuration);
    } catch (e) {
      debugPrint("Ошибка инициализации RevenueCat: $e");
    }
  }

  /// Проверка, активна ли подписка пользователя
  Future<bool> isUserSubscribed() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // Если у пользователя есть хотя бы один активный entitlement – подписка оформлена
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint("Ошибка проверки подписки: $e");
      return false;
    }
  }

  /// Совершение покупки подписки по заданному идентификатору пакета
  Future<void> purchaseSubscription(String packageIdentifier) async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        // Ищем нужный пакет по идентификатору, иначе берем первый доступный
        final package = offerings.current!.availablePackages.firstWhere(
              (pkg) => pkg.identifier == packageIdentifier,
          orElse: () => offerings.current!.availablePackages.first,
        );
        // Совершаем покупку
        final customerInfo = await Purchases.purchasePackage(package);
        if (customerInfo.entitlements.active.isNotEmpty) {
          debugPrint("Подписка оформлена успешно");
        }
      } else {
        debugPrint("Нет доступных пакетов подписки");
      }
    } catch (e) {
      debugPrint("Ошибка покупки подписки: $e");
    }
  }
}
