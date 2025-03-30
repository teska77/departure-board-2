import 'dart:convert';

import 'departure_model.dart';
import 'package:http/http.dart' as http;

class TflBusDepartureService extends StationDepartureService {
  final String naptanCode;

  TflBusDepartureService({required this.naptanCode, required super.name})
    : super(logo: StationLogo.tflBus, pollTime: Duration(seconds: 5));

  @override
  Future<StationData> getLatest() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.tfl.gov.uk/StopPoint/$naptanCode/Arrivals"),
      );
      if (response.statusCode == 200) {
        final arrivals = jsonDecode(response.body) as List<dynamic>;
        return StationData.departures(
          arrivals.map((j) => parseDeparture(j)).toList(),
        );
      } else {
        return StationData.error("Got HTTP ${response.statusCode}");
      }
    } catch (e) {
      return StationData.error("$e");
    }
  }

  Departure parseDeparture(dynamic dep) {
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

    return Departure.bus(
      time: arrivalTime,
      secondaryText: "$line $dest",
      isLive: true,
    );
  }
}
