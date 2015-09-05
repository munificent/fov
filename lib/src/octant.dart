library fov.src.octant;

import 'package:piecemeal/piecemeal.dart';

import 'demo.dart';

class Octant extends Demo {
  static final center = new Vec(15, 9);

  final bool _allOctants;
  Iterator<Vec> _steps;
  int _octant = 0;

  Octant(String id, {bool allOctants})
      : _allOctants = allOctants,
        super(id, 31, 19) {
    render();
  }

  void render() {
    for (var pos in new Rect(6, 0, 19, 19)) {
      if (pos.x >= 6 || pos.x <= 24) {
        drawTile(pos, 6);
      }
    }

    drawTile(center, Tile.hero);
  }

  bool onTick() {
    if (_steps == null) {
      render();
      _octant = 0;
      _steps = walkOctant(center, _octant).iterator;
      return true;
    }

    if (!_steps.moveNext()) {
      if (_allOctants && _octant < 7) {
        _octant++;
        _steps = walkOctant(center, _octant).iterator;
        return true;
      }

      _steps = null;
      return false;
    }

    drawTile(_steps.current, 7 + _octant);
    return true;
  }
}

