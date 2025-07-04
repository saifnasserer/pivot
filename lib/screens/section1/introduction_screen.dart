import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/services/introduction_service.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});
  static const String id = 'introduction_screen';

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoLoading = true;
  bool _hasVideoError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      setState(() {
        _isVideoLoading = true;
        _hasVideoError = false;
        _errorMessage = '';
      });

      // Use the hosted video URL directly with HTTPS
      final videoUrl =
          'https://engseif.com/wp-content/uploads/2025/06/Pivot-intro.mp4';

      //debugprint('Initializing video with URL: $videoUrl');

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      //debugprint('Video controller created, initializing...');
      await _videoController.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timed out after 30 seconds');
        },
      );
      //debugprint('Video initialized successfully');

      // Add listener for video completion
      _videoController.addListener(() {
        if (_videoController.value.position >=
            _videoController.value.duration) {
          // Video finished, seek to beginning for next play
          _videoController.seekTo(Duration.zero);
        }
      });

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoLoading = false;
        });

        // Only start playing if we're already on the video page
        if (_currentPage == 1) {
          _videoController.play();
          //debugprint('Video started playing');
        }
      }
    } catch (e) {
      //debugprint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _isVideoLoading = false;
          _errorMessage = 'Error loading video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntroduction();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Play video only when on video page (index 1)
    if (_isVideoInitialized && !_hasVideoError) {
      if (index == 1) {
        _videoController.play();
      } else {
        _videoController.pause();
      }
    }
  }

  Future<void> _finishIntroduction() async {
    await IntroductionService.markIntroductionAsSeen();

    if (mounted) {
      Navigator.pushReplacementNamed(context, FirstLandingScreen.id);
    }
  }

  Future<void> _openVideoInBrowser() async {
    final videoUrl =
        'https://engseif.com/wp-content/uploads/2025/06/Pivot-intro.mp4';
    final uri = Uri.parse(videoUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح الفيديو في المتصفح'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff161616),
        body: Stack(
          children: [
            // Background decoration
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xff161616),
                image: DecorationImage(
                  image: AssetImage('assets/images/Group 113.png'),
                  opacity: 0.15,
                  scale: 1.2,
                ),
              ),
            ),

            // Page content
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                // First page - What is Pivot?
                _buildFirstPage(),

                // Second page - Video
                _buildVideoPage(),
              ],
            ),

            // Navigation buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.large),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _previousPage,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              'السابق',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // Page indicator
                    Row(
                      children: List.generate(2, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.tiny,
                            ),
                          ),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    // Next/Finish button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.large,
                          ),
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage == 1 ? 'ابدأ' : 'التالي',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                            size: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstPage() {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App logo/icon placeholder

          // Title
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'يعني اية Pivot ؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    Responsive.text(context, size: TextSize.heading) * 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Description
          Text(
            'يعني نقطة ارتكاز أو مركز التوجيه. سميت التطبيق كده لأنه بيكون المركز اللي الطلاب بيرجعوله لتنظيم محتواهم ومتابعة كل اللي يخص دراستهم في مكان واحد.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: Responsive.text(context, size: TextSize.medium),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      child: Stack(
        children: [
          // Full screen video
          _hasVideoError || !_isVideoInitialized
              ? Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'خطأ في عرض الفيديو',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
              : _isVideoInitialized
              ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              )
              : Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),

          // Loading overlay
          if (_isVideoLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل الفيديو...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (_hasVideoError)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'فشل في تحميل الفيديو',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isVideoLoading = true;
                              _hasVideoError = false;
                            });
                            _initializeVideo();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _openVideoInBrowser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text(
                            'فتح في المتصفح',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Video controls overlay - positioned to avoid navigation
          if (!_isVideoLoading && !_hasVideoError && _isVideoInitialized)
            Positioned(
              bottom: 100, // Move up to avoid navigation buttons
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _videoController.value.isPlaying
                              ? _videoController.pause()
                              : _videoController.play();
                        });
                      },
                      icon: Icon(
                        _videoController.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _videoController.seekTo(Duration.zero);
                        _videoController.play();
                      },
                      icon: const Icon(
                        Icons.replay,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
