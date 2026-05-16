import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Returns an HTTP client that accepts self-signed certificates.
// Used for home-lab services on private networks where self-signed
// certs are the norm.
http.Client buildTrustingClient() {
  final inner = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;
  return IOClient(inner);
}
