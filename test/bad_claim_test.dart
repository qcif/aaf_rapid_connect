import 'package:aaf_rapid_connect/aaf_rapid_connect.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:test/test.dart';

//----------------------------------------------------------------

const issuer = 'https://rapid.test.aaf.edu.au'; // defined by AAF
const audience = 'https://service-provider.example.com'; // provided to reg.
const secret = 'abcdefghijklmnopqrstuvwxyz012345'; // provided to reg.

final sp = ServiceProvider(issuer, audience, secret);

//----------------------------------------------------------------

void _validByDefault(
    {String? jwtId = 'unique-id',
    String? subject = 'subject',
    Duration expiryDuration = const Duration(seconds: 120)}) {
  final when = DateTime.now();

  final claimSet = JwtClaim(
      issuer: issuer,
      subject: subject,
      audience: [audience],
      expiry: when.add(expiryDuration),
      notBefore: when,
      issuedAt: when,
      jwtId: jwtId,
      otherClaims: {
        'typ': 'authnresponse',
        'https://aaf.edu.au/attributes': {'edupersontargetedid': subject}
      });

  final assertion = issueJwtHS256(claimSet, secret);

  ServiceProvider.reset();
  sp.authenticate(assertion);
}

//----------------

void _test(String name, void Function() x, String expectedError) {
  test(name, () {
    try {
      x();
    } on AafException catch (e) {
      expect(e.toString(), equals(expectedError));
    }
  });
}

//----------------

void badClaim() {
  group('bad claim', () {
    test('works by default', _validByDefault);

    _test(
        'Missing JWT ID', () => _validByDefault(jwtId: null), 'Missing JWT ID');
    _test('Missing JWT ID', () => _validByDefault(jwtId: ''), 'Blank JWT ID');
    _test('Missing sub', () => _validByDefault(subject: null),
        'Bad AAF claim: sub missing');
    _test('Empty sub', () => _validByDefault(subject: ''),
        'Bad AAF claim: sub is empty string');
    _test('Blank sub', () => _validByDefault(subject: ' '),
        'Bad AAF claim: sub is all whitespace');
    // Note: cannot omit 'exp', since JwtClaim always puts one in.
    _test(
        'Expiry is too large to be sensible',
        () => _validByDefault(expiryDuration: const Duration(minutes: 31)),
        'TTL is too long');
  });
}

//----------------------------------------------------------------

void badAafClaim() {
  const subjectValue = 'foo:bar:baz';

  final testCases = <List<dynamic>>[
    ['no typ', null, 'Bad AAF claim: bad typ'],
    [
      'wrong typ',
      {'typ': 'not-authn-response'},
      'Bad AAF claim: bad typ'
    ],
    [
      'missing AAF claim',
      {'typ': 'authnresponse'},
      'Bad AAF claim: missing AAF claims'
    ],
    [
      'null AAF claim',
      {'typ': 'authnresponse', 'https://aaf.edu.au/attributes': null},
      'Bad AAF claim: AAF claims missing from JWT'
    ],
    [
      'AAF claim not JSON object',
      {'typ': 'authnresponse', 'https://aaf.edu.au/attributes': 'not object'},
      'Bad AAF claim: AAF claims not a JSON object'
    ],
    [
      'AAF claim missing eduPersonTargedId',
      {'typ': 'authnresponse', 'https://aaf.edu.au/attributes': {}},
      'Bad AAF claim: edupersontargetedid missing'
    ],
    [
      'AAF claim non-string eduPersonTargedId',
      {
        'typ': 'authnresponse',
        'https://aaf.edu.au/attributes': {'edupersontargetedid': 42}
      },
      'Bad AAF claim: non-string value: edupersontargetedid'
    ],
    [
      'eduPersonTargedId does not match sub',
      {
        'typ': 'authnresponse',
        'https://aaf.edu.au/attributes': {'edupersontargetedid': 'not-sub'}
      },
      'Bad AAF claim: edupersontargetedid != sub'
    ],
  ];

  for (final testCase in testCases) {
    final name = testCase[0];
    final otherClaims = testCase[1];
    final expectedError = testCase[2];

    test(name, () {
      // Create a correctly signed JWT from the test case.
      // This is necessary for testing bad claims, since the signature is
      // checked first, and any bad claims won't be detected at all if the
      // assertion was rejected because of the signature.

      final when = DateTime.now();

      final claimSet = JwtClaim(
          issuer: issuer,
          subject: subjectValue,
          audience: [audience],
          expiry: when.add(const Duration(seconds: 120)),
          notBefore: when,
          issuedAt: when,
          jwtId: 'unique-id',
          otherClaims: otherClaims);

      final assertion = issueJwtHS256(claimSet, secret);

      try {
        ServiceProvider.reset();
        sp.authenticate(assertion);
        fail('did not cause an error');
      } on AafException catch (e) {
        expect(e.toString(), equals(expectedError));
      }
    });
  }
}

//----------------------------------------------------------------

void main() {
  badClaim();
  badAafClaim();
}
