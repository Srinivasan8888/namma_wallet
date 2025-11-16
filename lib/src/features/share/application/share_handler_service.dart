import 'dart:io';

import 'package:flutter/material.dart';
import 'package:namma_wallet/src/common/services/logger_interface.dart';
import 'package:namma_wallet/src/features/share/presentation/share_content_view.dart';

enum SharedContentType { text, image, pdf, unknown }

class SharedContent {
  SharedContent({
    required this.type,
    required this.data,
    this.filePath,
    this.mimeType,
  });

  final SharedContentType type;
  final String data;
  final String? filePath;
  final String? mimeType;
}

class ShareHandlerService {
  ShareHandlerService({required ILogger logger}) : _logger = logger;

  final ILogger _logger;

  /// Process shared file and determine its type
  Future<SharedContent> processSharedFile(String filePath) async {
    _logger.info('Processing shared file: $filePath');

    final fileObj = File(filePath);
    if (!fileObj.existsSync()) {
      throw Exception('File not found: $filePath');
    }

    final extension = filePath.toLowerCase().split('.').last;
    
    // Try to determine MIME type from extension
    String? mimeType;
    if (_isPdfFile(extension, '')) {
      mimeType = 'application/pdf';
    } else if (_isImageFile(extension, '')) {
      mimeType = 'image/*';
    } else if (_isTextFile(extension, '')) {
      mimeType = 'text/plain';
    }

    // Determine content type
    if (_isPdfFile(extension, mimeType ?? '')) {
      return SharedContent(
        type: SharedContentType.pdf,
        data: filePath,
        filePath: filePath,
        mimeType: mimeType,
      );
    } else if (_isImageFile(extension, mimeType ?? '')) {
      return SharedContent(
        type: SharedContentType.image,
        data: filePath,
        filePath: filePath,
        mimeType: mimeType,
      );
    } else if (_isTextFile(extension, mimeType ?? '')) {
      final content = await fileObj.readAsString();
      return SharedContent(
        type: SharedContentType.text,
        data: content,
        filePath: filePath,
        mimeType: mimeType,
      );
    }

    return SharedContent(
      type: SharedContentType.unknown,
      data: filePath,
      filePath: filePath,
      mimeType: mimeType,
    );
  }

  /// Process shared text content
  SharedContent processSharedText(String text) {
    _logger.info('Processing shared text: ${text.substring(0, 50)}...');
    return SharedContent(
      type: SharedContentType.text,
      data: text,
    );
  }

  /// Show share content modal and handle user selection
  Future<void> handleSharedContent({
    required BuildContext context,
    required SharedContent content,
    required Future<void> Function(
      ShareContentType type,
      SharedContent content,
    ) onContentProcessed,
  }) async {
    showShareContentModal(
      context,
      onShare: (type, title) async {
        _logger.info('User selected: $title (${type.name})');
        try {
          await onContentProcessed(type, content);
        } catch (e, stackTrace) {
          _logger.error('Error processing shared content', e, stackTrace);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error processing content: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  bool _isPdfFile(String extension, String mimeType) {
    return extension == 'pdf' || mimeType.contains('pdf');
  }

  bool _isImageFile(String extension, String mimeType) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(extension) || mimeType.contains('image');
  }

  bool _isTextFile(String extension, String mimeType) {
    const textExtensions = ['txt', 'sms', 'text'];
    return textExtensions.contains(extension) || mimeType.contains('text');
  }
}
