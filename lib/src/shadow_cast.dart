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

  int _line = 8;

  Dragging _dragging = Dragging.nothing;
  Vec _dragFrom;

  ShadowCast(String id) : super(id, 31, 19) {
    tiles.get(10, 17).isWall = true;
    tiles.get(12, 12).isWall = true;
    tiles.get(12, 13).isWall = true;
    tiles.get(15, 14).isWall = true;
    tiles.get(16, 14).isWall = true;
    tiles.get(17, 10).isWall = true;
    tiles.get(18, 10).isWall = true;
    tiles.get(19, 10).isWall = true;
    tiles.get(20, 10).isWall = true;
    tiles.get(20, 11).isWall = true;
    tiles.get(20, 12).isWall = true;

    render();
  }

  void onMouseDown(Vec pos) {
    if (pos.y > 17) {
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
        var line = pos.x - hero.x;
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
    for (var pos in walkOctant(hero, 1, 18)) {
      tiles[pos].isVisible = true;
    }

    var shadows = new Fov(this).refreshOctant(hero, 1, _line + 1);

    drawTile(hero);
    drawTile(hero, Tile.hero);

    for (var pos in walkOctant(hero, 1, 18)) {
      drawTile(pos);
    }

    var lineX = (_line + hero.x + 1) * 10;
    var lineTop = (16 - _line) * 10;
    var lineBottom = 18 * 10;

    strokeStyle = "rgba(200, 0, 0, 0.3)";
    drawLine(new Vec(lineX, lineTop), new Vec(lineX, lineBottom));

    strokeStyle = "rgba(220, 0, 0, 1.0)";

    drawShadows(int x, int lineTop, int lineBottom) {
      var lineHeight = lineBottom - lineTop;

      for (var shadow in shadows) {
        var top = (1 - shadow.start) * lineHeight + lineTop;
        var bottom = (1 - shadow.end) * lineHeight + lineTop;

        //if (top < 4) top = 4;

        drawLine(new Vec(x, top), new Vec(x, bottom));
        drawLine(new Vec(x - 2, top), new Vec(x + 2, top));
        drawLine(new Vec(x - 2, bottom), new Vec(x + 2, bottom));
      }
    }

    drawShadows(lineX, lineTop, lineBottom);
    drawShadows(280, 0, 180);

    drawSprite(new Vec(lineX - 5, 180), Tile.slider);
  }
}

