// Shows a course's Canvas image, or a tile in the course's Canvas colour with its code when it has none.
import 'package:flutter/material.dart';

import '../models/course.dart';

const List<Color> _fallbackColors = [
  Color(0xFF3F6C8F),
  Color(0xFF5B7F5E),
  Color(0xFF8C5A6B),
  Color(0xFF7A6A9E),
  Color(0xFFA9703F),
  Color(0xFF4F8A8B),
  Color(0xFF9A5B4A),
  Color(0xFF5D6B8A),
];

// Uses the colour the student has for the course in Canvas. Courses without one get a colour
// picked from their id, so the same course always looks the same.
Color courseColor(Course course) {
  final hex = course.colorHex.replaceFirst('#', '');
  final parsed = hex.length == 6 ? int.tryParse(hex, radix: 16) : null;
  if (parsed != null) return Color(0xFF000000 | parsed);

  final seed = course.id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return _fallbackColors[seed % _fallbackColors.length];
}

class CourseImage extends StatelessWidget {
  final Course course;
  final double? width;
  final double height;
  final double radius;

  const CourseImage({
    super.key,
    required this.course,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _buildPlaceholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: course.imageUrl.isEmpty
            ? placeholder
            : Image.network(
                course.imageUrl,
                fit: BoxFit.cover,
                // Canvas serves course images from its file storage without CORS headers, so the
                // web build falls back to a plain <img> element when it cannot read the pixels.
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return placeholder;
                },
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final color = courseColor(course);
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black87;
    final label = course.courseCode.trim().split(RegExp(r'[\s_\-]+')).first;

    return Container(
      color: color,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: onColor,
            fontSize: (height * 0.24).clamp(11.0, 28.0),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
