enum DepartureType { normal, delayed, cancelled }

enum DepartureIcon { none, check, live, scheduled, speed }

class Departure {
  final DepartureType type;
  final String time;
  final bool timeStrikethrough;
  final String? secondaryText;
  final DepartureIcon icon;

  Departure(
    this.type,
    this.time,
    this.timeStrikethrough,
    this.secondaryText,
    this.icon,
  );
  Departure.train({required this.time, required this.type, this.secondaryText})
    : timeStrikethrough =
          (type == DepartureType.delayed || type == DepartureType.cancelled),
      icon =
          type == DepartureType.normal
              ? DepartureIcon.check
              : DepartureIcon.none;

  Departure.bus({
    required this.time,
    required this.secondaryText,
    required bool isLive,
  }) : type = DepartureType.normal,
       timeStrikethrough = false,
       icon = isLive ? DepartureIcon.live : DepartureIcon.scheduled;
}

enum StationLogo { southWesternRailway, thamesLink, tflBus, digico, highway }

class StationData {
  final String? errorText;
  final List<Departure> departures;

  StationData({required this.departures, this.errorText});
  StationData.departures(this.departures) : errorText = null;
  StationData.error(this.errorText) : departures = [];
}

abstract class StationDepartureService {
  final String name;
  final StationLogo logo;
  final Duration pollTime;

  StationDepartureService({
    required this.name,
    required this.logo,
    this.pollTime = const Duration(seconds: 5),
  });

  Future<StationData> getLatest();
}
