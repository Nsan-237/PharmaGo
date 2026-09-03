import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

// ─────────────────────────────────────────────────────────────────────────────
// PharmaGo Platform Adaptive Utilities
//
// iOS-specific adaptive code is written correctly here.
// IMPORTANT: iOS behavior has NOT been live-tested (requires macOS/Xcode).
//            Android is the verified demo platform.
//
// iOS Info.plist entries required (for App Store / device):
//   NSLocationWhenInUseUsageDescription → for geolocator
//   NSCameraUsageDescription            → for image_picker (camera)
//   NSPhotoLibraryUsageDescription      → for image_picker (gallery)
// ─────────────────────────────────────────────────────────────────────────────

class PlatformUtils {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Returns the platform-appropriate back icon.
  /// iOS: chevron_left (Cupertino style)
  /// Android: arrow_back_ios_new_rounded (Material style)
  static IconData get backIcon =>
      isIOS ? CupertinoIcons.chevron_left : Icons.arrow_back_ios_new_rounded;

  /// Platform-appropriate action icon for "more options".
  static IconData get moreIcon =>
      isIOS ? CupertinoIcons.ellipsis : Icons.more_vert_rounded;

  /// Platform-appropriate share icon.
  static IconData get shareIcon =>
      isIOS ? CupertinoIcons.share : Icons.share_rounded;

  /// Shows a platform-adaptive confirmation dialog.
  /// On iOS: CupertinoAlertDialog
  /// On Android: Material AlertDialog
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: false,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmLabel,
                style: isDestructive ? const TextStyle(color: Colors.red) : null,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Shows a platform-adaptive bottom action sheet.
  /// On iOS: CupertinoActionSheet
  /// On Android: Material ModalBottomSheet
  static Future<void> showActionSheet(
    BuildContext context, {
    required String title,
    required List<SheetAction> actions,
    String cancelLabel = 'Cancel',
  }) {
    if (isIOS) {
      return showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text(title),
          actions: actions.map((a) {
            return CupertinoActionSheetAction(
              isDestructiveAction: a.isDestructive,
              onPressed: () {
                Navigator.of(context).pop();
                a.onTap();
              },
              child: Text(a.label),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelLabel),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              ...actions.map((a) => ListTile(
                    title: Text(
                      a.label,
                      style: TextStyle(
                        color: a.isDestructive ? Colors.red : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      a.onTap();
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
  }
}

class SheetAction {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const SheetAction({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
