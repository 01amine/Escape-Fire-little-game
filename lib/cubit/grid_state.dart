enum TileType { ground, wall, safe, fire }

class GridState {
  final List<List<TileType>> grid;
  final int playerX;
  final int playerY;
  final bool gameStarted;

  GridState({
    required this.grid,
    required this.playerX,
    required this.playerY,
    required this.gameStarted,
  });

  factory GridState.initial() {
    return GridState(
      grid: [
        [
          TileType.ground,
          TileType.ground,
          TileType.ground,
          TileType.ground,
          TileType.safe,
        ],
        [
          TileType.ground,
          TileType.wall,
          TileType.ground,
          TileType.wall,
          TileType.ground,
        ],
        [
          TileType.ground,
          TileType.ground,
          TileType.ground,
          TileType.ground,
          TileType.ground,
        ],
        [
          TileType.ground,
          TileType.wall,
          TileType.ground,
          TileType.wall,
          TileType.ground,
        ],
        [
          TileType.fire,
          TileType.ground,
          TileType.ground,
          TileType.ground,
          TileType.ground,
        ],
      ],
      playerX: 0,
      playerY: 4,
      gameStarted: false,
    );
  }

  GridState copyWith({
    List<List<TileType>>? grid,
    int? playerX,
    int? playerY,
    bool? gameStarted,
  }) {
    return GridState(
      grid: grid ?? this.grid,
      playerX: playerX ?? this.playerX,
      playerY: playerY ?? this.playerY,
      gameStarted: gameStarted ?? this.gameStarted,
    );
  }
}

class GameOverState extends GridState {
  GameOverState({
    required super.grid,
    required super.playerX,
    required super.playerY,
    required super.gameStarted,
  });
}

class WinState extends GridState {
  WinState({
    required super.grid,
    required super.playerX,
    required super.playerY,
    required super.gameStarted,
  });
}
