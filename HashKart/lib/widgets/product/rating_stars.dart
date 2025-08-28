import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool allowHalfRating;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starRating = index + 1;
        
        if (rating >= starRating) {
          // Full star
          return Icon(
            Icons.star,
            size: size,
            color: activeColor,
          );
        } else if (allowHalfRating && rating >= starRating - 0.5) {
          // Half star
          return Icon(
            Icons.star_half,
            size: size,
            color: activeColor,
          );
        } else {
          // Empty star
          return Icon(
            Icons.star_border,
            size: size,
            color: inactiveColor,
          );
        }
      }),
    );
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final double initialRating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Function(double) onRatingChanged;

  const InteractiveRatingStars({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 24,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    required this.onRatingChanged,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starRating = index + 1;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starRating.toDouble();
            });
            widget.onRatingChanged(_currentRating);
          },
          child: Icon(
            _currentRating >= starRating ? Icons.star : Icons.star_border,
            size: widget.size,
            color: _currentRating >= starRating 
                ? widget.activeColor 
                : widget.inactiveColor,
          ),
        );
      }),
    );
  }
}

class RatingBreakdown extends StatelessWidget {
  final Map<int, int> ratingCounts;
  final int totalReviews;
  final double size;

  const RatingBreakdown({
    super.key,
    required this.ratingCounts,
    required this.totalReviews,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final count = ratingCounts[rating] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$rating',
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: size,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: size,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}