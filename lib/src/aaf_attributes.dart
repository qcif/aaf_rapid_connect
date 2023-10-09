part of aaf_rapid_connect;

//################################################################
/// Abstract base class for AAF Rapid Connect attributes.

class Claim {
  //================================================================
  // Constructors

  /// Constructor for a claim set.

  Claim(this.attributes);

  //================================================================
  // Members

  /// All the attributes and their values.

  final Map<String, String> attributes;

  //================================================================
  // Methods

  //----------------------------------------------------------------
  /// Names of the attributes which are not known.
  ///
  /// Returns a list of attribute names, which are not in the _knownAttributes_
  /// for the profile represented by the class.

  Iterable<String> get extra => attributes.keys;
}

//################################################################
/// Attributes for the standard profile of AAF Rapid Connect.

class ClaimStandard extends Claim {
  //================================================================
  // Constructors

  /// Constructor for a standard AAF Rapid Connect claim set.

  ClaimStandard(Map<String, String> m) : super(m);

  //================================================================
  // Constants

  static const _attrCn = 'cn';
  static const _attrMail = 'mail';
  static const _attrDisplayname = 'displayname';
  static const _attrEdupersontargetedid = 'edupersontargetedid';
  static const _attrScopedAffiliation = 'edupersonscopedaffiliation';
  static const _attrEdupersonprincipalname = 'edupersonprincipalname';
  static const _attrGivenname = 'givenname';
  static const _attrSurname = 'surname';
  static const _attrEdupersonorcid = 'edupersonorcid';

  /// Names of the attributes which are not known to this profile.
  ///
  /// This is a list that contains all of the attribute names from the
  /// standard profile, as defined by AAF Rapid Connect v1.10.1.

  static const List<String> known = [
    _attrCn,
    _attrMail,
    _attrDisplayname,
    _attrEdupersontargetedid,
    _attrScopedAffiliation,
    _attrEdupersonprincipalname,
    _attrGivenname,
    _attrSurname,
    _attrEdupersonorcid,
  ];

  //================================================================
  // Methods

  /// AAF Rapid Connect subject: unique identifier for the login account.
  ///
  /// An alias for the "edupersontargetedid" attribute.

  String? get sub => attributes[_attrEdupersontargetedid]; // alias

  /// Common name attribute
  ///
  /// Note: AAF Rapid Connect specifies this attribute "SHOULD" be available.
  /// That is, sometimes it is not provided.
  String? get cn => attributes[_attrCn];

  /// Mail attribute
  ///
  /// The mail should not be used as an identifier for the login account.
  /// It is possible for this value to change in subsequent logins by the same
  /// login account. It is extremely unlikely, but possible for two different
  /// login accounts to have the same mail value.
  ///
  /// Note: AAF Rapid Connect specifies this attribute "SHOULD" be available.
  /// That is, sometimes it is not provided.

  String? get mail => attributes[_attrMail];

  /// Display name attribute
  ///
  /// Note: AAF Rapid Connect specifies this attribute "SHOULD" be available.
  /// That is, sometimes it is not provided.
  String? get displayname => attributes[_attrDisplayname];

  /// Edu Person Targeted Id attribute
  ///
  /// Note: AAF Rapid Connect specifies this attribute "SHOULD" be available.
  /// That is, sometimes it is not provided.
  String? get edupersontargetedid => attributes[_attrEdupersontargetedid];

  /// Edu Person Scoped affiliation attribute
  ///
  /// Note: AAF Rapid Connect specifies this attribute "SHOULD" be available.
  /// That is, sometimes it is not provided.
  String? get edupersonscopedaffiliation => attributes[_attrScopedAffiliation];

  /// Edu Person Principal name (EPPN) attribute.
  ///
  /// Note: AAF Rapid Connect specifies this attribute "MAY" be available
  /// at the discretion of the user's Identity Provider.
  String? get edupersonprincipalname => attributes[_attrEdupersonprincipalname];

  /// Given name attribute
  ///
  /// Note: AAF Rapid Connect specifies this attribute "MAY" be available
  /// at the discretion of the user's Identity Provider.
  String? get givenname => attributes[_attrGivenname];

  /// Surname attribute
  ///
  /// Note: AAF Rapid Connect specifies this attribute "MAY" be available
  /// at the discretion of the user's Identity Provider.
  String? get surname => attributes[_attrSurname];

  /// Edu Person ORCID attribute
  ///
  /// Note: AAF Rapid Connect specifies this attribute "MAY" be available
  /// at the discretion of the user's Identity Provider.
  String? get edupersonorcid => attributes[_attrEdupersonorcid];

  //----------------------------------------------------------------

  @override
  Iterable<String> get extra =>
      attributes.keys.where((k) => !known.contains(k));
}

//################################################################
/// Attributes for the standard profile with the AAF Shared Token.

class ClaimWithSharedToken extends ClaimStandard {
  //================================================================
  // Constructors

  /// Constructor for a standard AAF Rapid Connect claim set plus shared token.

  ClaimWithSharedToken(Map<String, String> m) : super(m);

  //================================================================

  static const _attrAuedupersonsharedtoken = 'auedupersonsharedtoken';

  /// Names of the attributes which are not known to this profile.
  ///
  /// This is a list that contains all of the attribute names from the
  /// standard profile plus "auedupersonsharedtoken".

  static const List<String> known = [
    ...ClaimStandard.known,
    _attrAuedupersonsharedtoken,
  ];

  //================================================================
  // Methods

  //----------------------------------------------------------------
  /// AAF Shared Token.
  ///
  /// This attribute is not available in the standard AAF Rapid Connect.
  ///
  /// If possible, new code should use [edupersonprincipalname] instead of
  /// this attribute.

  String? get auedupersonsharedtoken => attributes[_attrAuedupersonsharedtoken];

  //----------------------------------------------------------------

  @override
  Iterable<String> get extra =>
      attributes.keys.where((k) => !known.contains(k));
}
