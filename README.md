# Australian Access Federation Rapid Connect

A Dart package for implementing AAF Rapid Connect Service Providers.

The Australian Access Federation (AAF) provides a federated
authentication service.

A _Service Provider_ (SP) is a Web application that requires its users
to be authenticated. The users must be people who have logins at an
organisation that subscribes to the Australian Access Federation:
namely all Australian universities and some research organisations.

The "AAF Rapid Connect" protocol allows Service Providers to use AAF
for authentication. It is a simpler alternative to using SAML. It is a
proprietary protocol that existed before OpenID Connect had been
defined.

To develop a Web application using AAF Rapid Connect to perform
authentication:

1. Write the Web application so it expects a HTTP POST request from
   the AAF Rapid Connect service. This is the "callback URL" and it
   gets invoked after the user has been successfully authenticated.

2. Deploy the Web application, secured using TLS (i.e. the callback
   URL must be a HTTPS URL).

3. Register the deployed Web application with AAF.  The callback URL
   and other information must be provided to AAF to register it.

4. When the Web application wants to authenticate a user, redirect
   their Web browser to the "redirect URL", which is issued by AAF
   after registration.

5. If the user is successfully authenticated, the Web application will
   receive a HTTP POST request on the callback URL with an "assertion"
   parameter.

This package provides a library for processing that "assertion"
parameter.  The Web application uses it to parse, validate and extract
information from the assertion.


## Example

The Web application should create a `ServiceProvider` object, using
the values from the AAF Rapid Connect registration.

```dart
import 'package:aaf_rapid_connect/aaf_rapid_connect.dart';

ServiceProvider sp; // global

void initialize(String issuer, String audience, String secret, String redirect) {

  sp = ServiceProvider(issuer, audience, secret, redirect,
        allowedClockSkew: const Duration(minutes: 2));
}

```

The _issuer_ will always be "https://rapid.aaf.edu.au" when using the
AAF production environment, and "https://rapid.test.aaf.edu.au" when
using the AAF test environment.

The _audience_ is the URL that was provided to the service
registration. It is described as "the primary URL of your
application", but it is just a URL used as a unique identifier.

The _secret_ is the value that was provided to the service
registration.

The _redirect_ is the redirect URL that was issued by the service
registration process.

An optional _allowed clock skew_ duration can be provided. It is used
during validation of the assertion.

### Redirecting

When the user wants to authenticate, send their Web brower to the
redirect URL.

The _ServiceProvider_ object contains a copy of the redirect URL.

```dart
  final url = sp.redirect;

  response.write('<a href="${escapeAttribute(url)}">Sign in with AAF</a>');
```

### Handling the callback HTTP POST request

When the callback is invoked, extract the "assertion" POST parameter
and use the _ServiceProvider_ object to process it. The `authenticate`
method parses, checks and validates it.

An _AafException_ is thrown if the assertion is invalid or not
trusted.

If successful, the attributes in the claim as a Map<String,String>.
That can be used directly, or used to create create a _ClaimStandard_
or _ClaimWithSharedToken_, which define convenient getters for getting
the known attributes, and also methods to identify any extra
attributes which are not known.

```dart
Future<Response> handleCallback(Request req) async {
  // Extract string "assertion" parameter from HTTP POST request
  final assertionStr = req.postParams!['assertion'];

  try {
    final m = sp.authenticate(assertionStr);
    
    final claim = ClaimStandard(m);

    // Assertion accepted
    //
    // aafAttributes identifies the user and has properties about them

    print(claim.mail);
    print(claim.givenname);
    print(claim.surname);
    print(claim.cn);
    ...
    

  } on AafException catch (e) {
    // Assertion rejected
    ...
  }
}
```



## More information

* [AAF Rapid Connect - documentation](https://rapid.test.aaf.edu.au/developers)
* [AAF Rapid Connect - test](https://rapid.test.aaf.edu.au/)
* [AAF Rapid Connect - production](https://rapid.aaf.edu.au/)

## Features and bugs

Please report bugs and feature requests on the [issue
tracker](https://github.com/qcif/aaf_rapid_connect/issues).

