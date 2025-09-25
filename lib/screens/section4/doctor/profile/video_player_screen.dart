import 'package:flutter/material.dart' hide MaterialType;
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/material_link.dart';


class VideoPlayerScreen extends StatefulWidget {
  final MaterialLink materialLink;

  const VideoPlayerScreen({super.key, required this.materialLink});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoPlayerController;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.materialLink.type == MaterialType.video) {
        final videoId = widget.materialLink.videoId;
        if (videoId != null) {
          // For YouTube videos, we'll use WebView
          _webViewController =
              WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onProgress: (int progress) {
                      // Update loading bar
                    },
                    onPageStarted: (String url) {
                      setState(() {
                        _isLoading = true;
                      });
                    },
                    onPageFinished: (String url) {
                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),
                )
                ..loadRequest(
                  Uri.parse(
                    'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0',
                  ),
                );
        } else {
          // For direct video URLs
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(widget.materialLink.url),
          );
          await _videoPlayerController!.initialize();
          _videoPlayerController!.play();
        }
      }
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل الفيديو: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.materialLink.displayTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            onPressed: () => _openInBrowser(),
            tooltip: 'فتح في المتصفح',
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () => _toggleFullscreen(),
            tooltip: 'ملء الشاشة',
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
              'خطأ في تحميل الفيديو',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w600,
                color: Colors.red.shade300,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              _error!,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade400,
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
                _initializeVideo();
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
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الفيديو...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Center(
      child: AspectRatio(aspectRatio: 16 / 9, child: _buildVideoPlayer()),
    );
  }

  Widget _buildVideoPlayer() {
    if (widget.materialLink.type == MaterialType.video &&
        widget.materialLink.videoId != null) {
      // YouTube video
      return WebViewWidget(controller: _webViewController!);
    } else if (_videoPlayerController != null) {
      // Direct video URL
      return VideoPlayer(_videoPlayerController!);
    } else {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'لا يمكن تشغيل هذا الفيديو',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.text(context, size: TextSize.medium),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              ElevatedButton(
                onPressed: _openInBrowser,
                child: const Text('فتح في المتصفح'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _openInBrowser() async {
    final Uri? url = Uri.tryParse(widget.materialLink.url);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الرابط: ${widget.materialLink.url}'),
          ),
        );
      }
    }
  }

  void _toggleFullscreen() {
    // TODO: Implement fullscreen functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة ميزة ملء الشاشة قريباً'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
