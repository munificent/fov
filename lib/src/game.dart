library fov.src.game;

import 'package:piecemeal/piecemeal.dart';

import 'demo.dart';
import 'fov.dart';
import 'los.dart';

enum Dragging {
  nothing,
  hero,
  wall,
  floor
}

final map = """
######################################################
#       ##############################################
#            ###               ######    ##          #
#       #### ###    ########## ####      ## ######## #
#       #### ###### ########## #### #    ## ######## #
#       #### ###### ###          ## #    ## ##   ### #
#       ####    ### ###  #    #  ## ## #### ## # ### #
## ######### ## ### ###  #    #  ## #    ##    # ### #
#     ###### ## ### ###  #    #  ## #    ####### ### #
#     ###### ## ### ###  #    #  ## #    ##       ## #
############ ## ### ###          ## ### ###       ## #
############ ##     ######### ##### #    ##       ## #
#   #        ################ ##### #             ## #
#     #############        ##       ################ #
#   # #############  ####  ######################### #
##### #########      #  #       ######          #### #
#   # ######### ###        #### #####            ### #
#     ######### ############### ####    #         ## #
#   #           ######          ###                # #
###### ### ### ####################       ##         #
#   #   #   #   ##      ##    #####                ###
#       #   #   ## #### ##    ######         #    ####
#   #   #   #      #### ##    #######            #####
#######################       ########          ######
######################################################
""";

class Game extends Demo {
  Dragging _dragging = Dragging.nothing;
  Vec _dragFrom;

  Vec hero = new Vec(3, 3);

  Game(String id)
      : super(id, 54, 25) {
    const hash = 35;

    var y = 0;
    for (var row in map.split("\n")) {
      var x = 0;
      for (var column in row.codeUnits) {
        if (column == hash) tiles.get(x, y).isWall = true;
        x++;
      }

      y++;
    }

    render();
  }

  void onMouseDown(Vec pos) {
    if (pos == hero) {
      _dragging = Dragging.hero;
    } else {
      var tile = tiles[pos];
      tile.isWall = !tile.isWall;
      _dragging = tile.isWall ? Dragging.wall : Dragging.floor;
      _dragFrom = pos;
      render();
    }
  }

  void onMouseMove(Vec pos) {
    if (_dragging == Dragging.nothing) return;

    switch (_dragging) {
      case Dragging.nothing:
        break;

      case Dragging.hero:
        var closest = hero;
        for (var step in new Los(hero, pos)) {
          if (tiles[step].isWall) break;
          closest = step;
          if (step == pos) break;
        }

        if (closest != hero) {
          hero = closest;
          render();
        }
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

      default:
        break;
    }
  }

  void onMouseUp(Vec pos) {
    _dragging = Dragging.nothing;
  }

  void render() {
    new Fov(this).refresh(hero);

    super.render();

    drawTile(hero, Tile.hero);
  }
}
