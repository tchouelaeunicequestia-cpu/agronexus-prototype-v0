// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_picker_model.dart';

bool _isMobileBrowser() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod') ||
      ua.contains('android') ||
      ua.contains('mobile');
}

Future<PickedProduceImage?> pickDeviceImage({bool fromCamera = false}) {
  final completer = Completer<PickedProduceImage?>();

  // Remove any previously orphaned file inputs
  final existing = html.document.querySelectorAll('#agronexus-file-picker');
  for (var el in existing) {
    el.remove();
  }

  final input = html.FileUploadInputElement()
    ..id = 'agronexus-file-picker'
    ..accept = 'image/*';
  input.style.display = 'none';

  // Only use capture="environment" on mobile devices (Android / iOS).
  // On desktop browsers (Windows / Mac / Linux), setting capture causes
  // desktop Chrome to silently drop the click event and open nothing.
  if (fromCamera && _isMobileBrowser()) {
    input.setAttribute('capture', 'environment');
  }

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoadEnd.listen((_) {
      final dataUrl = reader.result as String?;
      if (dataUrl != null) {
        final byteReader = html.FileReader();
        byteReader.readAsArrayBuffer(file);
        byteReader.onLoadEnd.listen((_) {
          input.remove();
          final rawResult = byteReader.result;
          if (rawResult != null && rawResult is ByteBuffer) {
            if (!completer.isCompleted) {
              completer.complete(
                PickedProduceImage(
                  bytes: rawResult.asUint8List(),
                  dataUrl: dataUrl,
                  name: file.name,
                ),
              );
            }
          } else if (rawResult != null && rawResult is List<int>) {
            if (!completer.isCompleted) {
              completer.complete(
                PickedProduceImage(
                  bytes: Uint8List.fromList(rawResult),
                  dataUrl: dataUrl,
                  name: file.name,
                ),
              );
            }
          } else {
            if (!completer.isCompleted) completer.complete(null);
          }
        });
      } else {
        input.remove();
        if (!completer.isCompleted) completer.complete(null);
      }
    });
  });

  html.document.body?.children.add(input);

  // Some browsers do not dispatch `cancel` for a dismissed file dialog.
  // Wait until the window actually loses and regains focus before treating
  // that interaction as a cancellation.
  var dialogOpened = false;
  html.window.onBlur.first.then((_) => dialogOpened = true);
  StreamSubscription<html.Event>? focusSub;
  focusSub = html.window.onFocus.listen((_) {
    if (!dialogOpened) return;
    focusSub?.cancel();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!completer.isCompleted) {
        input.remove();
        completer.complete(null);
      }
    });
  });

  input.click();

  return completer.future;
}
