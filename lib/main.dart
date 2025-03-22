import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'departure_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final options = WindowOptions(size: Size(1920, 360));
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(TrainboardApp());
}

class TrainboardState extends ChangeNotifier {}

class TrainboardApp extends StatelessWidget {
  const TrainboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final commonTextColor = Color(0xffeeeeee);
    return ChangeNotifierProvider(
      create: (context) => TrainboardState(),
      child: MaterialApp(
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
              fontSize: 45,
              fontWeight: FontWeight.w200,
            ),
            bodyMedium: GoogleFonts.robotoMono(
              fontSize: 40,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        home: MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final station = StationData(
      name: "Chessington South",
      logo: StationLogo.southWesternRailway,
      departures: [
        Departure.bus(time: "12m", secondaryText: "Kingston", isLive: true),
        Departure.bus(time: "31m", secondaryText: "Kingston", isLive: false),
        Departure.train(
          time: "16:34",
          type: DepartureType.delayed,
          secondaryText: "16:38",
        ),
        Departure.train(
          time: "17:04",
          type: DepartureType.cancelled,
          secondaryText: "Cancelled",
        ),
      ],
    );

    final station2 = StationData(
      name: "Wim Thameslink",
      logo: StationLogo.thamesLink,
      departures: [
        Departure.train(time: "16:34", type: DepartureType.normal),
        Departure.train(time: "17:04", type: DepartureType.normal),
      ],
    );
    final station3 = StationData(
      name: "Rushett Lane",
      logo: StationLogo.digico,
      departures: [
        Departure.train(time: "16:34", type: DepartureType.normal),
        Departure.train(time: "17:04", type: DepartureType.normal),
      ],
    );
    return Scaffold(
      body: Row(
        children: [
          Expanded(child: StationWidget(station: station)),
          Expanded(child: StationWidget(station: station2)),
          Expanded(child: StationWidget(station: station3)),
          Expanded(child: StationWidget(station: station2)),
        ],
      ),
    );
  }
}

class StationWidget extends StatelessWidget {
  final StationData station;

  const StationWidget({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final svgHeight = 40.0;

    Widget logo;
    switch (station.logo) {
      case StationLogo.southWesternRailway:
        logo = SvgPicture.asset("assets/swr_logo.svg", height: svgHeight);
        break;
      case StationLogo.thamesLink:
        logo = SvgPicture.asset(
          "assets/thameslink_logo.svg",
          height: svgHeight,
        );
        break;
      case StationLogo.tflBus:
        logo = SvgPicture.asset("assets/buses_roundel.svg", height: svgHeight);
        break;
      case StationLogo.digico:
        logo = SvgPicture.asset("assets/digico.svg", height: svgHeight);
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TitleCard(title: station.name, icon: logo),
          for (final departure in station.departures)
            DepartureWidget(departure: departure),
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
            spacing: 10,
            children: [
              Text(
                departure.time,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: fg,
                  decoration: timeTextDecoration,
                ),
              ),
              Spacer(),
              if (departure.secondaryText != null)
                Text(
                  departure.secondaryText!,
                  style: theme.textTheme.bodyMedium!.copyWith(color: fg),
                ),

              if (departure.icon != DepartureIcon.none)
                Icon(icon, color: iconColor, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}
