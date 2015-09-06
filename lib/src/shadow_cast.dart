library fov.src.shadow_cast;

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'demo.dart';
import 'fov.dart';
import 'los.dart';

enum Dragging {
  nothing,
  wall,
  floor,
  line
}

class ShadowCast extends Demo {
  static final hero = new Vec(7, 17);

  int _line = 0;

  Dragging _dragging = Dragging.nothing;
  Vec _dragFrom;

  ShadowCast(String id) : super(id, 31, 19) {
    tiles.get(7, 13).isWall = true;
    tiles.get(11, 11).isWall = true;
    tiles.get(10, 11).isWall = true;
    tiles.get(9, 8).isWall = true;
    tiles.get(9, 7).isWall = true;
    tiles.get(10, 3).isWall = true;
    tiles.get(11, 3).isWall = true;
    tiles.get(12, 3).isWall = true;
    tiles.get(12, 4).isWall = true;
    tiles.get(12, 5).isWall = true;
    tiles.get(12, 6).isWall = true;

    render();
  }

  void onMouseDown(Vec pos) {
    if (pos.x < 7) {
      _dragging = Dragging.line;
      return;
    }

    var tile = tiles[pos];
    tile.isWall = !tile.isWall;
    _dragging = tile.isWall ? Dragging.wall : Dragging.floor;
    _dragFrom = pos;
    render();
  }

  void onMouseMove(Vec pos) {
    if (_dragging == Dragging.nothing) return;

    switch (_dragging) {
      case Dragging.nothing:
        break;

      case Dragging.wall:
      case Dragging.floor:
        for (var step in new Los(_dragFrom, pos)) {
          tiles[step].isWall = _dragging == Dragging.wall;

          if (step == pos) break;
        }

        _dragFrom = pos;
        render();
        break;

      case Dragging.line:
        var line = hero.y - pos.y;
        line = math.max(0, line);
        line = math.min(17, line);
        if (_line != line) {
          _line = line;
          render();
        }
        break;

      default:
        break;
    }
  }

  void onMouseUp(Vec pos) {
    _dragging = Dragging.nothing;
  }

  void render() {
    clear();

    // Don't cast shadows past the line.
    for (var pos in walkOctant(hero, 0, 18)) {
      tiles[pos].isVisible = true;
    }

    var shadows = new Fov(this).refreshOctant(hero, 0, _line + 1);

    drawTile(hero);
    drawTile(hero, Tile.hero);

    for (var pos in walkOctant(hero, 0, 18)) {
      drawTile(pos);
    }

    var lineY = (hero.y - _line) * 10;
    var lineLeft = 7 * 10;
    var lineRight = (9 + _line) * 10;

    strokeStyle = "rgba(255, 255, 255, 0.2)";
    drawLine(new Vec(lineLeft, lineY), new Vec(lineRight, lineY));

    var lineWidth = lineRight - lineLeft;
    for (var shadow in shadows) {
      var left = shadow.start * lineWidth + lineLeft;
      var right = shadow.end * lineWidth + lineLeft;

      strokeStyle = "rgba(255, 255, 255, 1.0)";
      drawLine(new Vec(left, lineY), new Vec(right, lineY));

      // Show the lines from the point where the shadow starts.
      strokeStyle = "rgba(255, 255, 255, 0.3)";
      drawLine(endpointToPixel(shadow.startPos), new Vec(left, lineY));
      drawLine(endpointToPixel(shadow.endPos), new Vec(right, lineY));
    }

    drawSprite(new Vec(60, lineY - 5), Tile.slider);

    strokeStyle = "rgba(0, 0, 0, 1.0)";
    lineY = 175;
    lineLeft = 100;
    lineRight = 250;
    lineWidth = lineRight - lineLeft;
    for (var shadow in shadows) {
      var left = shadow.start * lineWidth + lineLeft;
      var right = shadow.end * lineWidth + lineLeft;

      // Show the lines from the point where the shadow starts.
      drawLine(new Vec(left, lineY), new Vec(right, lineY));
      drawLine(new Vec(left, lineY - 2), new Vec(left, lineY + 2));
      drawLine(new Vec(right, lineY - 2), new Vec(right, lineY + 2));
    }
  }

  Vec endpointToPixel(Vec endpoint) {
    return (hero + transformOctant(endpoint.y - 2, endpoint.x, 0)) * 10;
  }
}

