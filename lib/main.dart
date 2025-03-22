import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'departure.dart';

void main() {
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
    return Scaffold(
      body: Column(
        children: [
          DepartureWidget(
            departure: Departure.train(
              time: "16:05",
              type: DepartureType.normal,
            ),
          ),
          DepartureWidget(
            departure: Departure.train(
              time: "16:05",
              type: DepartureType.normal,
            ),
          ),
          DepartureWidget(
            departure: Departure.bus(
              time: "11m",
              secondaryText: "Kingston",
              isLive: true,
            ),
          ),
          DepartureWidget(
            departure: Departure.bus(
              time: "31m",
              secondaryText: "Kingston",
              isLive: false,
            ),
          ),
          DepartureWidget(
            departure: Departure.train(
              time: "16:34",
              type: DepartureType.delayed,
              secondaryText: "16:38",
            ),
          ),
          DepartureWidget(
            departure: Departure.train(
              time: "17:04",
              type: DepartureType.cancelled,
              secondaryText: "Cancelled",
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
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
