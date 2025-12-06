import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:grid_controller/cubit/grid_cubit.dart";
import "../cubit/grid_state.dart";

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});
  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> with TickerProviderStateMixin {
  double _ballOffsetX = 0.0;
  double _ballOffsetY = 0.0;
  Timer? _repeatTimer;
  String? _currentDirection;
  String _playerDirection = "down";
  bool _isMoving = false;
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    _precacheAssets();
    _overlayController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _precacheAssets() async {
    for (int i = 1; i <= 24; i++) {
      final assetPath =
          "assets/player/player_${i.toString().padLeft(2, '0')}.png";
      await precacheImage(AssetImage(assetPath), context);
    }
    await precacheImage(AssetImage("assets/ground.png"), context);
    await precacheImage(AssetImage("assets/wall.png"), context);
    await precacheImage(AssetImage("assets/safe.png"), context);
    await precacheImage(AssetImage("assets/fire/fire.png"), context);
  }

  void _startRepeatingMovement(String direction) {
    if (_currentDirection == direction) return;

    _repeatTimer?.cancel();
    _currentDirection = direction;
    _playerDirection = direction;

    setState(() {
      _isMoving = true;
    });

    _triggerMovement(direction);

    _repeatTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _triggerMovement(direction);
    });
  }

  void _triggerMovement(String direction) {
    final cubit = context.read<GridCubit>();
    switch (direction) {
      case "right":
        cubit.moveRight();
        break;
      case "left":
        cubit.moveLeft();
        break;
      case "up":
        cubit.moveUp();
        break;
      case "down":
        cubit.moveDown();
        break;
    }
  }

  void _stopRepeatingMovement() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _currentDirection = null;

    setState(() {
      _isMoving = false;
    });
  }

  void _startGame() {
    context.read<GridCubit>().startGame();
  }

  void _restartGame() {
    context.read<GridCubit>().close();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider(create: (_) => GridCubit(), child: GridScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: SafeArea(
        child: Stack(
          children: [
            // Main game content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  // Grid section
                  Expanded(flex: 3, child: _buildGridSection()),
                  SizedBox(height: 20),
                  // Joystick section
                  Expanded(flex: 2, child: _buildJoystick()),
                ],
              ),
            ),
            // Overlays for start/end game
            _buildGameOverlays(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection() {
    return BlocBuilder<GridCubit, GridState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: EdgeInsets.all(12),
          child: GridView.builder(
            itemCount: 25,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisExtent: 70.0,
              crossAxisSpacing: 6.0,
              mainAxisSpacing: 6.0,
            ),
            itemBuilder: (context, index) {
              int row = index ~/ 5;
              int col = index % 5;
              TileType type = state.grid[row][col];

              Widget tile;
              if (col == state.playerX && row == state.playerY) {
                tile = PlayerTile(
                  direction: _playerDirection,
                  isMoving: _isMoving,
                );
              } else {
                switch (type) {
                  case TileType.ground:
                    tile = Image.asset("assets/ground.png", fit: BoxFit.cover);
                    break;
                  case TileType.wall:
                    tile = Image.asset("assets/wall.png", fit: BoxFit.cover);
                    break;
                  case TileType.safe:
                    tile = Image.asset("assets/safe.png", fit: BoxFit.cover);
                    break;
                  case TileType.fire:
                    tile = FireTile();
                    break;
                }
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: tile,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildJoystick() {
    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _ballOffsetX += details.delta.dx;
            _ballOffsetY += details.delta.dy;

            const double maxOffset = 70.0;
            double distanceSquared =
                (_ballOffsetX * _ballOffsetX + _ballOffsetY * _ballOffsetY);
            if (distanceSquared > maxOffset * maxOffset) {
              double distance = sqrt(distanceSquared);
              _ballOffsetX = (maxOffset * _ballOffsetX) / distance;
              _ballOffsetY = (maxOffset * _ballOffsetY) / distance;
            }
          });

          const double threshold = 25;
          String? direction;
          if (_ballOffsetX.abs() > _ballOffsetY.abs() &&
              _ballOffsetX.abs() > threshold) {
            direction = _ballOffsetX > 0 ? "right" : "left";
          } else if (_ballOffsetY.abs() > threshold) {
            direction = _ballOffsetY > 0 ? "down" : "up";
          }

          if (direction != null) {
            _startRepeatingMovement(direction);
          }
        },
        onPanEnd: (_) {
          setState(() {
            _ballOffsetX = 0.0;
            _ballOffsetY = 0.0;
          });
          _stopRepeatingMovement();
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF2a2a4e), Color(0xFF1a1a2e)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: Duration(
                  milliseconds: _ballOffsetX == 0 && _ballOffsetY == 0
                      ? 200
                      : 0,
                ),
                curve: Curves.easeOut,
                left: 80 + _ballOffsetX,
                top: 80 + _ballOffsetY,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.blue[300]!, Colors.blue[700]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 15,
                child: Icon(
                  Icons.arrow_upward,
                  color: Colors.white30,
                  size: 32,
                ),
              ),
              Positioned(
                bottom: 15,
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.white30,
                  size: 32,
                ),
              ),
              Positioned(
                left: 15,
                child: Icon(Icons.arrow_back, color: Colors.white30, size: 32),
              ),
              Positioned(
                right: 15,
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white30,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverlays() {
    return BlocBuilder<GridCubit, GridState>(
      builder: (context, state) {
        bool showOverlay = false;
        Widget? overlayContent;

        if (!state.gameStarted &&
            state is! GameOverState &&
            state is! WinState) {
          showOverlay = true;
          overlayContent = _buildStartScreen();
        } else if (state is GameOverState) {
          showOverlay = true;
          overlayContent = _buildGameOverScreen();
        } else if (state is WinState) {
          showOverlay = true;
          overlayContent = _buildWinScreen();
        }

        if (showOverlay) {
          _overlayController.forward();
        } else {
          _overlayController.reverse();
        }

        return FadeTransition(
          opacity: _overlayAnimation,
          child: Container(
            color: Colors.black.withOpacity(0.85),
            child: overlayContent ?? SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "ESCAPE THE FIRE",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.green.withOpacity(0.5), blurRadius: 20),
              ],
            ),
          ),
          SizedBox(height: 20),

          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: Colors.green.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 32),
                SizedBox(width: 10),
                Text(
                  "START GAME",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department, size: 100, color: Colors.red[400]),
          SizedBox(height: 30),
          Text(
            "GAME OVER",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.red[400],
              letterSpacing: 3,
              shadows: [
                Shadow(color: Colors.red.withOpacity(0.5), blurRadius: 20),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            "You got caught by the fire!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 50),
          ElevatedButton(
            onPressed: _restartGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: Colors.red.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.replay_rounded, size: 28),
                SizedBox(width: 10),
                Text(
                  "PLAY AGAIN",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 100,
              color: Colors.amber[400],
            ),
            SizedBox(height: 30),
            Text(
              "Rak rbe7t",
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.amber[400],
                letterSpacing: 3,
                shadows: [
                  Shadow(color: Colors.amber.withOpacity(0.5), blurRadius: 20),
                ],
              ),
            ),

            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[700]!, Colors.orange[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset("assets/adel.png", fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    " Level 1 ",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
                shadowColor: Colors.amber.withOpacity(0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "PLAY AGAIN",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _overlayController.dispose();
    super.dispose();
  }
}

class FireTile extends StatefulWidget {
  const FireTile({super.key});
  @override
  State<FireTile> createState() => _FireTileState();
}

class _FireTileState extends State<FireTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _frame;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat();
    _frame = IntTween(begin: 1, end: 6).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        int frameIndex = _frame.value;
        return Image.asset(
          "assets/fire/fire$frameIndex.png",
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class PlayerTile extends StatefulWidget {
  final String direction;
  final bool isMoving;
  const PlayerTile({
    super.key,
    required this.direction,
    required this.isMoving,
  });
  @override
  State<PlayerTile> createState() => _PlayerTileState();
}

class _PlayerTileState extends State<PlayerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _frame;
  int _idleFrame = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(PlayerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction ||
        oldWidget.isMoving != widget.isMoving) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.isMoving) {
      int start = 0, end = 5;
      switch (widget.direction) {
        case "up":
          start = 0;
          end = 5;
          _idleFrame = 0;
          break;
        case "right":
          start = 6;
          end = 11;
          _idleFrame = 6;
          break;
        case "down":
          start = 12;
          end = 17;
          _idleFrame = 12;
          break;
        case "left":
          start = 18;
          end = 23;
          _idleFrame = 18;
          break;
      }
      _frame = IntTween(begin: start, end: end).animate(_controller);
      _controller.repeat();
    } else {
      _controller.stop();
      switch (widget.direction) {
        case "up":
          _idleFrame = 0;
          break;
        case "right":
          _idleFrame = 6;
          break;
        case "down":
          _idleFrame = 12;
          break;
        case "left":
          _idleFrame = 18;
          break;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMoving) {
      return Image.asset(
        "assets/player/player_${(_idleFrame + 1).toString().padLeft(2, '0')}.png",
        fit: BoxFit.cover,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Image.asset(
          "assets/player/player_${(_frame.value + 1).toString().padLeft(2, '0')}.png",
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
