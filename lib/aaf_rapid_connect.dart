/// Processing identity assertions issued by the _AAF Rapid Connect_ service.
///
/// To use this library, create an instance of [ServiceProvider] using
/// the information from the registration of the Service Provider.
///
/// When the AAF Rapid Connect POST callback receives an identity
/// assertion, process it using the [ServiceProvider.authenticate]
/// method. If the identity assertion is accepted, it will return an
/// instance of [AafAttributes] containing the details extracted
/// from the assertion. Otherwise, one of the subclasses of
/// [AafException] will be thrown.
///
/// For more information about AAF Rapid Connect, please see the
/// _AAF Rapid Connect_ developer's guide at
/// <https://rapid.aaf.edu.au/developers>.

library aaf_rapid_connect;

//----------------------------------------------------------------

import 'dart:async';

import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:logging/logging.dart';

//----------------------------------------------------------------

part 'src/aaf_attributes.dart';
part 'src/exceptions.dart';
part 'src/logging.dart';
part 'src/service_provider.dart';
