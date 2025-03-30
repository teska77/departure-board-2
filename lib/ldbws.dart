import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'departure_model.dart';
import 'package:http/http.dart' as http;

// TODO(liam)
const String API_KEY = "e3d8b441-61aa-4ce8-9709-6872af719b2a";

class LdbwsService extends StationDepartureService {
  final String crs;

  LdbwsService({required this.crs, required super.name, required super.logo})
    : super(pollTime: Duration(seconds: 5));

  @override
  Future<StationData> getLatest() async {
    try {
      // I don't actually know anything about the SOAP protocol or WSDL.
      // This was done via reverse engineering with wireshark and is definitely
      // no where near actual compliance with SOAP
      final wsdlResponse = await http.get(
        Uri.parse(
          "https://lite.realtime.nationalrail.co.uk/OpenLDBWS/wsdl.aspx?ver=2021-11-01",
        ),
      );
      if (wsdlResponse.statusCode != 200) {
        return StationData.error("Got HTTP ${wsdlResponse.statusCode}");
      }
      final wsdl = XmlDocument.parse(wsdlResponse.body);

      // return from API eg:
      //
      // <?xml version="1.0" encoding="utf-8"?>
      // <wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:tns="http://thalesgroup.com/RTTI/2021-11-01/ldb/" targetNamespace="http://thalesgroup.com/RTTI/2021-11-01/ldb/">

      // <wsdl:import namespace="http://thalesgroup.com/RTTI/2021-11-01/ldb/" location="rtti_2021-11-01_ldb.wsdl" />

      // <wsdl:service name="ldb">
      //   <wsdl:port name="LDBServiceSoap" binding="tns:LDBServiceSoap">
      //     <soap:address location="https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb12.asmx" />
      //   </wsdl:port>
      //   <wsdl:port name="LDBServiceSoap12" binding="tns:LDBServiceSoap12">
      //     <soap12:address location="https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb12.asmx" />
      //   </wsdl:port>
      // </wsdl:service>

      // </wsdl:definitions>
      final soap12Location =
          wsdl
              .xpath(
                "/wsdl:definitions/wsdl:service/wsdl:port/soap12:address/@location[1]",
              )
              .firstOrNull
              ?.value;

      if (soap12Location == null) {
        return StationData.error(
          "Unable to locate soap12 location:\n${wsdlResponse.body}",
        );
      }

      // <soap-env:Envelope
      // 	xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
      // 	<soap-env:Header>
      // 		<ns0:AccessToken
      // 			xmlns:ns0="http://thalesgroup.com/RTTI/2013-11-28/Token/types">
      // 			<ns0:TokenValue>e3d8b441-61aa-4ce8-9709-6872af719b2a</ns0:TokenValue>
      // 		</ns0:AccessToken>
      // 	</soap-env:Header>
      // 	<soap-env:Body>
      // 		<ns0:GetDepartureBoardRequest
      // 			xmlns:ns0="http://thalesgroup.com/RTTI/2021-11-01/ldb/">
      // 			<ns0:numRows>30</ns0:numRows>
      // 			<ns0:crs>KGX</ns0:crs>
      // 		</ns0:GetDepartureBoardRequest>
      // 	</soap-env:Body>
      // </soap-env:Envelope>

      final builder = XmlBuilder();
      builder.processing('xml', "version='1.0' encoding='utf-8'");
      builder.element(
        "soap-env:Envelope",
        nest: () {
          builder.attribute(
            "xmlns:soap-env",
            "http://schemas.xmlsoap.org/soap/envelope/",
          );
          builder.element(
            "soap-env:Header",
            nest: () {
              builder.element(
                "ns0:AccessToken",
                nest: () {
                  builder.attribute(
                    "xmlns:ns0",
                    "http://thalesgroup.com/RTTI/2013-11-28/Token/types",
                  );
                  builder.element(
                    "ns0:TokenValue",
                    nest: () {
                      builder.text(API_KEY);
                    },
                  );
                },
              );
            },
          );
          builder.element(
            "soap-env:Body",
            nest: () {
              builder.element(
                "ns0:GetDepartureBoardRequest",
                nest: () {
                  builder.attribute(
                    "xmlns:ns0",
                    "http://thalesgroup.com/RTTI/2021-11-01/ldb/",
                  );
                  builder.element(
                    "ns0:numRows",
                    nest: () {
                      builder.text("30");
                    },
                  );
                  builder.element(
                    "ns0:crs",
                    nest: () {
                      builder.text(crs);
                    },
                  );
                },
              );
            },
          );
        },
      );

      final depboardRequestDoc = builder.buildDocument().toXmlString(
        pretty: false,
      );

      print(depboardRequestDoc);

      final soap12Response = await http.post(
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction":
              "\"http://thalesgroup.com/RTTI/2012-01-13/ldb/GetDepartureBoard\"",
        },
        Uri.parse(soap12Location),
        body: depboardRequestDoc,
      );

      return StationData.error("${soap12Response.body}");
    } catch (e) {
      return StationData.error("$e");
    }
  }
}
