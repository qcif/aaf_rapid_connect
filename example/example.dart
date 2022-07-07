// Example

import 'dart:io';
import 'package:woomera/woomera.dart';

import 'package:aaf_rapid_connect/aaf_rapid_connect.dart';

//################################################################
// Constants

const port = 8080;

// Details about this Service Provider

const name = 'Test SP';
const callbackUrlPath = '/auth/aaf'; // POST handler: implemented by this server

const issuer = 'https://rapid.test.aaf.edu.au'; // defined by AAF
const audience = 'https://service-provider.example.com'; // provided to reg.
const secret = 'abcdefghijklmnopqrstuvwxyz012345'; // provided to reg.

// Redirect URL is issued by AAF after registration.
const redirectUrl =
    'https://rapid.test.aaf.edu.au/jwt/authnrequest/auresearch/...';

/*
// For testing with the QCIF's Rapid Connect Test Harness
const redirectUrl2 =
    'http://localhost:18080/rapidAAF/idp/?'
    'iss=https%3A%2F%2Frapid.test.aaf.edu.au&'
    'aud=https%3A%2F%2Fservice-provider.example.com&'
    'secret=abcdefghijklmnopqrstuvwxyz012345&'
    'callback=http%3A%2F%2Flocalhost%3A8080%2Fauth%2Faaf';
*/

//################################################################
// There are three steps to implement a Service Provider.

// 1. Use the details from the registration.

ServiceProvider sp = sp = ServiceProvider(issuer, audience, secret,
    name: name,
    redirectUrl: redirectUrl,
    allowedClockSkew: Duration(minutes: 2));

// 2. Redirect the browser to the redirect URL, when requiring authentication.

Future<Response> handleLoginPage(Request req) async {
  return ResponseBuffered(ContentType.html)
    ..status = HttpStatus.ok
    ..write('''
<html lang="en">
  <head>
    <title>Example Service Provider</title>
  </head>
  <body>
    <h1>Example Service Provider</h1>

    <p><a href="${HEsc.attr(sp.redirectUrl)}">Sign in with AAF</a></p>
  </body>
</html>
''');
}

// 3. Handle the the "assertion" parameter in the callback HTTP POST request.

Future<Response> handleAafCallback(Request req) async {
  var assertion = req.postParams!['assertion'];
  print('Assertion: $assertion');

  try {
    final attrs = ClaimStandard(sp.authenticate(assertion));
    return _successful(attrs);
  } on AafException catch (e) {
    print('Assertion rejected: $e'); // For more details use logging.

    // For security, do not reveal to client why it failed.
    return _failed('Assertion was not valid.');
  }
}

Response _successful(ClaimStandard attr) {
  final resp = ResponseBuffered(ContentType.html)
    ..status = HttpStatus.ok
    ..write('''
<html lang="en">
<head><title>Successful</title></head>
<body>
  <h1>Sign in successful</h1>
  <table>
''');

  for (final k in attr.attributes.keys) {
    final v = attr.attributes[k];
    resp.write('<tr><th>${HEsc.text(k)}</th><td>${HEsc.text(v)}</td>\n');
  }

  resp.write('''
  </table>
  <p><a href="/">Home</a></p>
</body>
</html>
''');

  return resp;
}

Response _failed(String message) {
  return ResponseBuffered(ContentType.html)
    ..status = HttpStatus.badRequest
    ..write('''
<html lang="en">
<head><title>Failed</title></head>
<body>
  <h1>Failed</h1>
  <p>${HEsc.text(message)}</p>
  <p><a href="/">Home</a></p>
</body>
</html>
''');
}

//################################################################

void main() async {
  final server = Server()
    ..bindAddress = InternetAddress.loopbackIPv4
    ..bindPort = port;

  server.pipelines.first
    ..get('~/', handleLoginPage)
    ..post('~/auth/aaf', handleAafCallback);

  print('Listening on ${server.bindAddress} port ${server.bindPort}');

  await server.run();
}
