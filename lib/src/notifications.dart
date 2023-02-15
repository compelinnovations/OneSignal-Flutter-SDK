
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/src/defines.dart';
import 'package:onesignal_flutter/src/notification.dart';
import 'package:onesignal_flutter/src/permission.dart';



typedef void OpenedNotificationHandler(OSNotificationOpenedResult openedResult);
typedef void NotificationWillShowInForegroundHandler(OSNotificationReceivedEvent event);


class OneSignalNotifications {

  // event handlers
  OpenedNotificationHandler? _onOpenedNotification;
  NotificationWillShowInForegroundHandler? _onNotificationWillShowInForegroundHandler;

  // private channels used to bridge to ObjC/Java
  MethodChannel _channel = const MethodChannel('OneSignal#notifications');

  List<OneSignalPermissionObserver> _observers = <OneSignalPermissionObserver>[];
  // constructor method
  OneSignalNotifications() {
    this._channel.setMethodCallHandler(_handleMethod);
  }

  /// Whether this app has push notification permission.
  Future<bool> permission() async {
    return await _channel
        .invokeMethod("OneSignal#permission");
  }

  /// Whether attempting to request notification permission will show a prompt. 
  /// Returns true if the device has not been prompted for push notification permission already.
  Future<bool> canRequest() async {
    return await _channel
        .invokeMethod("OneSignal#canRequest");
  }

  /// Removes all OneSignal notifications.
  Future<void> clearAll() async {
    return await _channel
        .invokeMethod("OneSignal#clearAll");
  }

  /// Prompt the user for permission to receive push notifications. This will display the native 
  /// system prompt to request push notification permission.
  Future<bool> requestPermission(bool fallbackToSettings) async {
     return await _channel.invokeMethod("OneSignal#requestPermission", {'fallbackToSettings' : fallbackToSettings});
  }

  /// Instead of having to prompt the user for permission to send them push notifications, 
  /// your app can request provisional authorization.
  Future<bool> registerForProvisionalAuthorization(bool fallbackToSettings) async {
     return await _channel.invokeMethod("OneSignal#registerForProvisionalAuthorization");
  }

  /// The OSPermissionObserver.onOSPermissionChanged method will be fired on the passed-in object 
  /// when a notification permission setting changes. This happens when the user enables or disables 
  /// notifications for your app from the system settings outside of your app.
  void addPermssionObserver(OneSignalPermissionObserver observer) {
    _observers.add(observer);
  }

  // Remove a push subscription observer that has been previously added.
  void removePermissionObserver(OneSignalPermissionObserver observer) {
    _observers.remove(observer);
  }
  

  Future<Null> _handleMethod(MethodCall call) async {
    if (call.method == 'OneSignal#handleOpenedNotification' &&
        this._onOpenedNotification != null) {
      this._onOpenedNotification!(
          OSNotificationOpenedResult(call.arguments.cast<String, dynamic>()));
    } else if (call.method == 'OneSignal#handleNotificationWillShowInForeground' &&
        this._onNotificationWillShowInForegroundHandler != null) {
      this._onNotificationWillShowInForegroundHandler!(
          OSNotificationReceivedEvent(call.arguments.cast<String, dynamic>()));
    } else if (call.method == 'OneSignal#OSPermissionChanged') {
      this.onOSPermissionChangedHandler(OSPermissionState(call.arguments.cast<String, dynamic>()));
    } 
      return null;
  }

  Future<void> onOSPermissionChangedHandler(OSPermissionState state) async {
    print("onOSPermissionChanged update in flutter");
    for (var observer in _observers) {
       print("onOSPermissionChanged fired");
      observer.onOSPermissionChanged(state);
    }
  }

  /// The notification foreground handler is called whenever a notification arrives
  /// and the application is in foreground
  void setNotificationWillShowInForegroundHandler(NotificationWillShowInForegroundHandler handler) {
    _onNotificationWillShowInForegroundHandler = handler;
    _channel.invokeMethod("OneSignal#initNotificationWillShowInForegroundHandlerParams");
  } 

   /// The notification foreground handler is called whenever a notification arrives
  /// and the application is in foreground
  void completeNotification(String notificationId, bool shouldDisplay) {
    _channel.invokeMethod("OneSignal#completeNotification",
        {'notificationId': notificationId, 'shouldDisplay': shouldDisplay});
  }


  /// The notification opened handler is called whenever the user opens a
  /// OneSignal push notification, or taps an action button on a notification.
  void setNotificationOpenedHandler(OpenedNotificationHandler handler) {
    _onOpenedNotification = handler;
    _channel.invokeMethod("OneSignal#initNotificationOpenedHandlerParams");
  }
}
class OneSignalPermissionObserver {
  void onOSPermissionChanged(OSPermissionState state) {
  }
}
