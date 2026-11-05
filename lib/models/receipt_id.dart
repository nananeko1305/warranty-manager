final RegExp _receiptPath = RegExp(r'/image/upload/(?:v\d+/)?(.+)\.[^./]+$');

/// The Cloudinary id of a photo, from its link, or empty when there is none.
///
/// The same rule is in `firestore.rules`, which refuses a warranty where the id
/// and the link disagree. The push worker relies on that when it deletes photos
/// no warranty refers to.
String receiptIdOf(String url) => _receiptPath.firstMatch(url)?.group(1) ?? '';
