part of aaf_rapid_connect;

//----------------------------------------------------------------

Logger _logAssertion = Logger('aaf_rapid_connect.assertion');
Logger _logJwt = Logger('aaf_rapid_connect.jwt');
Logger _logAuthenticate = Logger('aaf_rapid_connect.authenticate');

/// All the loggers used in the _aaf_rapid_connect_ library.
///
/// The library uses these loggers:
///
/// - `aaf_rapid_connect.assertion` for the encoded assertion.
/// - `aaf_rapid_connect.jwt` for the assertion decoded into a JWT.
/// - `aaf_rapid_connect.authenticate` for the result of processing the JWT.

final loggers = [
  _logAssertion,
  _logJwt,
  _logAuthenticate,
];
