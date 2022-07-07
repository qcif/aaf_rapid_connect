part of aaf_rapid_connect;

//################################################################
/// Base class for exceptions used by the AAF Rapid Connect library.

abstract class AafException implements Exception {
  /// Constructor
  AafException(this._message);

  final String _message;

  @override
  String toString() => _message;
}

/// Exception thrown if the JWT is bad.

class BadJwt extends AafException {
  /// Constructor
  BadJwt(String details) : super(details);
}

/// Exception thrown if the claim set is bad.

class BadAafClaim extends AafException {
  /// Constructor
  BadAafClaim(String details) : super('Bad AAF claim: $details');
}
