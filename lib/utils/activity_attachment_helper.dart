import 'dart:convert';
import 'dart:typed_data';

class ActivityAttachment {
  final String name;
  final String base64;
  final int bytes;

  const ActivityAttachment({
    required this.name,
    required this.base64,
    required this.bytes,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'base64': base64,
        'bytes': bytes,
      };
}

class ActivityAttachmentHelper {
  static const int maxBytes = 2 * 1024 * 1024;

  static String encode(Uint8List bytes) => base64Encode(bytes);

  static bool isAllowed(Uint8List bytes) => bytes.lengthInBytes <= maxBytes;
}
