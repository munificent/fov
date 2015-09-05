library fov.src.demo;

import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

enum Dragging {
  nothing,
  hero,
  wall,
  floor
}

class Tile {
  static const size = 20;

  static const unexplored = 0;
  static const floor = 1;
  static const wall = 3;
  static const hero = 5;
  static const slider = 15;

  bool isWall = false;

  bool get isVisible => _isVisible;
  set isVisible(bool value) {
    _isVisible = value;
    if (value) _isExplored = true;
  }
  bool _isVisible = false;

  bool get isExplored => _isExplored;
  bool _isExplored = false;
}

class Demo {
  static html.ImageElement tileset;

  final Array2D<Tile> tiles;

  html.CanvasElement _canvas;
  html.CanvasRenderingContext2D _context;
  double _scale;
  bool _running = false;

  Demo(String id, int width, int height)
      : tiles = new Array2D<Tile>.generated(width, height, () => new Tile()) {

    _canvas = html.querySelector("#$id") as html.CanvasElement;
    _context = _canvas.context2D;

    // Handle high-resolution (i.e. retina) displays.
    _scale = html.window.devicePixelRatio;
    var size = tiles.size * (Tile.size ~/ 2) * _scale.toInt();
    _canvas.width = size.x.toInt();
    _canvas.height = size.y.toInt();

    _canvas.onMouseDown.listen(_onMouseDown);
    _canvas.onMouseMove.listen(_onMouseMove);
    _canvas.onMouseUp.listen(_onMouseUp);
  }

  void _onMouseDown(html.MouseEvent event) {
    onMouseDown(_mousePos(event));
  }

  void _onMouseMove(html.MouseEvent event) {
    onMouseMove(_mousePos(event));
  }

  void _onMouseUp(html.MouseEvent event) {
    onMouseUp(_mousePos(event));
  }

  void onMouseDown(Vec pos) {
    _running = !_running;

    if (_running) html.window.requestAnimationFrame(_tick);
  }

  void onMouseMove(Vec pos) {}

  void onMouseUp(Vec pos) {}

  bool onTick() => false;

  void render() {
    for (var pos in tiles.bounds) {
      drawTile(pos);
    }
  }

  void clear() {
    _context.clearRect(0, 0, _canvas.width, _canvas.height);
  }

  void drawTile(Vec pos, [int sprite]) {
    if (sprite == null) {
      var tile = tiles[pos];
      sprite = Tile.unexplored;
      if (tile.isExplored) {
        sprite = tile.isWall ? Tile.wall : Tile.floor;
        if (tile.isVisible) sprite++;
      }
    }

    var w = Tile.size ~/ 2;
    drawSprite(pos * w, sprite);
  }

  void drawSprite(Vec pos, int sprite) {
    var w = Tile.size ~/ 2;
    _context.drawImageScaledFromSource(tileset,
        sprite * Tile.size, 0, Tile.size, Tile.size,
        pos.x * _scale, pos.y * _scale,
        w * _scale, w * _scale);
  }

  set strokeStyle(String value) {
    _context.strokeStyle = value;
  }

  void drawLine(Vec from, Vec to) {
    _context.beginPath();
    _context.moveTo(from.x * _scale, from.y * _scale);
    _context.lineTo(to.x * _scale, to.y * _scale);
    _context.closePath();
    _context.stroke();
  }

  Iterable<Vec> walkOctant(Vec center, int octant, [int distance = 10]) sync* {
    var steps = octantSteps(octant);

    for (var row = 1; row < distance; row++) {
      // Stop if we go out of bounds.
      if (!tiles.bounds.contains(center + steps[0] * row)) return;

      for (var col = 0; col <= row; col++) {
        var pos = center + steps[0] * row + steps[1] * col;

        // Skip any columns that are out of bounds.
        if (tiles.bounds.contains(pos)) {
          yield pos;
        }
      }
    }
  }

  List<Vec> octantSteps(int octant) {
    switch (octant) {
      case 0: return [new Vec( 0, -1), new Vec( 1,  0)];
      case 1: return [new Vec( 1,  0), new Vec( 0, -1)];
      case 2: return [new Vec( 1,  0), new Vec( 0,  1)];
      case 3: return [new Vec( 0,  1), new Vec( 1,  0)];
      case 4: return [new Vec( 0,  1), new Vec(-1,  0)];
      case 5: return [new Vec(-1,  0), new Vec( 0,  1)];
      case 6: return [new Vec(-1,  0), new Vec( 0, -1)];
      case 7: return [new Vec( 0, -1), new Vec(-1,  0)];
    }

    throw "unreachable";
  }

  Vec _mousePos(html.MouseEvent event) {
    var x = (event.offset.x / _canvas.clientWidth * tiles.width).toInt();
    var y = (event.offset.y / _canvas.clientHeight * tiles.height).toInt();
    return new Vec(x, y);
  }

  void _tick(num elapsed) {
    // If they clicked to stop the animation, stop now.
    if (!_running) return;

    if (onTick()) {
      html.window.requestAnimationFrame(_tick);
    } else {
      _running = false;
    }
  }
}
