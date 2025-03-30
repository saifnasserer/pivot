import 'package:flutter/material.dart';
import 'package:pivot/screens/models/card_model.dart';
// TODO: Import your CardModel definition here
// import 'package:pivot/screens/models/card_model.dart'; // Example import

class SCReport extends StatefulWidget {
  const SCReport({super.key});

  @override
  State<SCReport> createState() => _SCReportState();
}

class _SCReportState extends State<SCReport> {
  // Controller for the PageView
  late PageController _pageController;
  // Index of the currently visible card
  int _currentCardIndex = 0;

  // TODO: Replace with your actual data source for the cards
  final List<Color> _cardColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the PageController
    _pageController = PageController(initialPage: _currentCardIndex);
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // You might want to wrap this PageView in a Container or SizedBox
    // to constrain its size if it's part of a larger layout.
    // For now, let's assume it takes available space or has constraints
    // provided by its parent widget in landing.dart.
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical, // Vertical scrolling as in your snippet
      itemCount: _cardColors.length, // Use the length of your data list
      itemBuilder: (context, index) {
        // TODO: Replace CardModel with your actual card widget
        // Make sure CardModel accepts the data (e.g., color)
        return CardModel(color: _cardColors[index]); // Your original line
      },
      onPageChanged: (index) {
        // Update the state when the page changes
        setState(() {
          _currentCardIndex = index;
        });
      },
    );
  }
}
