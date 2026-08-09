import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/common/models/response_model.dart';
import 'package:shoplancer_vendor/features/business/domain/models/package_model.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplancer_vendor/features/auth/domain/repositories/auth_repository_interface.dart';

class AuthRepository implements AuthRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  AuthRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response> login(String? phone, String? countryCode, String password, String type) async {
    return await apiClient.postData(AppConstants.loginUri, {
      "phone": phone,
      "country_code": countryCode,
      "password": password,
      'vendor_type': type,
    }, handleError: false);
  }

  @override
  Future<Response> registerRestaurant(
    Map<String, String> data,
    XFile? logo,
    XFile? cover,
    List<MultipartDocument> tinFiles,
  ) async {
    return await apiClient.postMultipartData(
      AppConstants.restaurantRegisterUri,
      data,
      [MultipartBody('logo', logo), MultipartBody('cover_photo', cover)],
      multipartDocument: tinFiles,
    );
  }

  @override
  Future<ResponseModel> checkSlug(String slug) async {
    Response response = await apiClient.getData('${AppConstants.checkSlugUri}$slug');
    if (response.statusCode == 200) {
      bool exist = response.body['exist'] == true || response.body['exist']?.toString() == 'true';
      if (exist) {
        String msg = (response.body['message'] ?? '').toString().trim();
        return ResponseModel(false, msg.isNotEmpty ? msg : 'slug_already_exists');
      } else {
        return ResponseModel(true, 'slug_is_available');
      }
    } else {
      return ResponseModel(false, 'failed_to_validate_slug');
    }
  }

  @override
  Future<Response> updateToken() async {
    String? deviceToken;
    // Desktop (Windows/macOS/Linux) builds don't ship Firebase config and
    // don't need push notifications for the POS flow, so skip Firebase
    // Messaging there instead of crashing with "No Firebase App '[DEFAULT]'".
    if (!GetPlatform.isMobile && !GetPlatform.isWeb) {
      // Desktop has no push notifications; server validation just requires
      // a non-empty value here, so send a placeholder instead of ''.
      return await apiClient.postData(AppConstants.tokenUri, {
        "_method": "put",
        "token": getUserToken(),
        "fcm_token": 'desktop-no-push-support',
      }, handleError: false);
    }
    if (GetPlatform.isIOS) {
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        deviceToken = await _saveDeviceToken();
      }
    } else {
      deviceToken = await _saveDeviceToken();
    }
    if (!GetPlatform.isWeb) {
      FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic);
      FirebaseMessaging.instance.subscribeToTopic(
        sharedPreferences.getString(AppConstants.zoneTopic)!,
      );
    }
    return await apiClient.postData(AppConstants.tokenUri, {
      "_method": "put",
      "token": getUserToken(),
      "fcm_token": deviceToken,
    }, handleError: false);
  }

  Future<String?> _saveDeviceToken() async {
    String? deviceToken = '';
    if (!GetPlatform.isWeb && GetPlatform.isMobile) {
      deviceToken = (await FirebaseMessaging.instance.getToken())!;
    }
    if (kDebugMode) {
      print('-----Device Token----- $deviceToken');
    }
    return deviceToken;
  }

  @override
  Future<bool> saveUserToken(
    String token,
    String zoneTopic,
    String type,
  ) async {
    apiClient.updateHeader(
      token,
      sharedPreferences.getString(AppConstants.languageCode),
      null,
      type,
    );
    sharedPreferences.setString(AppConstants.zoneTopic, zoneTopic);
    sharedPreferences.setString(AppConstants.type, type);
    return await sharedPreferences.setString(AppConstants.token, token);
  }

  @override
  String getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  @override
  bool isLoggedIn() {
    return sharedPreferences.containsKey(AppConstants.token);
  }

  @override
  Future<bool> clearSharedData() async {
    if (!GetPlatform.isWeb) {
      apiClient.postData(AppConstants.tokenUri, {
        "_method": "put",
        "token": getUserToken(),
        "fcm_token": '@',
      }, handleError: false);
      // Firebase isn't configured/initialized on desktop builds.
      if (GetPlatform.isMobile) {
        FirebaseMessaging.instance.unsubscribeFromTopic(
          sharedPreferences.getString(AppConstants.zoneTopic)!,
        );
      }
    }
    await sharedPreferences.remove(AppConstants.token);
    await sharedPreferences.remove(AppConstants.userAddress);
    await sharedPreferences.remove(AppConstants.type);
    await sharedPreferences.remove(AppConstants.moduleType);
    return true;
  }

  @override
  Future<void> saveUserNumberAndPassword(
    String number,
    String password,
    String type,
  ) async {
    try {
      // SECURITY: passwords must never be persisted in plaintext (SharedPreferences
      // is unencrypted storage on both Android and iOS). Only the phone number and
      // vendor type are remembered to prefill the login form; the password field is
      // always left blank for the user to re-enter.
      await sharedPreferences.remove(AppConstants.userPassword);
      await sharedPreferences.setString(AppConstants.userNumber, number);
      await sharedPreferences.setString(AppConstants.userType, type);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getUserNumber() {
    return sharedPreferences.getString(AppConstants.userNumber) ?? "";
  }

  @override
  String getUserPassword() {
    // Deliberately always empty — passwords are never persisted. Kept for
    // interface compatibility with existing callers (e.g. login form prefill).
    // Also purges any plaintext password left over from installs predating this fix.
    if (sharedPreferences.containsKey(AppConstants.userPassword)) {
      sharedPreferences.remove(AppConstants.userPassword);
    }
    return "";
  }

  @override
  String getUserType() {
    return sharedPreferences.getString(AppConstants.type) ?? "";
  }

  @override
  bool isNotificationActive() {
    return sharedPreferences.getBool(AppConstants.notification) ?? true;
  }

  @override
  Future<void> setNotificationActive(bool isActive) async {
    if (isActive) {
      updateToken();
    } else {
      if (!GetPlatform.isWeb) {
        apiClient.postData(AppConstants.tokenUri, {
          "_method": "put",
          "token": getUserToken(),
          "fcm_token": '@',
        }, handleError: false);
        // Firebase isn't configured/initialized on desktop builds.
        if (GetPlatform.isMobile) {
          FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.topic);
          FirebaseMessaging.instance.unsubscribeFromTopic(
            sharedPreferences.getString(AppConstants.zoneTopic)!,
          );
        }
      }
    }
    sharedPreferences.setBool(AppConstants.notification, isActive);
  }

  @override
  Future<bool> clearUserNumberAndPassword() async {
    await sharedPreferences.remove(AppConstants.userType);
    await sharedPreferences.remove(AppConstants.userPassword);
    return await sharedPreferences.remove(AppConstants.userNumber);
  }

  @override
  Future<bool> toggleStoreClosedStatus() async {
    Response response = await apiClient.postData(
      AppConstants.updateVendorStatusUri,
      {},
    );
    return (response.statusCode == 200);
  }

  @override
  Future<bool> saveIsStoreRegistration(bool status) async {
    return await sharedPreferences.setBool(
      AppConstants.isStoreRegister,
      status,
    );
  }

  @override
  bool getIsStoreRegistration() {
    return sharedPreferences.getBool(AppConstants.isStoreRegister) ?? false;
  }

  @override
  Future<PackageModel?> getPackageList({int? moduleId}) async {
    PackageModel? packageModel;
    Response response = await apiClient.getData(
      '${AppConstants.restaurantPackagesUri}?module_id=$moduleId',
    );
    if (response.statusCode == 200) {
      packageModel = PackageModel.fromJson(response.body);
    }
    return packageModel;
  }

  @override
  String getModuleType() {
    return sharedPreferences.getString(AppConstants.moduleType) ?? "";
  }

  @override
  void setModuleType(String type) {
    sharedPreferences.setString(AppConstants.moduleType, type);
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  Future getList() {
    throw UnimplementedError();
  }
}
