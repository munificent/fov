library fov.web.main;

import 'dart:html' as html;

import 'package:fov/src/demo.dart';
import 'package:fov/src/game.dart';
import 'package:fov/src/octant.dart';
import 'package:fov/src/shadow_cast.dart';

main() {
  Demo.tileset = new html.ImageElement(src: "/image/2015/09/tiles.png");
  Demo.tileset.onLoad.listen(_start);
}

_start(_) {
  new Game("explore");
  new Octant("octant", allOctants: false);
  new Octant("octants", allOctants: true);
  new ShadowCast("shadow-cast");
}
