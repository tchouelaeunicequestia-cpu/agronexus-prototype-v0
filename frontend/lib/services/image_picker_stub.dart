import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'image_picker_model.dart';

Future<PickedProduceImage?> pickDeviceImage({bool fromCamera = false}) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final mimeType = _mimeTypeFor(file.name);
  final dataUrl =
      'data:$mimeType;base64,${base64Encode(Uint8List.fromList(bytes))}';

  return PickedProduceImage(
    bytes: Uint8List.fromList(bytes),
    dataUrl: dataUrl,
    name: file.name,
  );
}

String _mimeTypeFor(String name) {
  final extension = name.split('.').last.toLowerCase();
  switch (extension) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'heic':
    case 'heif':
      return 'image/heic';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}
