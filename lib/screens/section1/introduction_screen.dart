import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/responsive.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:pivot/services/introduction_service.dart';
import 'package:pivot/widgets/no_internet_message.dart';

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
  String _errorMessage = '';
  bool _hasStartedVideo = false;
  bool _videoEnded = false;

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
      final videoUrl =
          'https://engseif.com/wp-content/uploads/2025/06/Pivot-intro.mp4';
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timed out after 30 seconds');
        },
      );
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

  void _nextPage() async {
    if (_currentPage < 2) {
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

  Widget _buildPageIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? Colors.teal
                    : Colors.teal.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: NoInternetMessage(
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
                    pageCount: 3,
                    onNext: _nextPage,
                    buttonText: 'التالي',
                  ),
                ],
              ),
              // Screen 2: Intro Video
              Column(
                children: [Expanded(child: Center(child: _buildVideoPage()))],
              ),
              // Screen 3: First Step
              Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/first_step.jpeg',
                      // fit: BoxFit.cover,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: _BottomCard(
                          heightFactor: 0.32,
                          title: 'أول خطوة',
                          description:
                              'ادخل علي البروفايل واعمل تسجيل مواد عشان المحتوى يظهرلك',
                          currentPage: _currentPage,
                          pageCount: 3,
                          onNext: _nextPage,
                          buttonText: 'ابدأ',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
        child: Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _hasStartedVideo = true;
                _videoController.play();
              });
            },
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
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'فشل في تحميل الفيديو',
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
                    _errorMessage = '';
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
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController.value.size.width,
              height: _videoController.value.size.height,
              child: VideoPlayer(_videoController),
            ),
          ),
        ),
        // Video controls overlay
        if (_videoController.value.isInitialized &&
            !_videoController.value.isPlaying &&
            !_videoEnded)
          Positioned(
            bottom: 100,
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
                        _videoController.play();
                      });
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_videoController.value.isInitialized &&
            _videoController.value.isPlaying)
          Positioned(
            bottom: 100,
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
                        _videoController.pause();
                      });
                    },
                    icon: const Icon(
                      Icons.pause,
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
                      _videoController.pause();
                      setState(() {});
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
        // Show Next button when video ends
        if (_videoEnded)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.space(context, size: Space.medium),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'التالي',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
              ),
            ),
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
  final bool compact;

  const _BottomCard({
    required this.heightFactor,
    this.title,
    this.description,
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    this.buttonText = 'التالي',
    this.compact = false,
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
          vertical:
              compact
                  ? Responsive.space(context, size: Space.small)
                  : Responsive.space(context, size: Space.medium),
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
            SizedBox(
              height:
                  compact ? 8 : Responsive.space(context, size: Space.medium),
            ),
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
                    vertical:
                        compact
                            ? Responsive.space(context, size: Space.small)
                            : Responsive.space(context, size: Space.medium),
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
