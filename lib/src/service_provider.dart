part of aaf_rapid_connect;

//################################################################
/// AAF Rapid Connect service provider.
///
/// Represents an AAF Rapid Connect "Service Provider". That is, a Web
/// application that uses AAF Rapid Connect to perform user authentication.
///
/// Create an instance of this class to represent the Service Provider.
///
/// When the callback HTTP POST request is received by the Web application,
/// extract the "assertion" parameter from it and process the value with
/// the [authenticate] method.

class ServiceProvider {
  //----------------------------------------------------------------
  /// Constructor.
  ///
  /// The [issuer] is a string that identifies the expected issuer of the
  /// authentication tokens. Use "https://rapid.aaf.edu.au" for the production
  /// AAF Rapid Connect service and "https://rapid.test.aaf.edu.au" for the
  /// AAF's test service.
  ///
  /// The [audience] is a string that identifies the Service Provider (i.e. the
  /// Web application using AAF Rapid Connect to perform authentication).
  /// Note: the audience is not necessarily the same as the callback URL.
  ///
  /// The [secret] is the shared secret between AAF Rapid Connect
  /// and the Service Provider using it.
  ///
  /// The optional [redirectUrl] is where the Web browser should be
  /// redirected to, to authenticate the login. This value is not used
  /// by this implementation (since processing of the authentication token
  /// happens after the redirection has occurred), but is included
  /// as a member since this is a convenient place to record the value.
  ///
  /// The optional [name] is where the name of the Service Provider can be
  /// recorded. It is not used by this implementation.
  ///
  /// The _audience_, _shared secret_ and _name_ are values provided to AAF
  /// when the Service Provider was registered.
  /// The _redirect URL_ is the value that was issued by AAF when
  /// the service was successfully registered.
  ///
  /// The [allowedClockSkew] is a duration to allow for differences between
  /// the clocks. If not provided, a duration of zero is used (i.e. no allowance
  /// is made). Providing a sensible value is highly recommended, otherwise
  /// any clock skew could invalidate tokens.

  ServiceProvider(this.issuer, this.audience, this.secret,
      {this.redirectUrl, this.name, Duration? allowedClockSkew})
      : allowedClockSkew = allowedClockSkew ?? Duration();

  //================================================================
  // Static members

  static const _aafClaimName = 'https://aaf.edu.au/attributes';

  //================================================================
  // Members

  /// The issuer of the authentication tokens.
  final String issuer;

  /// The audience expected in the authentication tokens.
  final String audience;

  /// The shares secret used to sign the authentication tokens.
  final String secret;

  /// The URL to redirect to authenticate using AAF Rapid Connect.
  ///
  /// This member is provided as a convenient place to store the redirect URL.
  /// It is not used to process assertions.

  final String? redirectUrl;

  /// The name of the registered Service Provider.
  ///
  /// This member is provided as a convenient place to store the name of the
  /// Service Provider.
  /// It is not used to process assertions.

  final String? name;

  /// Amount of clock skew to allow for.
  ///
  /// This value is used when checking if the assertion has expired
  /// (i.e. current time is after the "exp" expiry time) or is not yet valid
  /// (i.e. current time is before the "nbf" time).

  Duration allowedClockSkew;

  /// Maximum lifetime of tokens that will be accepted.
  ///
  /// This value is used to prevent tokens with unusually long lifetimes
  /// from being accepted. For example, a token that expires in 10 years
  /// time is probably either a bug or something malicious.

  Duration maxAllowedLifetime = const Duration(minutes: 30);

  // Map for tracking all seen JTI values until they have expired.
  // This is used to prevent replay attacks.
  static final Map<String, Timer> _seenJti = <String, Timer>{};

  //================================================================
  // Methods

  //----------------------------------------------------------------
  /// Processes the "assertion" POST parameter received by the callback URL.
  ///
  /// Parses the [assertion] and validates it.
  ///
  /// If provided, the [currentTime] is used for validating time values in the
  /// token. Otherwise, the time when this method is invoked is used. The
  /// _currentTime_ is usually only used for testing.
  ///
  /// Returns a map if the assertion is acceptable.
  /// That is, if a login has successfully authenticated themselves.
  /// The map contains the attributes names to values, which can be used to
  /// create a [ClaimStandard] or [ClaimWithSharedToken].
  ///
  /// Throws a subclass of the [AafException] exception if
  /// the assertion is not acceptable. To discover why an assertion was
  /// rejected, examine the exception or set the [loggers] to log more
  /// details.

  Map<String, String> authenticate(String assertion, {DateTime? currentTime}) {
    try {
      if (assertion.isEmpty) {
        throw BadJwt('POST missing "assertion"');
      }

      _logAssertion.finest('assertion: $assertion');

      // Verify the JWT.
      //
      // Note: custom headerCheck provided, since AAF Rapid Connect sets
      // the 'typ' to 'JsonWebToken', instead of the 'JWT' (the default expected
      // by jaguar_jwt.
      final cs = verifyJwtHS256Signature(assertion, secret,
          defaultIatExp: false, headerCheck: (h) {
        _logJwt.finest('header=$h');

        final dynamic typ = h['typ']; // get the value of the "typ" header

        if (typ is String) {
          // The "typ" header has a string value, which is the expected type
          if (typ != 'JsonWebToken' && typ != 'JWT') {
            return false; // reject: value is not one of the expected values
          }
        } else if (typ != null) {
          // The "typ" header exists, but value is (strangely) not a string
          return false; // reject: unexpected value type for 'typ'
        }

        // There is no "typ" header, or it exists and has an expected value
        return true; // header is ok
      });
      _logJwt.finer('body=$cs');

      final when = (currentTime ?? DateTime.now()).toUtc();
      try {
        cs.validate(
            issuer: issuer,
            audience: audience,
            allowedClockSkew: allowedClockSkew,
            currentTime: when);
      } on JwtException catch (e) {
        // Extra information that might be useful for debugging failures

        switch (e) {
          case JwtException.tokenExpired:
            _logJwt.fine('expired'
                ': checkedAt=$when'
                ', out by ${_fmtDur(when.difference(cs.expiry!))}'
                ' > skew=${_fmtDur(allowedClockSkew)}');
            break;
          case JwtException.tokenNotYetAccepted:
            _logJwt.fine('notYetAccepted'
                ': checkedAt=$when'
                ', out by ${_fmtDur(cs.notBefore!.difference(when))}'
                ' > skew=${_fmtDur(allowedClockSkew)}');
            break;
          case JwtException.tokenNotYetIssued:
            // Note: jaguar_jwt 3.0.0 does not detect this situation, so this
            // exception never occurs.
            //
            // This need to be confirmed, but the JWT specification might be
            // silent on whether this situation is an error or not.
            //_logJwt.fine('notYetIssued'
            //    ': checkedAt=$when'
            //    ', out by ${_fmtDur(cs.issuedAt!.difference(when))}'
            //    ' ? skew=${_fmtDur(allowedClockSkew)}');
            break;
          case JwtException.audienceNotAllowed:
            _logJwt.fine('audienceNotAllowed: expecting "$audience"');
            break;
          case JwtException.incorrectIssuer:
            _logJwt.fine('incorrectIssuer: expecting "$issuer"');
            break;
        }

        rethrow;
      }

      // JWT ID

      final jwtID = cs.jwtId;
      if (jwtID == null) {
        throw BadJwt('Missing JWT ID');
      }
      if (jwtID.isEmpty) {
        throw BadJwt('Blank JWT ID');
      }

      if (_seenJti.containsKey(jwtID)) {
        throw BadJwt('JWT ID not unique'); // replay attack?
      }

      // Record JWT ID as seen

      final expiry = cs.expiry;
      if (expiry == null) {
        throw BadJwt('Missing expiry');
      }

      final durationToLive = expiry.difference(DateTime.now());
      if (maxAllowedLifetime < durationToLive) {
        // Unrealistic expiry time: reject long lived token
        throw BadJwt('TTL is too long');
      }

      // This timer will remove the JWT ID entry, once it has reached its
      // expiry time. This is to prevent the list from growing forever.
      // Although it means the uniqueness check is not complete, since it
      // won't check any JWT ID values beyond the lifetime of the JWTs.
      _seenJti[jwtID] = Timer(durationToLive, () {
        _seenJti.remove(jwtID);
      });

      // Type

      if (!cs.containsKey('typ') || cs['typ'] != 'authnresponse') {
        throw BadAafClaim('bad typ');
      }

      // Check "sub" exists and has a non-blank value

      // Make sure the AAF entry has a "sub"

      if (cs.subject == null) {
        throw BadAafClaim('sub missing');
      }
      if (cs.subject!.isEmpty) {
        throw BadAafClaim('sub is empty string');
      }
      if (cs.subject!.trim().isEmpty) {
        throw BadAafClaim('sub is all whitespace');
      }

      // Create the implementation-independent AafAttributes and populate it

      if (!cs.containsKey(_aafClaimName)) {
        throw BadAafClaim('missing AAF claims');
      }
      final dynamic aafClaims = cs[_aafClaimName];
      if (aafClaims is Map) {
        final aafAttr = <String, String>{}; // the result

        for (final k in aafClaims.keys) {
          if (k is String) {
            final Object? v = aafClaims[k];

            if (v is String) {
              final trimmedValue = v.trim();
              if (trimmedValue.isNotEmpty) {
                aafAttr[k] = trimmedValue; // record the value
              } else {
                // Treat attributes with empty strings as not present.
                // The edupersonorcid is often an empty string.
                // In the past some IdPs used an empty string for the
                // edupersonprincipalname identifier.
                _logJwt.finest('blank string ignored: $k');
              }
            } else {
              throw BadAafClaim('non-string value: $k');
            }
          } else {
            throw BadAafClaim('non-string key');
          }
        }

        // Since this is AAF Rapid Connect, the 'edupersontargetdid' must always
        // be present and must have the same value as the 'sub'.

        const targetName = ClaimStandard._attrEdupersontargetedid;
        final targetId = aafAttr[targetName];
        if (targetId == null) {
          throw BadAafClaim('$targetName missing');
        }
        if (cs.subject != targetId) {
          throw BadAafClaim('$targetName != sub');
        }

        _logAuthenticate.fine('success: ${aafAttr[ClaimStandard._attrMail]}');

        return aafAttr; // success: return result

      } else if (aafClaims == null) {
        throw BadAafClaim('AAF claims missing from JWT');
      } else {
        throw BadAafClaim('AAF claims not a JSON object');
      }
    } on AafException catch (e) {
      // High level exception thrown by above code
      _logAuthenticate.fine('invalid assertion: $e');
      rethrow;
    } on JwtException catch (e) {
      _logAuthenticate.fine('invalid JWT: $e');
      throw BadJwt(e.toString());
    } on Exception catch (e) {
      _logAuthenticate.fine('unexpected exception (${e.runtimeType}): $e');
      throw BadJwt('unexpected exception ${e.runtimeType}: $e');
    }
  }

  /// Compact string representation of a duration.
  ///
  /// This produces a short, and arguably more easily understood, representation
  /// of a [Duration].
  ///
  /// For example, 1d, 1h, 1h30m, 10s, 1h5.2s.

  static String _fmtDur(Duration? period) {
    if (period == null) {
      return 'none';
    }

    final buf = StringBuffer();

    final days = period.inDays;
    final hours = period.inHours % Duration.hoursPerDay;
    final min = period.inMinutes % Duration.minutesPerHour;
    final sec = period.inSeconds % Duration.secondsPerMinute;
    final microseconds = period.inMicroseconds % Duration.microsecondsPerSecond;

    if (0 < days) {
      buf.write('${days}d');
    }

    if (hours != 0 || min != 0 || sec != 0 || microseconds != 0) {
      if (0 < hours || buf.isNotEmpty) {
        buf.write('${hours}h');
      }

      if (min != 0 || sec != 0 || microseconds != 0) {
        if (0 < min || buf.isNotEmpty) {
          buf.write('${min}m');
        }

        if (sec != 0 || microseconds != 0) {
          buf.write(sec);

          if (0 < microseconds) {
            buf.write('.');

            var str = microseconds.toString().padLeft(6, '0');
            while (str.endsWith('0')) {
              str = str.substring(0, str.length - 1);
            }
            buf.write(str);
          }

          buf.write('s');
        }
      }
    }

    return (buf.isNotEmpty) ? buf.toString() : '0s';
  }

  //----------------------------------------------------------------
  /// Causes all AAF Rapid Connect tokens to be forgotten.
  ///
  /// The previously seen tokens are tracked to detect replay attacks, where
  /// a malicious client resends a previously sent token. Timers are used
  /// to automatically discard them, after a suitable time has passed.
  /// But this method can be used to immediately discard them all.
  ///
  /// This method is normally only invoked when shutting down the program.
  /// Since a program might not cleanly finish if there are Timers still
  /// running.
  ///
  /// Note: this is a static method, since tokens are tracked independently of
  /// which _ServiceProvider_ they were processed by. But usually a Web
  /// application would only have one _ServiceProvider_.

  static void reset() {
    var num = 0;

    while (_seenJti.isNotEmpty) {
      final anyKey = _seenJti.keys.first;
      final theAssociatedTimer = _seenJti.remove(anyKey)!;
      theAssociatedTimer.cancel();
      num++;
    }

    _logJwt.finest('reset: $num JTI values forgotten');
  }
}
