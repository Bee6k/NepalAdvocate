import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

class SlideToAnswerWidget extends StatefulWidget {
  final VoidCallback onAnswer;
  final VoidCallback onReject;
  final String answerText;
  final String rejectText;

  const SlideToAnswerWidget({
    super.key,
    required this.onAnswer,
    required this.onReject,
    this.answerText = 'Slide to Answer',
    this.rejectText = 'Decline',
  });

  @override
  State<SlideToAnswerWidget> createState() => _SlideToAnswerWidgetState();
}

class _SlideToAnswerWidgetState extends State<SlideToAnswerWidget>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  double _maxDragDistance = 0.0;
  bool _isAnswering = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnswering) return;
    
    setState(() {
      _dragPosition += details.primaryDelta!;
      _dragPosition = _dragPosition.clamp(0.0, _maxDragDistance);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnswering) return;
    
    // If dragged more than 70% of the way, answer the call
    if (_dragPosition >= _maxDragDistance * 0.7) {
      setState(() {
        _isAnswering = true;
      });
      _animationController.stop();
      widget.onAnswer();
    } else {
      // Spring back to start
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDragDistance = constraints.maxWidth - 120;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reject button
            GestureDetector(
              onTap: widget.onReject,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 20),
            
            // Slide to answer widget
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Container(
                width: constraints.maxWidth - 120,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.white24,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Answer text
                    Center(
                      child: AnimatedOpacity(
                        opacity: _dragPosition < _maxDragDistance * 0.3 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          widget.answerText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    // Sliding button
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _dragPosition < _maxDragDistance * 0.1 
                              ? _pulseAnimation.value 
                              : 1.0,
                          child: Positioned(
                            left: _dragPosition,
                            top: 0,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.successColor.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Answer text when dragged
                    if (_dragPosition > _maxDragDistance * 0.3)
                      Center(
                        child: Text(
                          'Answer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: AppTheme.successColor.withOpacity(0.8),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

