import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/features/media/providers/media_provider.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final MaterialLink materialLink;

  const PdfViewerScreen({super.key, required this.materialLink});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.materialLink.displayTitle,
          style: TextStyle(
            color: Colors.black,
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.black),
            onPressed: () => _openInBrowser(),
            tooltip: 'فتح في المتصفح',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              'خطأ في تحميل PDF',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              _error!,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
              },
              child: const Text('إعادة المحاولة'),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            TextButton(
              onPressed: _openInBrowser,
              child: const Text('فتح في المتصفح'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل PDF...'),
          ],
        ),
      );
    }

    return SfPdfViewer.network(
      widget.materialLink.url,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _isLoading = false;
        });
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _isLoading = false;
          _error = 'فشل في تحميل PDF: ${details.error}';
        });
      },
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }

  Future<void> _openInBrowser() async {
    final success = await ref
        .read(mediaProvider.notifier)
        .openPdfInBrowser(widget.materialLink.url);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الرابط: ${widget.materialLink.url}')),
      );
    }
  }
}
