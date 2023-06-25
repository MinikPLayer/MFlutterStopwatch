import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:stopwatch_flutter/state/global_app_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Pressing space in the focused text field now toggles the checkbox.
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: DynamicColorBuilder(
        builder: (lightScheme, darkScheme) => MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: lightScheme ?? const ColorScheme.light(),
            useMaterial3: true,
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const ColorScheme.light().surface,
              contentTextStyle: const TextStyle(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme ?? const ColorScheme.dark(),
            useMaterial3: true,
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const ColorScheme.dark().surface,
              contentTextStyle: const TextStyle(color: Colors.white),
            ),
          ),
          themeMode: ThemeMode.system,
          home: ChangeNotifierProvider(
            create: (context) => GlobalAppState(),
            child: const MyHomePage(title: "Rudy zegarek"),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class SavedDurationEntry {
  final int index;
  final String time;

  SavedDurationEntry(this.index, this.time);
}

class ListModel<T> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  final Function(BuildContext context, T s, Animation<double> animation)
      itemBuilder;
  final List<T> items = [];
  final Duration duration;

  ListModel(this.itemBuilder,
      {this.duration = const Duration(milliseconds: 100)});

  AnimatedListState get _animatedList => listKey.currentState!;

  void removeAt(int index) {
    final removedItem = items.removeAt(index);
    if (removedItem != null) {
      _animatedList.removeItem(index,
          (context, animation) => itemBuilder(context, removedItem, animation),
          duration: duration);
    }
  }

  void insert(int index, T item) {
    items.insert(index, item);
    _animatedList.insertItem(index);
  }
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  var stopwatch = Stopwatch();
  var durationText = "";

  var savedDurations = <SavedDurationEntry>[];
  final GlobalKey<AnimatedListState> savedDurationsListKey =
      GlobalKey<AnimatedListState>();

  AnimationController? _animationController;
  Animation? _animation;

  int currentState = 0;

  String _printDuration(Duration duration) {
    String twoDigits(int n, int v) => v.toString().padLeft(n, "0");
    String twoDigitMinutes = twoDigits(2, duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(2, duration.inSeconds.remainder(60));
    String twoDigitMilliseconds =
        twoDigits(3, duration.inMilliseconds.remainder(1000)).substring(0, 2);
    return "$twoDigitMinutes:$twoDigitSeconds:$twoDigitMilliseconds";
  }

  void updateDuration() {
    setState(() {
      durationText = _printDuration(stopwatch.elapsed);
    });
  }

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      updateDuration();
    });

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _animation = IntTween(begin: 0, end: 1).animate(_animationController!);
    _animation!.addListener(() => setState(() {}));
  }

  int getCurrentState() {
    if (!stopwatch.isRunning) {
      if (stopwatch.elapsedTicks == 0) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 2;
    }
  }

  List<Widget> getActions() {
    switch (currentState) {
      case 0:
        return [
          ElevatedButton.icon(
            onPressed: () {
              stopwatch.start();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withGreen(255),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            label: const Text('Start'),
            icon: const Icon(Icons.play_arrow),
          ),
        ];

      case 1:
        return [
          ElevatedButton.icon(
            onPressed: () async {
              if (savedDurations.isNotEmpty) {
                _animationController!.reverse();
              }
              stopwatch.reset();
              for (var s in savedDurations) {
                savedDurationsListKey.currentState!.removeItem(
                    0,
                    (context, animation) =>
                        _buildSavedDurationItem(context, s, animation),
                    duration: const Duration(milliseconds: 100));
              }
              savedDurations.clear();
              updateDuration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            label: const Text('Reset'),
            icon: const Icon(Icons.replay),
          ),
          ElevatedButton.icon(
            onPressed: () {
              stopwatch.start();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withBlue(255),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            label: const Text('Resume'),
            icon: const Icon(Icons.play_arrow),
          ),
        ];

      case 2:
        return [
          ElevatedButton.icon(
            onPressed: () {
              if (savedDurations.isEmpty) {
                _animationController!.forward();
              }
              setState(() {
                savedDurations.insert(
                    0,
                    SavedDurationEntry(savedDurations.length,
                        _printDuration(stopwatch.elapsed)));
                savedDurationsListKey.currentState!
                    .insertItem(0, duration: const Duration(milliseconds: 200));
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.error.withBlue(128),
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            label: const Text('Stamp'),
            icon: const Icon(Icons.flag),
          ),
          ElevatedButton.icon(
            onPressed: () {
              stopwatch.stop();
              updateDuration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withRed(200),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            label: const Text('Pause'),
            icon: const Icon(Icons.pause),
          ),
        ];

      default:
        throw Exception("Invalid state");
    }
  }

  Widget savedDurationsToRow(int key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (key != -1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '${key + 1}. ',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSavedDurationItem(
      BuildContext context, SavedDurationEntry s, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: savedDurationsToRow(s.index, s.time),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    currentState = getCurrentState();

    print(_animationController!.value.toString());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              flex: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Stopwatch',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    durationText,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: (_animationController!.value * 100).toInt(),
              child: AnimatedList(
                shrinkWrap: true,
                key: savedDurationsListKey,
                itemBuilder: (context, index, animation) {
                  var item = savedDurations[index];
                  return _buildSavedDurationItem(context, item, animation);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Row(
                  key: ValueKey(currentState),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: getActions()
                      .map((e) =>
                          Padding(padding: const EdgeInsets.all(8.0), child: e))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
