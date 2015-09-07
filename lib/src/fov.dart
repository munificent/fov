library fov.src.fov;

import 'package:piecemeal/piecemeal.dart';

import 'demo.dart';

/// Calculates the [Hero]'s field of view of the dungeon.
class Fov {
  final Demo _demo;

  Fov(this._demo);

  /// Updates the visible flags in [stage] given the [Hero]'s [pos].
  void refresh(Vec pos) {
    // Sweep through the octants.
    for (var octant = 0; octant < 8; octant++) {
      refreshOctant(pos, octant);
    }

    // The starting position is always visible.
    if (_demo.tiles[pos].isVisible = true);
  }

  List<Shadow> refreshOctant(Vec start, int octant, [int maxRows = 999]) {
    var line = new ShadowLine();
    var bounds = _demo.tiles.bounds;
    var fullShadow = false;

    // Sweep through the rows ('rows' may be vertical or horizontal based on
    // the incrementors). Start at row 1 to skip the center position.
    for (var row = 1; row < maxRows; row++) {
      // If we've gone out of bounds, bail.
      if (!bounds.contains(start + transformOctant(row, 0, octant))) break;

      for (var col = 0; col <= row; col++) {
        var pos = start + transformOctant(row, col, octant);

        // If we've traversed out of bounds, bail on this row.
        // note: this improves performance, but works on the assumption that
        // the starting tile of the FOV is in bounds.
        if (!bounds.contains(pos)) break;

        // If we know the entire row is in shadow, we don't need to be more
        // specific.
        if (fullShadow) {
          _demo.tiles[pos].isVisible = false;
        } else {
          var projection = _projectTile(row, col);

          // Set the visibility of this tile.
          var visible = !line.isInShadow(projection);
          _demo.tiles[pos].isVisible = visible;

          // Add any opaque tiles to the shadow map.
          if (visible && _demo.tiles[pos].isWall) {
            line.add(projection);
            fullShadow = line.isFullShadow;
          }
        }
      }
    }

    return line._shadows;
  }

  /// Creates a [Shadow] that corresponds to the projected silhouette of the
  /// given tile. This is used both to determine visibility (if any of the
  /// projection is visible, the tile is) and to add the tile to the shadow map.
  ///
  /// The maximal projection of a square is always from the two opposing
  /// corners. From the perspective of octant zero, we know the square is
  /// above and to the right of the viewpoint, so it will be the top left and
  /// bottom right corners.
  Shadow _projectTile(int row, int col) {
    // The top edge of row 0 is 2 wide.
    var topLeft = col / (row + 2);

    // The bottom edge of row 0 is 1 wide.
    var bottomRight = (col + 1) / (row + 1);

    return new Shadow(topLeft, bottomRight,
        new Vec(col, row + 2), new Vec(col + 1, row + 1));
  }
}

class ShadowLine {
  final List<Shadow> _shadows = [];

  bool isInShadow(Shadow projection) {
    // Check the shadow list.
    for (var shadow in _shadows) {
      if (shadow.contains(projection)) return true;
    }

    return false;
  }

  /// Add [shadow] to the list of non-overlapping shadows. May merge one or
  /// more shadows.
  void add(Shadow shadow) {
    // Figure out where to slot the new shadow in the sorted list.
    var index = 0;
    for (; index < _shadows.length; index++) {
      // Stop when we hit the insertion point.
      if (_shadows[index].start >= shadow.start) break;
    }

    // The new shadow is going here. See if it overlaps the previous or next.
    var overlappingPrevious;
    if (index > 0 && _shadows[index - 1].end > shadow.start) {
      overlappingPrevious = _shadows[index - 1];
    }

    var overlappingNext;
    if (index < _shadows.length && _shadows[index].start < shadow.end) {
      overlappingNext = _shadows[index];
    }

    // Insert and unify with overlapping shadows.
    if (overlappingNext != null) {
      if (overlappingPrevious != null) {
        // Overlaps both, so unify one and delete the other.
        overlappingPrevious.end = overlappingNext.end;
        overlappingPrevious.endPos = overlappingNext.endPos;
        _shadows.removeAt(index);
      } else {
        // Only overlaps the next shadow, so unify it with that.
        overlappingNext.start = shadow.start;
        overlappingNext.startPos = shadow.startPos;
      }
    } else {
      if (overlappingPrevious != null) {
        // Only overlaps the previous shadow, so unify it with that.
        overlappingPrevious.end = shadow.end;
        overlappingPrevious.endPos = shadow.endPos;
      } else {
        // Does not overlap anything, so insert.
        _shadows.insert(index, shadow);
      }
    }
  }

  bool get isFullShadow {
    return _shadows.length == 1 &&
        _shadows[0].start == 0 &&
        _shadows[0].end == 1;
  }
}

/// Represents the 1D projection of a 2D shadow onto a normalized line. In
/// other words, a range from 0.0 to 1.0.
class Shadow {
  num start;
  num end;

  Vec startPos;
  Vec endPos;

  Shadow(this.start, this.end, this.startPos, this.endPos);

  String toString() => '(${start}-${end})';

  /// Returns `true` if [other] is completely covered by this shadow.
  bool contains(Shadow other) {
    return start <= other.start && end >= other.end;
  }
}