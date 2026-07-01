import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class PhotoUtils {
  static Future<String?> toBase64DataUri(XFile? image) async {
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    final base64Str = base64Encode(bytes);
    final ext = image.name.split('.').last.toLowerCase();
    return 'data:image/$ext;base64,$base64Str';
  }

  static Future<XFile?> pickFromCameraOrGallery({
    required ImagePicker picker,
    required Future<ImageSource?> Function() chooseSource,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.front,
  }) async {
    final source = await chooseSource();
    if (source == null) return null;

    return picker.pickImage(
      source: source,
      preferredCameraDevice: preferredCameraDevice,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
}
