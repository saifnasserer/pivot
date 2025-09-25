import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/responsive.dart';
import 'package:video_player/video_player.dart';
import 'package:pivot/services/introduction_service.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

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
  bool _hasStartedVideo = false;
  bool _videoEnded = false;
  bool _showVideoControls = true;

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
      });

      // Use local asset video instead of network video
      _videoController = VideoPlayerController.asset('assets/Pivot-intro.mp4');

      await _videoController.initialize();

      _videoController.addListener(() {
        final isEnded =
            _videoController.value.isInitialized &&
            !_videoController.value.isPlaying &&
            _videoController.value.position >=
                _videoController.value.duration &&
            _videoController.value.duration != Duration.zero;
        if (isEnded != _videoEnded) {
          setState(() {
            _videoEnded = isEnded;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _isVideoLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController.dispose();
    // Restore status bar when leaving introduction screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    } else {
      // Mark onboarding as seen
      await IntroductionService.markIntroductionAsSeen();
      // Go to main app
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/first-landing',
          (route) => false,
        );
      }
    }
  }

  void _toggleVideoPlayPause() {
    if (_videoController.value.isInitialized) {
      setState(() {
        if (_videoController.value.isPlaying) {
          _videoController.pause();
        } else {
          _videoController.play();
        }
      });
    }
  }

  void _toggleVideoControls() {
    setState(() {
      _showVideoControls = !_showVideoControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hide status bar for introduction screens
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            // Screen 1: App Introduction
            Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Image.asset(
                        'assets/icon.png',
                        width:
                            Responsive.space(context, size: Space.large) * 11,
                        height:
                            Responsive.space(context, size: Space.large) * 11,
                      ),
                    ),
                  ),
                ),
                _BottomCard(
                  heightFactor: 0.4,
                  title: 'يعني إيه Pivot؟',
                  description:
                      'Pivot يعني "نقطة التغيير" أو "التحوّل".\nوإحنا هنا علشان نكون النقطة دي في طريقتك لمتابعة الدراسة.',
                  currentPage: _currentPage,
                  pageCount: 2,
                  onNext: _nextPage,
                  buttonText: 'التالي',
                ),
              ],
            ),
            // Screen 2: Intro Video - Full Screen
            _buildVideoPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPage() {
    if (!_hasStartedVideo) {
      // Show black background with big play button
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _hasStartedVideo = true;
              _videoController.play();
            });
          },
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(32),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 64),
            ),
          ),
        ),
      );
    }

    if (_hasVideoError || !_isVideoInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 64),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'خطأ في عرض الفيديو',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Text(
                'فشل في تحميل الفيديو',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: Responsive.text(context, size: TextSize.small),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.space(context, size: Space.large)),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasVideoError = false;
                    _isVideoLoading = true;
                  });
                  _initializeVideo();
                },
                icon: Icon(Icons.refresh, color: Colors.black),
                label: Text(
                  'حاول مرة أخرى',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isVideoLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Full screen video player
        SizedBox.expand(
          child: GestureDetector(
            onTap: _toggleVideoPlayPause,
            onDoubleTap: _toggleVideoControls,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
        ),

        // Video controls overlay - only show when controls are visible
        if (_showVideoControls && _videoController.value.isInitialized)
          Stack(
            children: [
              // Top controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.ease,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      Text(
                        'فيديو تعريفي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 40), // Balance the layout
                    ],
                  ),
                ),
              ),

              // Center play/pause button
              if (!_videoController.value.isPlaying && !_videoEnded)
                Center(
                  child: GestureDetector(
                    onTap: _toggleVideoPlayPause,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(24),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Play/Pause button
                      GestureDetector(
                        onTap: _toggleVideoPlayPause,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            _videoController.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      // Replay button
                      GestureDetector(
                        onTap: () {
                          _videoController.seekTo(Duration.zero);
                          _videoController.play();
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.replay,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      // Start button (always visible)
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Text(
                            'ابدأ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _BottomCard extends StatelessWidget {
  final double heightFactor;
  final String? title;
  final String? description;
  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;
  final String buttonText;
  const _BottomCard({
    required this.heightFactor,
    this.title,
    this.description,
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    this.buttonText = 'التالي',
  });

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * heightFactor;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.large),
          vertical: Responsive.space(context, size: Space.medium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontFamily: 'NotoSansArabic',
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
            ],
            if (description != null) ...[
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontFamily: 'NotoSansArabic',
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
            ],
            _buildPageIndicator(context),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                currentPage == index
                    ? Colors.teal
                    : Colors.teal.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
