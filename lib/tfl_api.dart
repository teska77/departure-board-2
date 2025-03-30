import 'dart:convert';

import 'departure_model.dart';
import 'package:http/http.dart' as http;

class TimedDeparture {
  final DateTime time;
  final Departure dep;

  TimedDeparture({required this.time, required this.dep});
}

class TflBusDepartureService extends StationDepartureService {
  final List<String> naptanCodes;

  TflBusDepartureService({required this.naptanCodes, required super.name})
    : super(logo: StationLogo.tflBus, pollTime: Duration(seconds: 5));

  @override
  Future<StationData> getLatest() async {
    try {
      final List<TimedDeparture> deps = [];
      for (final naptan in naptanCodes) {
        final response = await http.get(
          Uri.parse("https://api.tfl.gov.uk/StopPoint/$naptan/Arrivals"),
        );
        if (response.statusCode == 200) {
          final arrivals = jsonDecode(response.body) as List<dynamic>;
          deps.addAll(arrivals.map((j) => parseDeparture(j)));
        } else {
          return StationData.error("Got HTTP ${response.statusCode}");
        }
      }

      deps.sort((a, b) => a.time.compareTo(b.time));

      return StationData.departures(deps.map((d) => d.dep).toList());
    } catch (e) {
      return StationData.error("$e");
    }
  }

  TimedDeparture parseDeparture(dynamic dep) {
    final String line = dep["lineName"];
    final String dest = dep["destinationName"];

    final arrivalTimestamp = DateTime.parse(dep["expectedArrival"]);
    final arrivalDifference = arrivalTimestamp.difference(DateTime.now());

    final String arrivalTime;
    if (arrivalDifference.inMicroseconds > 0) {
      if (arrivalDifference.inMinutes == 0) {
        arrivalTime = "Due";
      } else {
        arrivalTime = "${arrivalDifference.inMinutes}m";
      }
    } else {
      arrivalTime = "Due";
    }

    return TimedDeparture(
      time: arrivalTimestamp,
      dep: Departure.bus(
        time: arrivalTime,
        secondaryText: "$line $dest",
        isLive: true,
      ),
    );
  }
}
