import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        ),
        home: HomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = 1;

  var favoriteNumbers = <int>{};

  void getNext() {
    current += 1;
    notifyListeners();
  }

  void toggleFavorite() => toggleFavoriteOf(current);

  void toggleFavoriteOf(int n) {
    if (favoriteNumbers.contains(n)) {
      favoriteNumbers.remove(n);
    } else {
      favoriteNumbers.add(n);
    }
    notifyListeners();
  }

  bool currentIsFavorite() => favoriteNumbers.contains(current);
}

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var currentNumber = appState.current;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Wowzer"),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: NumberDisplayer1000(
            currentNumber: currentNumber,
            isPhat: true,
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            FavoriteButton(number: appState.current),
            ElevatedButton(
              onPressed: () => appState.getNext(),
              child: Text("next"),
            ),
          ],
        ),
      ],
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return ElevatedButton.icon(
      onPressed: () => appState.toggleFavoriteOf(number),
      icon: Icon(
        appState.currentIsFavorite() ? Icons.favorite : Icons.favorite_outline,
        color: Colors.redAccent,
      ),
      label: Text("Favorite"),
    );
  }
}

class NumberDisplayer1000 extends StatelessWidget {
  const NumberDisplayer1000({
    super.key,
    required this.currentNumber,
    this.isPhat = false,
  });

  final int currentNumber;
  final bool isPhat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base =
        isPhat ? theme.textTheme.displayMedium : theme.textTheme.bodyMedium;
    final style = base!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontFamily: "mono",
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isPhat ? 80 : 10,
          vertical: isPhat ? 20 : 10,
        ),
        child: Text(currentNumber.toString(), style: style),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('No widget');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text("Home"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text("Favorite"),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var state = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Column(
      children: [
        Text("Favorites", style: theme.textTheme.displayMedium),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children:
                state.favoriteNumbers.map((n) {
                  return Row(
                    spacing: 10,
                    children: [
                      NumberDisplayer1000(currentNumber: n),
                      FavoriteButton(number: n),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
