import 'dart:ui';

/// Records every grid cell crossed by each pointer segment, including fast drags.
class TouchGridCoverage {
  static const side = 10;
  static const cellCount = side * side;

  final Set<int> touched = {};

  int get count => touched.length;
  int get percent => (count * 100 / cellCount).round();

  void reset() => touched.clear();

  bool markSegment(Offset start, Offset end, Size size) {
    if (size.width <= 0 || size.height <= 0) return false;
    final cellWidth = size.width / side;
    final cellHeight = size.height / side;
    final from = Offset(
      start.dx.clamp(0.0, size.width - 0.000001),
      start.dy.clamp(0.0, size.height - 0.000001),
    );
    final to = Offset(
      end.dx.clamp(0.0, size.width - 0.000001),
      end.dy.clamp(0.0, size.height - 0.000001),
    );
    var col = (from.dx / cellWidth).floor();
    var row = (from.dy / cellHeight).floor();
    final endCol = (to.dx / cellWidth).floor();
    final endRow = (to.dy / cellHeight).floor();
    var changed = _add(col, row);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final stepX = dx.sign.toInt();
    final stepY = dy.sign.toInt();
    var nextX = stepX == 0
        ? double.infinity
        : (((stepX > 0 ? col + 1 : col) * cellWidth) - from.dx) / dx;
    var nextY = stepY == 0
        ? double.infinity
        : (((stepY > 0 ? row + 1 : row) * cellHeight) - from.dy) / dy;
    final deltaX = stepX == 0 ? double.infinity : cellWidth / dx.abs();
    final deltaY = stepY == 0 ? double.infinity : cellHeight / dy.abs();

    for (
      var steps = 0;
      (col != endCol || row != endRow) && steps < side * 4;
      steps++
    ) {
      if ((nextX - nextY).abs() < 0.0000001) {
        changed = _add(col + stepX, row) || changed;
        changed = _add(col, row + stepY) || changed;
        col += stepX;
        row += stepY;
        nextX += deltaX;
        nextY += deltaY;
      } else if (nextX < nextY) {
        col += stepX;
        nextX += deltaX;
      } else {
        row += stepY;
        nextY += deltaY;
      }
      changed = _add(col, row) || changed;
    }
    return changed;
  }

  bool _add(int col, int row) {
    if (col < 0 || row < 0 || col >= side || row >= side) return false;
    return touched.add(row * side + col);
  }
}
