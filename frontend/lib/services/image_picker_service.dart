import 'image_picker_model.dart';
import 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart'
    as picker_impl;

export 'image_picker_model.dart';

class ImagePickerService {
  static Future<PickedProduceImage?> pickImage({
    bool fromCamera = false,
  }) async {
    return picker_impl.pickDeviceImage(fromCamera: fromCamera);
  }
}
