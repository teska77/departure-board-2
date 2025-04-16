import 'dart:async';

import 'package:depboard2_flutter/ldbws.dart';
import 'package:depboard2_flutter/tfl_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// import 'package:window_manager/window_manager.dart';
import 'departure_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await windowManager.ensureInitialized();
  //final options = WindowOptions(size: Size(1920, 360));
  //await windowManager.waitUntilReadyToShow(options, () async {
  //  await windowManager.show();
  //  await windowManager.focus();
  //});

  final state = TrainboardState([
    TflBusDepartureService(
      naptanCodes: ["490011796S", "490011796N"],
      name: "Bussy",
    ),
    LdbwsService(
      crs: "CSS",
      name: "Chessington",
      logo: StationLogo.southWesternRailway,
      reportDestination: false,
    ),
    LdbwsService(
      crs: "WIM",
      name: "Wim Thameslink",
      logo: StationLogo.thamesLink,
      reportDestination: true,
      operatorCodeFilter: "TL",
    ),
  ], depRowLimit: 4);

  await state.runInitialQueries();

  runApp(
    ChangeNotifierProvider(
      create: (context) => state,
      child: const TrainboardApp(),
    ),
  );
}

class StationDepartureState {
  final StationDepartureService service;
  StationData data = StationData.error("Not yet polled");

  StationDepartureState({required this.service});
}

class TrainboardState extends ChangeNotifier {
  late final List<StationDepartureState> stationStates;
  final int depRowLimit;

  TrainboardState(
    List<StationDepartureService> services, {
    this.depRowLimit = 0,
  }) {
    stationStates =
        services.map((service) {
          var depState = StationDepartureState(service: service);
          Timer.periodic(
            service.pollTime,
            (t) async => onTimerExpired(depState),
          );
          return depState;
        }).toList();
  }

  Future<void> onTimerExpired(StationDepartureState state) async {
    state.data = await state.service.getLatest();
    // TODO(liam) change notification could be per-service to avoid everything
    // redrawing
    notifyListeners();
  }

  Future<void> runInitialQueries() async {
    final queries = stationStates.map((s) => s.service.getLatest()).toList();
    await Future.wait(queries);
  }
}

class TrainboardApp extends StatelessWidget {
  const TrainboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final commonTextColor = Color(0xffeeeeee);
    return MaterialApp(
      title: 'Trainboard',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xff212121),
        useMaterial3: false,
        colorScheme: ColorScheme.dark(
          // primary = normal
          primary: Color(0xff313131),
          onPrimary: commonTextColor,

          // secondary = delayed
          secondary: Color(0xff664f0e),
          onSecondary: commonTextColor,

          // tertiary = cancelled
          tertiary: Color(0xff5a1919),
          onTertiary: commonTextColor,

          // used for lowkey icons on primary
          onPrimaryFixed: Color(0xff5b5b5b),
          // used for pop icons on primary
          onPrimaryFixedVariant: Color(0xffc5b019),
        ),
        textTheme: TextTheme(
          titleMedium: GoogleFonts.roboto(
            fontSize: 38,
            fontWeight: FontWeight.w200,
          ),
          bodyMedium: GoogleFonts.robotoMono(
            fontSize: 35,
            fontWeight: FontWeight.normal,
          ),
          bodySmall: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.w200,
          ),
        ),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TrainboardState>(
        builder: (_, state, _) {
          return Row(
            children:
                state.stationStates
                    .map(
                      (station) => Expanded(
                        child: StationWidget(
                          station: station.data,
                          name: station.service.name,
                          logo: station.service.logo,
                          depRowLimit: state.depRowLimit,
                        ),
                      ),
                    )
                    .toList(),
          );
        },
      ),
    );
  }
}

class StationWidget extends StatelessWidget {
  final String name;
  final StationLogo logo;
  final StationData station;
  final int depRowLimit;

  const StationWidget({
    super.key,
    required this.station,
    required this.name,
    required this.logo,
    required this.depRowLimit,
  });

  @override
  Widget build(BuildContext context) {
    final svgHeight = 30.0;

    Widget logoWidget;
    switch (logo) {
      case StationLogo.southWesternRailway:
        logoWidget = SvgPicture.asset("assets/swr_logo.svg", height: svgHeight);
        break;
      case StationLogo.thamesLink:
        logoWidget = SvgPicture.asset(
          "assets/thameslink_logo.svg",
          height: svgHeight,
        );
        break;
      case StationLogo.tflBus:
        logoWidget = SvgPicture.asset(
          "assets/buses_roundel.svg",
          height: svgHeight,
        );
        break;
      case StationLogo.digico:
        logoWidget = SvgPicture.asset("assets/digico.svg", height: svgHeight);
        break;
    }

    List<Widget> departuresList;
    if (station.errorText != null) {
      departuresList = [StationErrorWidget(errorText: station.errorText!)];
    } else {
      var depWidgets = station.departures.map(
        (dep) => DepartureWidget(departure: dep),
      );
      if (depRowLimit != 0) {
        departuresList = depWidgets.take(depRowLimit).toList();
      } else {
        departuresList = depWidgets.toList();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TitleCard(title: name, icon: logoWidget),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: departuresList),
            ),
          ),
        ],
      ),
    );
  }
}

class TitleCard extends StatelessWidget {
  final String title;
  final Widget icon;

  const TitleCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        spacing: 10,
        children: [
          icon,
          Text(
            title,
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class StationErrorWidget extends StatelessWidget {
  final String errorText;
  const StationErrorWidget({super.key, required this.errorText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.tertiary;
    final fg = theme.colorScheme.onTertiary;

    return Container(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Column(
            children: [
              Text(
                "Error",
                style: theme.textTheme.bodyMedium!.copyWith(color: fg),
              ),
              FittedBox(
                child: Text(
                  errorText,
                  style: theme.textTheme.bodySmall!.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DepartureWidget extends StatelessWidget {
  const DepartureWidget({super.key, required this.departure});

  final Departure departure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;
    switch (departure.type) {
      case DepartureType.normal:
        bg = theme.colorScheme.primary;
        fg = theme.colorScheme.onPrimary;
        break;
      case DepartureType.delayed:
        bg = theme.colorScheme.secondary;
        fg = theme.colorScheme.onSecondary;
        break;
      case DepartureType.cancelled:
        bg = theme.colorScheme.tertiary;
        fg = theme.colorScheme.onTertiary;
        break;
    }

    final timeTextDecoration =
        departure.timeStrikethrough
            ? TextDecoration.lineThrough
            : TextDecoration.none;

    IconData icon;
    Color iconColor;
    switch (departure.icon) {
      case DepartureIcon.none:
        icon = Icons.abc;
        iconColor = Colors.black;
      case DepartureIcon.check:
        icon = Icons.check_rounded;
        iconColor = theme.colorScheme.onPrimaryFixed;
      case DepartureIcon.live:
        icon = Icons.rss_feed;
        iconColor = theme.colorScheme.onPrimaryFixedVariant;
      case DepartureIcon.scheduled:
        icon = Icons.calendar_month;
        iconColor = theme.colorScheme.onPrimaryFixed;
    }

    return Container(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            spacing: 30,
            children: [
              Text(
                departure.time,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: fg,
                  decoration: timeTextDecoration,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (departure.secondaryText != null)
                      Flexible(
                        child: Text(
                          departure.secondaryText!,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    if (departure.icon != DepartureIcon.none)
                      Icon(icon, color: iconColor, size: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
