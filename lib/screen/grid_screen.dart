import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:grid_controller/cubit/grid_cubit.dart";

import "../cubit/grid_state.dart";

class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 75, horizontal: 10),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: BlocBuilder<GridCubit, GridState>(
                builder: (context, state) {
                  return GridView.builder(
                    itemCount: 25,
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisExtent: 70.0,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemBuilder: (context, index) {
                      // Calculate row and column from index
                      int row = index ~/ 5;
                      int col = index % 5;
                      
                      // Check if this is the selected square
                      bool isSelected = (col == state.x && row == state.y);
                      
                      return Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      context.read<GridCubit>().moveUp();
                    },
                    icon: Icon(Icons.arrow_upward_outlined, size: 40),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<GridCubit>().moveLeft();
                        },
                        icon: Icon(Icons.arrow_back_outlined, size: 40),
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          context.read<GridCubit>().moveRight();
                        },
                        icon: Icon(Icons.arrow_forward_outlined, size: 40),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<GridCubit>().moveDown();
                    },
                    icon: Icon(Icons.arrow_downward_outlined, size: 40),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}