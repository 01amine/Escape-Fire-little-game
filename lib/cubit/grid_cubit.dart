import "package:flutter_bloc/flutter_bloc.dart";

import "grid_state.dart";

class GridCubit extends Cubit<GridState> {
  static const int gridSize = 5;

  GridCubit() : super(GridState(x: 2, y: 2));

  void moveUp() {
    int newY = state.y - 1;
    if (newY < 0) newY = gridSize - 1;
    emit(GridState(x: state.x, y: newY));
  }

  void moveDown() {
    int newY = state.y + 1;
    if (newY >= gridSize) newY = 0;
    emit(GridState(x: state.x, y: newY));
  }

  void moveLeft() {
    int newX = state.x - 1;
    if (newX < 0) newX = gridSize - 1;
    emit(GridState(x: newX, y: state.y));
  }

  void moveRight() {
    int newX = state.x + 1;
    if (newX >= gridSize) newX = 0;
    emit(GridState(x: newX, y: state.y));
  }
}
