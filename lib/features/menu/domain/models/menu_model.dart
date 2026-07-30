import 'package:flutter/material.dart';

class MenuModel {
  String icon;
  IconData? iconData;
  String title;
  String route;
  bool isBlocked;
  bool isNotSubscribe;
  bool isLanguage;
  bool isWhatsApp;
  bool isPaymentMethods;
  Color? iconColor;

  MenuModel({
    required this.icon,
    this.iconData,
    required this.title,
    required this.route,
    this.isBlocked = false,
    this.isNotSubscribe = false,
    this.iconColor,
    this.isLanguage = false,
    this.isWhatsApp = false,
    this.isPaymentMethods = false,
  });
}