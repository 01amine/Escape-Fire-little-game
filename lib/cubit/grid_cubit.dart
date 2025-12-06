import "dart:async";
import "package:flutter_bloc/flutter_bloc.dart";
import "grid_state.dart";

class GridCubit extends Cubit<GridState> {
  Timer? _fireSpreadTimer;

  GridCubit() : super(GridState.initial());

  void startGame() {
    emit(state.copyWith(gameStarted: true));
    
    // Increased delay from 5 to 8 seconds to make it easier
    _fireSpreadTimer = Timer.periodic(Duration(seconds: 8), (_) {
      _spreadFire();
    });
  }

  void _spreadFire() {
    if (state is GameOverState || state is WinState) {
      _fireSpreadTimer?.cancel();
      return;
    }

    List<List<TileType>> newGrid = List.generate(
      5,
      (i) => List.from(state.grid[i]),
    );

    // Find all current fire tiles
    List<List<int>> firePositions = [];
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (newGrid[row][col] == TileType.fire) {
          firePositions.add([row, col]);
        }
      }
    }

    // Spread fire to adjacent ground tiles
    for (var pos in firePositions) {
      int row = pos[0];
      int col = pos[1];

      // Check all 4 directions
      List<List<int>> directions = [
        [row - 1, col], // up
        [row + 1, col], // down
        [row, col - 1], // left
        [row, col + 1], // right
      ];

      for (var dir in directions) {
        int newRow = dir[0];
        int newCol = dir[1];

        if (newRow >= 0 && newRow < 5 && newCol >= 0 && newCol < 5) {
          if (newGrid[newRow][newCol] == TileType.ground) {
            newGrid[newRow][newCol] = TileType.fire;
            
            // Check if player is on this tile
            if (state.playerX == newCol && state.playerY == newRow) {
              _fireSpreadTimer?.cancel();
              emit(GameOverState(
                grid: newGrid,
                playerX: state.playerX,
                playerY: state.playerY,
                gameStarted: state.gameStarted,
              ));
              return;
            }
          }
        }
      }
    }

    emit(state.copyWith(grid: newGrid));
  }

  void moveRight() {
    if (state is GameOverState || state is WinState || !state.gameStarted) return;
    
    int newX = state.playerX + 1;
    if (newX < 5 && state.grid[state.playerY][newX] != TileType.wall) {
      _movePlayer(newX, state.playerY);
    }
  }

  void moveLeft() {
    if (state is GameOverState || state is WinState || !state.gameStarted) return;
    
    int newX = state.playerX - 1;
    if (newX >= 0 && state.grid[state.playerY][newX] != TileType.wall) {
      _movePlayer(newX, state.playerY);
    }
  }

  void moveUp() {
    if (state is GameOverState || state is WinState || !state.gameStarted) return;
    
    int newY = state.playerY - 1;
    if (newY >= 0 && state.grid[newY][state.playerX] != TileType.wall) {
      _movePlayer(state.playerX, newY);
    }
  }

  void moveDown() {
    if (state is GameOverState || state is WinState || !state.gameStarted) return;
    
    int newY = state.playerY + 1;
    if (newY < 5 && state.grid[newY][state.playerX] != TileType.wall) {
      _movePlayer(state.playerX, newY);
    }
  }

  void _movePlayer(int newX, int newY) {
    TileType targetTile = state.grid[newY][newX];

    if (targetTile == TileType.fire) {
      _fireSpreadTimer?.cancel();
      emit(GameOverState(
        grid: state.grid,
        playerX: newX,
        playerY: newY,
        gameStarted: state.gameStarted,
      ));
    } else if (targetTile == TileType.safe) {
      _fireSpreadTimer?.cancel();
      emit(WinState(
        grid: state.grid,
        playerX: newX,
        playerY: newY,
        gameStarted: state.gameStarted,
      ));
    } else {
      emit(state.copyWith(playerX: newX, playerY: newY));
    }
  }

  @override
  Future<void> close() {
    _fireSpreadTimer?.cancel();
    return super.close();
  }
}