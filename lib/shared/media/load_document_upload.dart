import 'package:file_picker/file_picker.dart';

import '../../core/api_client.dart';
import '../../models/load.dart';

const maxLoadDocuments = 5;

const loadDocumentExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

/// Picks a PDF/image and uploads it with `kind=document`.
Future<LoadDocument?> pickAndUploadLoadDocument(ApiClient api) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: loadDocumentExtensions,
    withData: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final path = file.path;
  if (path == null || path.isEmpty) return null;
  final url = await api.uploadFile(path, kind: 'document');
  final name = file.name.trim().isEmpty ? 'document' : file.name.trim();
  return LoadDocument(url: url, fileName: name);
}
