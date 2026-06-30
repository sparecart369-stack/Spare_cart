import 'package:spare_kart/core/validation/form_validators.dart';
import 'package:spare_kart/core/utils/operating_countries_helper.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _profileBaseSelect =
      'id, name, phone, positive_feedback_pct';
  static const _profileFullSelect =
      'id, name, phone, positive_feedback_pct, operating_countries, operates_globally';

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserProfile?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final row = await _fetchProfileRow(user.id);
    if (row == null) return null;

    final resolved = _resolveOperatingCountries(
      row: row,
      metadata: user.userMetadata,
    );

    // Back-fill profile when countries live only in auth metadata.
    if (_shouldSyncOperatingCountries(row, resolved)) {
      await _syncOperatingCountriesToProfile(user.id, resolved);
    }

    final bankRow = await _client
        .from('seller_bank_accounts')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    final listings = await _safeCount(
      () => _client
          .from('listings')
          .select('id')
          .eq('seller_id', user.id)
          .count(CountOption.exact),
    );

    final orders = await _safeCount(
      () => _client
          .from('orders')
          .select('id')
          .eq('buyer_id', user.id)
          .count(CountOption.exact),
    );

    SellerBankAccount? bankAccount;
    if (bankRow != null) {
      bankAccount = SellerBankAccount(
        upiId: bankRow['upi_id'] as String,
        bankName: bankRow['bank_name'] as String,
        accountNumber: bankRow['account_number'] as String,
        accountName: bankRow['account_name'] as String,
        ifscCode: bankRow['ifsc_code'] as String,
      );
    }

    return UserProfile(
      name: row['name'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      positiveFeedback: (row['positive_feedback_pct'] as num?)?.toInt() ?? 98,
      listings: listings,
      orders: orders,
      bankAccount: bankAccount,
      operatingCountries: resolved.countryCodes,
      operatesGlobally: resolved.operatesGlobally,
    );
  }

  Future<UserProfile> signUp({
    required String name,
    required String phone,
    required String password,
    required OperatingCountriesSelection operatingCountries,
  }) async {
    final normalizedPhone = FormValidators.normalizePhone(phone);
    final email = FormValidators.phoneToAuthEmail(phone);
    final normalizedCodes =
        OperatingCountriesHelper.normalizeCodes(operatingCountries.countryCodes);
    final countries = operatingCountries.copyWith(countryCodes: normalizedCodes);

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name.trim(),
        'phone': normalizedPhone,
        'operating_countries': normalizedCodes,
        'operates_globally': operatingCountries.operatesGlobally,
      },
    );

    if (response.user == null) {
      throw const AuthException('Sign up failed');
    }

    // Profile is auto-created by the DB trigger. Sync extra fields when we have a session.
    if (response.session != null) {
      try {
        await _ensureProfile(
          userId: response.user!.id,
          name: name.trim(),
          phone: normalizedPhone,
          operatingCountries: countries,
        );
      } on PostgrestException catch (e) {
        if (!_isIgnorableProfileSyncError(e)) rethrow;
      }
    }

    try {
      final profile = await fetchProfile();
      if (profile != null) return profile;
    } on PostgrestException catch (e) {
      if (!_isIgnorableProfileSyncError(e)) rethrow;
    }

    return UserProfile(
      name: name.trim(),
      phone: normalizedPhone,
      operatingCountries: normalizedCodes,
      operatesGlobally: operatingCountries.operatesGlobally,
    );
  }

  Future<UserProfile> signIn({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = FormValidators.normalizePhone(phone);
    final email = FormValidators.phoneToAuthEmail(phone);

    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = currentUser;
    if (user != null) {
      final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
      final countries = _operatingCountriesFromMetadata(meta);
      await _ensureProfile(
        userId: user.id,
        name: (meta['name'] as String?)?.trim() ?? '',
        phone: (meta['phone'] as String?) ?? normalizedPhone,
        operatingCountries: countries,
      );
    }

    final profile = await fetchProfile();
    if (profile == null) {
      throw const AuthException('Profile not found');
    }
    return profile;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<SellerBankAccount> saveBankAccount(SellerBankAccount account) async {
    final userId = currentUser?.id;
    if (userId == null) throw const AuthException('Not authenticated');

    final payload = {
      'user_id': userId,
      'upi_id': account.upiId,
      'bank_name': account.bankName,
      'account_number': account.accountNumber,
      'account_name': account.accountName,
      'ifsc_code': account.ifscCode,
    };

    await _client.from('seller_bank_accounts').upsert(payload);

    return account;
  }

  Future<OperatingCountriesSelection> updateOperatingCountries(
    OperatingCountriesSelection selection,
  ) async {
    final userId = currentUser?.id;
    if (userId == null) throw const AuthException('Not authenticated');

    final normalizedCodes =
        OperatingCountriesHelper.normalizeCodes(selection.countryCodes);

    try {
      await _client.from('profiles').update({
        'operating_countries': normalizedCodes,
        'operates_globally': selection.operatesGlobally,
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      if (_isMissingColumnError(e)) {
        throw const AuthException(
          'Operating countries are not enabled on the server yet. '
          'Apply the latest database migration and try again.',
        );
      }
      rethrow;
    }

    return selection.copyWith(countryCodes: normalizedCodes);
  }

  Future<void> _ensureProfile({
    required String userId,
    required String name,
    required String phone,
    OperatingCountriesSelection? operatingCountries,
  }) async {
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    final basePayload = <String, dynamic>{
      'name': name,
      'phone': phone,
    };

    if (existing != null) {
      await _upsertProfileFields(userId, basePayload, operatingCountries);
      return;
    }

    try {
      await _insertProfile(userId, basePayload, operatingCountries);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final createdByTrigger = await _client
            .from('profiles')
            .select('id')
            .eq('id', userId)
            .maybeSingle();
        if (createdByTrigger != null) {
          await _upsertProfileFields(userId, basePayload, operatingCountries);
          return;
        }
        throw const AuthException(
          'This phone number is already linked to an account. Try logging in instead.',
        );
      }
      rethrow;
    }

    final cart = await _client
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    if (cart == null) {
      try {
        await _client.from('carts').insert({'user_id': userId});
      } on PostgrestException catch (e) {
        if (!_isDuplicateProfileError(e)) rethrow;
      }
    }
  }

  Future<void> _upsertProfileFields(
    String userId,
    Map<String, dynamic> basePayload,
    OperatingCountriesSelection? operatingCountries,
  ) async {
    try {
      final payload = _withOperatingCountries(basePayload, operatingCountries);
      await _client.from('profiles').update(payload).eq('id', userId);
    } on PostgrestException catch (e) {
      if (_isMissingColumnError(e) && operatingCountries != null) {
        await _client.from('profiles').update(basePayload).eq('id', userId);
        return;
      }
      rethrow;
    }
  }

  Future<void> _insertProfile(
    String userId,
    Map<String, dynamic> basePayload,
    OperatingCountriesSelection? operatingCountries,
  ) async {
    try {
      final payload = {
        'id': userId,
        ..._withOperatingCountries(basePayload, operatingCountries),
      };
      await _client.from('profiles').insert(payload);
    } on PostgrestException catch (e) {
      if (_isMissingColumnError(e) && operatingCountries != null) {
        await _client.from('profiles').insert({
          'id': userId,
          ...basePayload,
        });
        return;
      }
      rethrow;
    }
  }

  Map<String, dynamic> _withOperatingCountries(
    Map<String, dynamic> base,
    OperatingCountriesSelection? operatingCountries,
  ) {
    if (operatingCountries == null) return base;
    return {
      ...base,
      'operating_countries':
          OperatingCountriesHelper.normalizeCodes(operatingCountries.countryCodes),
      'operates_globally': operatingCountries.operatesGlobally,
    };
  }

  Future<Map<String, dynamic>?> _fetchProfileRow(String userId) async {
    try {
      return await _client
          .from('profiles')
          .select(_profileFullSelect)
          .eq('id', userId)
          .maybeSingle();
    } on PostgrestException catch (e) {
      if (!_isMissingColumnError(e)) rethrow;
      return _client
          .from('profiles')
          .select(_profileBaseSelect)
          .eq('id', userId)
          .maybeSingle();
    }
  }

  bool _isMissingColumnError(PostgrestException e) {
    final message = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return e.code == '42703' ||
        e.code == 'PGRST204' ||
        message.contains('operating_countries') ||
        message.contains('operates_globally') ||
        message.contains('column') && message.contains('does not exist');
  }

  bool _isDuplicateProfileError(PostgrestException e) => e.code == '23505';

  bool _isIgnorableProfileSyncError(PostgrestException e) {
    if (_isMissingColumnError(e)) return true;
    final message = e.message.toLowerCase();
    return message.contains('permission denied') ||
        message.contains('row-level security');
  }

  Future<int> _safeCount(
    Future<PostgrestResponse> Function() query,
  ) async {
    try {
      final response = await query();
      return response.count;
    } catch (_) {
      return 0;
    }
  }

  List<String> _parseCountryCodes(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return OperatingCountriesHelper.normalizeCodes(
        value.map((e) => e.toString()),
      );
    }
    if (value is String && value.isNotEmpty) {
      final trimmed = value.replaceAll(RegExp(r'[{}"\s]'), '');
      if (trimmed.isEmpty) return const [];
      return OperatingCountriesHelper.normalizeCodes(trimmed.split(','));
    }
    return const [];
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  OperatingCountriesSelection? _operatingCountriesFromMetadata(
    Map<String, dynamic> meta,
  ) {
    final codes = _parseCountryCodes(meta['operating_countries']);
    final global = _parseBool(meta['operates_globally']);
    if (global || codes.isNotEmpty) {
      return OperatingCountriesSelection(
        countryCodes: codes,
        operatesGlobally: global,
      );
    }
    return null;
  }

  OperatingCountriesSelection _resolveOperatingCountries({
    required Map<String, dynamic> row,
    required Map<String, dynamic>? metadata,
  }) {
    var codes = _parseCountryCodes(row['operating_countries']);
    var global = _parseBool(row['operates_globally']);

    if (!global && codes.isEmpty && metadata != null) {
      final fromMeta = _operatingCountriesFromMetadata(
        Map<String, dynamic>.from(metadata),
      );
      if (fromMeta != null) {
        codes = fromMeta.countryCodes;
        global = fromMeta.operatesGlobally;
      }
    }

    if (!global && codes.isEmpty) {
      final phone = row['phone'] as String? ?? '';
      final inferred = OperatingCountriesHelper.countryCodeFromPhone(phone);
      codes = [
        inferred ?? OperatingCountriesHelper.defaultCountryCode,
      ];
    }

    return OperatingCountriesSelection(
      countryCodes: codes,
      operatesGlobally: global,
    );
  }

  bool _shouldSyncOperatingCountries(
    Map<String, dynamic> row,
    OperatingCountriesSelection resolved,
  ) {
    if (!resolved.isValid) return false;
    final dbCodes = _parseCountryCodes(row['operating_countries']);
    final dbGlobal = _parseBool(row['operates_globally']);
    return dbCodes.join(',') != resolved.countryCodes.join(',') ||
        dbGlobal != resolved.operatesGlobally;
  }

  Future<void> _syncOperatingCountriesToProfile(
    String userId,
    OperatingCountriesSelection selection,
  ) async {
    try {
      await _client.from('profiles').update({
        'operating_countries':
            OperatingCountriesHelper.normalizeCodes(selection.countryCodes),
        'operates_globally': selection.operatesGlobally,
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      if (_isMissingColumnError(e)) return;
    }
  }
}
