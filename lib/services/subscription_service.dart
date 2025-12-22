// lib/services/subscription_service.dart
class SubscriptionService {
  /// مؤقتاً: نعتبر المستخدم عنده وصول دائماً (للتجربة)
  static Future<bool> hasActiveAccess() async => true;

  /// شاشة الحساب كانت تستخدمه، نخليه يرجع null
  static Future<String?> getResolvedDeviceId() async => null;

  /// كان يرجع وثيقة اشتراك، الآن null
  static Future<dynamic> getActiveSubscriptionByDeviceId(String deviceId) async => null;

  /// تفعيل كود: حالياً نخليه ينجح دائماً
  static Future<String?> activateWithCode({required String code}) async {
    final c = code.trim();
    if (c.isEmpty) return 'اكتب الكود أولاً';
    // مؤقتاً: نجاح
    return null;
  }

  /// تجربة مجانية: نجاح دائماً
  static Future<String?> startTrialOnce() async {
    return null;
  }
}
