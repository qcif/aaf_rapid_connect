import 'dart:convert';

import 'package:aaf_rapid_connect/aaf_rapid_connect.dart';
import 'package:test/test.dart';

//----------------------------------------------------------------

const issuer = 'https://rapid.test.aaf.edu.au'; // defined by AAF
const audience = 'https://service-provider.example.com'; // provided to reg.
const secret = 'abcdefghijklmnopqrstuvwxyz012345'; // provided to reg.

final sp = ServiceProvider(issuer, audience, secret);

//----------------------------------------------------------------

void loggerTests() {
  test('logger', () {
    for (final x in loggers) {
      expect(x.fullName, startsWith('aaf_rapid_connect.'));
    }
  });
}

//----------------------------------------------------------------

void jwtSyntaxTest() {
  test('invalid JWT syntax', () {
    const samples = {
      '': 'POST missing "assertion"',
      ' ': 'Invalid JWT token!',
      'onlyOnePart': 'Invalid JWT token!',
      'onlyTwoParts.secondPart': 'Invalid JWT token!',
      'notBase64.notBase64.notBase64': 'Invalid JWT token!',
      'e30K': 'Invalid JWT token!',
      'e30K.e30K': 'Invalid JWT token!',
      'e30K.e30K.e30K': 'JWT hash mismatch!'
    };

    for (final sample in samples.entries) {
      try {
        ServiceProvider.reset(); // discard any previously seen JWT IDs
        sp.authenticate(sample.key);
        fail('was not rejected: "${sample.key}"');
      } on BadJwt catch (e) {
        expect(e.toString(), equals(sample.value));
      }
    }
  });
}

//----------------------------------------------------------------

void nbfSameAsIss() {
  group('nbf = iss:', () {
    final timeIssued = DateTime.utc(2019, 12, 25, 17, 30); // 1577295000
    // print('issued: ${timeIssued.millisecondsSinceEpoch ~/ 1000}');

    // This example has a not-valid-before (nbf) the same as the time issued.
    // This example has an expiry (exp) 120 seconds after the time issued.

    const testAssertion = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJhdWQiOlsiaHR0cHM6Ly9zZXJ2aWNlLXByb3ZpZGVyLmV4YW1wbGUuY29tIl0s'
        'ImV4cCI6MTU3NzI5NTEyMCwiaHR0cHM6Ly9hYWYuZWR1LmF1L2F0dHJpYnV0ZXMi'
        'OnsiYXVlZHVwZXJzb25zaGFyZWR0b2tlbiI6Im5oUnFoQ3JlZmJhMV9HR2FiY2Rl'
        'ZmdoaWprbCIsImNuIjoiR2FuZGFsZiB0aGUgR3JleSIsImRpc3BsYXluYW1lIjoi'
        'RHIgR2FuZGFsZiB0aGUgR3JleSIsImVkdXBlcnNvbnByaW5jaXBhbG5hbWUiOiJn'
        'YW5kYWxmQGV4YW1wbGUuY29tIiwiZWR1cGVyc29uc2NvcGVkYWZmaWxpYXRpb24i'
        'OiJzdGFmZkBleGFtcGxlLmNvbSIsImVkdXBlcnNvbnRhcmdldGVkaWQiOiJodHRw'
        'czovL3JhcGlkLnRlc3QuYWFmLmVkdS5hdSFodHRwczovL3NlcnZpY2UtcHJvdmlk'
        'ZXIuZXhhbXBsZS5jb20hMDAwYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoiLCJn'
        'aXZlbm5hbWUiOiJHYW5kYWxmIiwibWFpbCI6ImdhbmRhbGZAZXhhbXBsZS5jb20i'
        'LCJzdXJuYW1lIjoiR3JleSJ9LCJpYXQiOjE1NzcyOTUwMDAsImlzcyI6Imh0dHBz'
        'Oi8vcmFwaWQudGVzdC5hYWYuZWR1LmF1IiwianRpIjoieFlzWDFVNE9UM0V2M1JI'
        'ZndpQnYzOVZXTVl6OWM4bkwiLCJuYmYiOjE1NzcyOTUwMDAsInN1YiI6Imh0dHBz'
        'Oi8vcmFwaWQudGVzdC5hYWYuZWR1LmF1IWh0dHBzOi8vc2VydmljZS1wcm92aWRl'
        'ci5leGFtcGxlLmNvbSEwMDBhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5eiIsInR5'
        'cCI6ImF1dGhucmVzcG9uc2UifQ.'
        'TyO1CWEHuhhVOQ_2CJ1g2wnQNlWlI4s4FsJcM2xof1o';

    group('valid', () {
      ServiceProvider.reset(); // discard any previously seen JWT IDs
      final attrs = sp.authenticate(testAssertion, currentTime: timeIssued);

      // Treat the attributes as a claim without any profile (i.e. without
      // any known attributes
      test('Base claim', () {
        final c = Claim(attrs);

        expect(c.extra.isNotEmpty, isTrue);
        expect(c.extra.length, equals(attrs.length));
      });

      // Treat the attributes as a claim with just the standard profile.
      // Note: the extra auedupersonsharedtoken attribute will be considered
      // an extra/unknown attribute.

      test('Standard claim', () {
        expect(ClaimStandard.known.length, equals(9));

        final c = ClaimStandard(attrs);

        // Shared Token is not a part of the standard profile, so is treated
        // as an extra attribute.

        expect(c.extra.length, equals(1));
        expect(c.extra.first, equals('auedupersonsharedtoken'));
      });

      // Treat the attributes as a claim with the standard plus AAF Shared Token
      // profile.

      test('Claim with Shared Token', () {
        expect(ClaimWithSharedToken.known.length, equals(10));

        final c = ClaimWithSharedToken(attrs);

        // Shared token is a part of profile, so there are no extra attributes.

        expect(c.extra.isEmpty, isTrue); // all attributes are known

        // Note: example does not have ORCID
        expect(
            c.attributes.length, equals(ClaimWithSharedToken.known.length - 1));

        // Getters all work

        expect(c.mail, equals('gandalf@example.com'));
        expect(c.givenname, equals('Gandalf'));
        expect(c.surname, equals('Grey'));
        expect(c.cn, equals('Gandalf the Grey'));
        expect(c.displayname, equals('Dr Gandalf the Grey'));
        expect(c.edupersonprincipalname, equals('gandalf@example.com'));
        expect(c.edupersonscopedaffiliation, equals('staff@example.com'));
        expect(c.edupersonorcid, isNull);
        expect(c.auedupersonsharedtoken, equals('nhRqhCrefba1_GGabcdefghijkl'));
        expect(
            c.edupersontargetedid,
            equals('https://rapid.test.aaf.edu.au!'
                'https://service-provider.example.com!'
                '000abcdefghijklmnopqrstuvwxyz'));
        expect(c.sub, equals(c.edupersontargetedid)); // sub is an alias

        // Can also access the values via the attributes member

        expect(c.attributes.containsKey('mail'), isTrue);
        expect(c.attributes.containsKey('something-else'), isFalse);
        expect(c.attributes['mail'], equals('gandalf@example.com'));
        expect(c.attributes['something-else'], isNull);
      });
    });

    test('clock skew is not allowed', () {
      // Note: iat, exp, nbf only have the resolution of 1 second.
      sp.allowedClockSkew = Duration.zero;

      final samples = {
        const Duration(days: -1): 'JWT token not yet accepted!',
        const Duration(hours: -1): 'JWT token not yet accepted!',
        const Duration(seconds: -1): 'JWT token not yet accepted!',
        Duration.zero: null, // valid if immediately received
        const Duration(seconds: 1): null, // still valid
        const Duration(seconds: 60): null, // still valid
        const Duration(seconds: 119): null, // still valid for up to 2 minutes
        const Duration(seconds: 120): 'JWT token expired!',
        const Duration(seconds: 121): 'JWT token expired!',
        const Duration(hours: 1): 'JWT token expired!',
        const Duration(days: 1, microseconds: 100): 'JWT token expired!',
      };

      for (final sample in samples.entries) {
        final offset = sample.key;
        try {
          ServiceProvider.reset(); // discard previously seen JWT IDs
          sp.authenticate(testAssertion, currentTime: timeIssued.add(offset));
          if (sample.value != null) {
            fail('Offset $offset from issued time: was not rejected: '
                ' was expecting "${sample.value}"');
          }
        } on AafException catch (e) {
          if (sample.value != null) {
            expect(e.toString(), equals(sample.value));
          } else {
            fail('Offset $offset from issued time: was rejected');
          }
        }
      }
    });

    test('clock skew is allowed', () {
      sp.allowedClockSkew = const Duration(seconds: 30);

      final samples = {
        const Duration(hours: -1): 'JWT token not yet accepted!',
        const Duration(seconds: -31): 'JWT token not yet accepted!',
        const Duration(seconds: -30):
            null, // issued time - 30 seconds clock skew
        const Duration(seconds: -29): null,
        Duration.zero: null,
        const Duration(seconds: 60): null,
        const Duration(seconds: 149):
            null, // 119 seconds + 30 seconds clock skew
        const Duration(seconds: 150): 'JWT token expired!',
        const Duration(seconds: 151): 'JWT token expired!',
        const Duration(hours: 1): 'JWT token expired!',
      };

      for (final sample in samples.entries) {
        final offset = sample.key;
        try {
          ServiceProvider.reset(); // discard previously seen JWT IDs
          sp.authenticate(testAssertion, currentTime: timeIssued.add(offset));
          if (sample.value != null) {
            fail('Offset $offset from issued time: was not rejected:'
                ' was expecting "${sample.value}"');
          }
        } on AafException catch (e) {
          if (sample.value != null) {
            expect(e.toString(), equals(sample.value));
          } else {
            fail('Offset $offset from issued time: was rejected');
          }
        }
      }
    });

    test('duplicate JWT ID detected', () {
      ServiceProvider.reset(); // discard any previously seen JWT IDs
      sp.authenticate(testAssertion, currentTime: timeIssued);
      try {
        // Another assertion with the same JWT ID (e.g. replay attack)
        sp.authenticate(testAssertion, currentTime: timeIssued);
        fail('duplicate JWT ID not detected');
      } on AafException catch (e) {
        expect(e.toString(), equals('JWT ID not unique'));
      }
    });

    test('wrong issuer/audience/signature', () {
      final testCases = {
        ServiceProvider('wrong-issuer', audience, secret): 'Incorrect issuer!',
        ServiceProvider(issuer, 'wrong-audience', secret):
            'Audience not allowed!',
        ServiceProvider(issuer, audience, 'wrong-secret'): 'JWT hash mismatch!',
      };

      for (final testCase in testCases.entries) {
        final candidateSp = testCase.key;
        final expectedError = testCase.value;

        try {
          candidateSp.authenticate(testAssertion, currentTime: timeIssued);
          fail('was not rejected: expecting "$expectedError"');
        } on AafException catch (e) {
          expect(e.toString(), equals(expectedError));
        }
      }
    });

    test('bad header', () {
      final parts = testAssertion.split('.');
      //print('Header: ${utf8.decode(base64Decode(parts.first))}');

      final testCases = {
        '{}': 'Invalid JWT token!',
        '{"typ":"JWT"}': 'Invalid JWT token!',
        '{"alg":"HS256"}': 'JWT hash mismatch!',
        '{"alg":"HS256","typ":"JWT"}': null, // correct
        '{"alg":"HS256","typ":"JWE"} ': 'Invalid JWT token!', // extra space
        '{"alg":"RS256","typ":"JWT"}': 'JWT hash mismatch!', // different alg
        '{"typ":"JWT","alg":"HS256"}': 'JWT hash mismatch!', // wrong order
      };

      for (final testCase in testCases.entries) {
        final badHeader = base64Encode(testCase.key.codeUnits);
        final expectedError = testCase.value;

        final badAssertion = [badHeader, parts[1], parts[2]].join('.');

        try {
          sp.authenticate(badAssertion, currentTime: timeIssued);
          if (expectedError != null) {
            fail('was not rejected:'
                ' expecting "$expectedError" for "${testCase.key}"');
          }
        } on AafException catch (e) {
          expect(e.toString(), equals(expectedError));
        }
      }
    });
  });
}

//----------------------------------------------------------------

void nbfAfterIss() {
  final timeIssued = DateTime.utc(2019, 12, 25, 17, 30); // 1577295000
  // print('issued: ${timeIssued.millisecondsSinceEpoch ~/ 1000}');

  // This example has a not-valid-before (nbf) 60 seconds after it was issued.
  //
  // The expiry (exp) 120 seconds after not-valid-before (i.e. 180 seconds
  // after it was issued).

  // This example also has extra unknown attributes.

  const testAssertion = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJhdWQiOlsiaHR0cHM6Ly9zZXJ2aWNlLXByb3ZpZGVyLmV4YW1wbGUuY29tIl0s'
      'ImV4cCI6MTU3NzI5NTE4MCwiaHR0cHM6Ly9hYWYuZWR1LmF1L2F0dHJpYnV0ZXMi'
      'OnsiYXVlZHVwZXJzb25zaGFyZWR0b2tlbiI6Im5oUnFoQ3JlZmJhMV9HR2FiY2Rl'
      'ZmdoaWprbCIsImNuIjoiR2FuZGFsZiB0aGUgR3JleSIsImRpc3BsYXluYW1lIjoi'
      'RHIgR2FuZGFsZiB0aGUgR3JleSIsImVkdXBlcnNvbnByaW5jaXBhbG5hbWUiOiJn'
      'YW5kYWxmQGV4YW1wbGUuY29tIiwiZWR1cGVyc29uc2NvcGVkYWZmaWxpYXRpb24i'
      'OiJzdGFmZkBleGFtcGxlLmNvbSIsImVkdXBlcnNvbnRhcmdldGVkaWQiOiJodHRw'
      'czovL3JhcGlkLnRlc3QuYWFmLmVkdS5hdSFodHRwczovL3NlcnZpY2UtcHJvdmlk'
      'ZXIuZXhhbXBsZS5jb20hMDAwYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoiLCJl'
      'eHRyYTEiOiJmb28iLCJleHRyYTIiOiJiYXIiLCJnaXZlbm5hbWUiOiJHYW5kYWxm'
      'IiwibWFpbCI6ImdhbmRhbGZAZXhhbXBsZS5jb20iLCJzdXJuYW1lIjoiR3JleSJ9'
      'LCJpYXQiOjE1NzcyOTUwMDAsImlzcyI6Imh0dHBzOi8vcmFwaWQudGVzdC5hYWYu'
      'ZWR1LmF1IiwianRpIjoiVDNidWVJSDFiT1N0YmhHQkRpM1lRRmtWSHp2eTlQcVQi'
      'LCJuYmYiOjE1NzcyOTUwNjAsInN1YiI6Imh0dHBzOi8vcmFwaWQudGVzdC5hYWYu'
      'ZWR1LmF1IWh0dHBzOi8vc2VydmljZS1wcm92aWRlci5leGFtcGxlLmNvbSEwMDBh'
      'YmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5eiIsInR5cCI6ImF1dGhucmVzcG9uc2Ui'
      'fQ.'
      'UvFq_u9twiLPriEF5J6-8Wdh8SYvpZ1KxB4GX9sANBM';

  test('iss < nbf:', () {
    // Note: iat, exp, nbf only have the resolution of 1 second.
    sp.allowedClockSkew = Duration.zero;

    final samples = {
      const Duration(hours: -1): 'JWT token not yet accepted!', // t <<< iss
      const Duration(seconds: -1): 'JWT token not yet accepted!', // t < iss
      Duration.zero: 'JWT token not yet accepted!', // iss = t < nbf
      const Duration(seconds: 1):
          'JWT token not yet accepted!', // iss < t < nbf
      const Duration(seconds: 59):
          'JWT token not yet accepted!', // iss < t < nbf
      const Duration(seconds: 60): null, // valid: t = nbf
      const Duration(seconds: 61): null, // valid: nbf < t < exp
      const Duration(seconds: 179): null, // valid: nbf < t < exp
      const Duration(seconds: 180): 'JWT token expired!', // t = exp
      const Duration(seconds: 181): 'JWT token expired!', // exp < t
      const Duration(hours: 1): 'JWT token expired!', // exp <<< t
    };

    for (final sample in samples.entries) {
      final offset = sample.key;
      try {
        ServiceProvider.reset(); // discard previously seen JWT IDs
        sp.authenticate(testAssertion, currentTime: timeIssued.add(offset));
        if (sample.value != null) {
          fail('Offset $offset from issued time: was not rejected:'
              ' was expecting "${sample.value}"');
        }
      } on AafException catch (e) {
        if (sample.value != null) {
          expect(e.toString(), equals(sample.value));
        } else {
          fail('Offset $offset from issued time: was rejected');
        }
      }
    }
  });

  test('extra attributes', () {
    final sp = ServiceProvider(issuer, audience, secret);
    final attr = ClaimWithSharedToken(sp.authenticate(testAssertion,
        currentTime: timeIssued.add(const Duration(seconds: 60))));

    // The underlying map of attributes has the extra values

    expect(attr.attributes.keys.contains('extra1'), isTrue);
    expect(attr.attributes.keys.contains('extra2'), isTrue);
    expect(attr.attributes['extra1'], equals('foo'));
    expect(attr.attributes['extra2'], equals('bar'));

    // The hasExtra and extraAttributes getters identifies the extra attributes
    expect(attr.extra, contains('extra1'));
    expect(attr.extra, contains('extra2'));
    expect(attr.extra.length, equals(2));
  });
}

//----------------------------------------------------------------

void nbfBeforeIss() {
  final timeIssued = DateTime.utc(2019, 12, 25, 17, 30); // 1577295000
  // print('issued: ${timeIssued.millisecondsSinceEpoch ~/ 1000}');

  // This example has a not-valid-before (nbf) 60 seconds before it was issued.
  //
  // The expiry (exp) is 120 seconds after not-valid-before
  // (i.e. 60 seconds after issued).

  const testAssertion = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJhdWQiOlsiaHR0cHM6Ly9zZXJ2aWNlLXByb3ZpZGVyLmV4YW1wbGUuY29tIl0s'
      'ImV4cCI6MTU3NzI5NTA2MCwiaHR0cHM6Ly9hYWYuZWR1LmF1L2F0dHJpYnV0ZXMi'
      'OnsiYXVlZHVwZXJzb25zaGFyZWR0b2tlbiI6Im5oUnFoQ3JlZmJhMV9HR2FiY2Rl'
      'ZmdoaWprbCIsImNuIjoiR2FuZGFsZiB0aGUgR3JleSIsImRpc3BsYXluYW1lIjoi'
      'RHIgR2FuZGFsZiB0aGUgR3JleSIsImVkdXBlcnNvbnByaW5jaXBhbG5hbWUiOiJn'
      'YW5kYWxmQGV4YW1wbGUuY29tIiwiZWR1cGVyc29uc2NvcGVkYWZmaWxpYXRpb24i'
      'OiJzdGFmZkBleGFtcGxlLmNvbSIsImVkdXBlcnNvbnRhcmdldGVkaWQiOiJodHRw'
      'czovL3JhcGlkLnRlc3QuYWFmLmVkdS5hdSFodHRwczovL3NlcnZpY2UtcHJvdmlk'
      'ZXIuZXhhbXBsZS5jb20hMDAwYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoiLCJn'
      'aXZlbm5hbWUiOiJHYW5kYWxmIiwibWFpbCI6ImdhbmRhbGZAZXhhbXBsZS5jb20i'
      'LCJzdXJuYW1lIjoiR3JleSJ9LCJpYXQiOjE1NzcyOTUwMDAsImlzcyI6Imh0dHBz'
      'Oi8vcmFwaWQudGVzdC5hYWYuZWR1LmF1IiwianRpIjoib0d0SnEzYWxEN0tGaDd5'
      'ZHZjeExRTWJETTlpM1JlOFEiLCJuYmYiOjE1NzcyOTQ5NDAsInN1YiI6Imh0dHBz'
      'Oi8vcmFwaWQudGVzdC5hYWYuZWR1LmF1IWh0dHBzOi8vc2VydmljZS1wcm92aWRl'
      'ci5leGFtcGxlLmNvbSEwMDBhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5eiIsInR5'
      'cCI6ImF1dGhucmVzcG9uc2UifQ.'
      '4QD1IgsLP-jHMzc4Ras-XxwfXmuFqbV1MBOoJuKpBEw';

  test('nbf < iss:', () {
    final sp = ServiceProvider(issuer, audience, secret)
      ..allowedClockSkew = Duration.zero;

    // nbf < iss < exp

    final samples = {
      const Duration(hours: -1):
          'JWT token not yet accepted!', // t <<< nbf < iss
      const Duration(seconds: -61):
          'JWT token not yet accepted!', // t < nbf < iss
      const Duration(seconds: -60): null, // t = nbf < iss
      const Duration(seconds: -59): null, // nbf < t < iss
      const Duration(seconds: -1): null, // nbf < t < iss
      Duration.zero: null, // nbf < t = iss
      const Duration(seconds: 1): null, // nbf < iss < t
      const Duration(seconds: 59): null, // valid: nbf < iss < t < exp
      const Duration(seconds: 60): 'JWT token expired!', // nbf < iss < t = exp
      const Duration(seconds: 61): 'JWT token expired!', // exp < t
      const Duration(hours: 1): 'JWT token expired!', // exp <<< t
    };

    for (final sample in samples.entries) {
      final offset = sample.key;
      try {
        ServiceProvider.reset(); // discard previously seen JWT IDs
        sp.authenticate(testAssertion, currentTime: timeIssued.add(offset));
        if (sample.value != null) {
          fail('Offset $offset from issued time: was not rejected:'
              ' was expecting "${sample.value}"');
        }
      } on AafException catch (e) {
        if (sample.value != null) {
          expect(e.toString(), equals(sample.value));
        } else {
          fail('Offset $offset from issued time: was rejected');
        }
      }
    }
  });
}

//----------------------------------------------------------------

void main() {
  loggerTests();
  jwtSyntaxTest();

  nbfSameAsIss(); // includes several other tests
  nbfAfterIss(); // includes extra attributes
  nbfBeforeIss();
}
