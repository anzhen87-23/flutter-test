import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// 笔记内容渲染组件
/// 解析 Markdown 内容，将文本和图片分别渲染
class NoteContentWidget extends StatelessWidget {
  final String content;
  final int? maxLines;
  final double fontSize;
  final double imageMaxHeight;

  const NoteContentWidget({
    super.key,
    required this.content,
    this.maxLines,
    this.fontSize = 14,
    this.imageMaxHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    final segments = _parseContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        if (segment.isImage) {
          final imageUrl = _getFullImageUrl(segment.text);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                height: imageMaxHeight,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: imageMaxHeight,
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: imageMaxHeight,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          );
        } else {
          return Text(
            segment.text,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[600],
              height: 1.5,
            ),
          );
        }
      }).toList(),
    );
  }

  /// 将相对路径转换为完整的图片 URL
  String _getFullImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // 相对路径，拼接服务器地址
    return '${ApiService.serverUrl}$url';
  }

  /// 解析内容，提取文本和图片
  List<_ContentSegment> _parseContent(String content) {
    final segments = <_ContentSegment>[];
    final imageRegex = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');

    int start = 0;
    for (final match in imageRegex.allMatches(content)) {
      // 图片前的文本
      if (match.start > start) {
        final text = content.substring(start, match.start).trim();
        if (text.isNotEmpty) {
          segments.add(_ContentSegment(text: text, isImage: false));
        }
      }

      // 图片 URL
      segments.add(_ContentSegment(text: match.group(2)!, isImage: true));
      start = match.end;
    }

    // 最后的文本
    if (start < content.length) {
      final text = content.substring(start).trim();
      if (text.isNotEmpty) {
        segments.add(_ContentSegment(text: text, isImage: false));
      }
    }

    return segments;
  }
}

class _ContentSegment {
  final String text;
  final bool isImage;

  _ContentSegment({required this.text, required this.isImage});
}
