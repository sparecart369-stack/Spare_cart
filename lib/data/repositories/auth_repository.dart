import 'package:spare_kart/core/validation/form_validators.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserProfile?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final row = await _client
        .from('profiles')
        .select('id, name, phone, positive_feedback_pct')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;

    final bankRow = await _client
        .from('seller_bank_accounts')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    final listingsCount = await _client
        .from('listings')
        .select('id')
        .eq('seller_id', user.id)
        .count(CountOption.exact);

    final ordersCount = await _client
        .from('orders')
        .select('id')
        .eq('buyer_id', user.id)
        .count(CountOption.exact);

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
      listings: listingsCount.count,
      orders: ordersCount.count,
      bankAccount: bankAccount,
    );
  }

  Future<UserProfile> signUp({
    required String name,
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = FormValidators.normalizePhone(phone);
    final email = FormValidators.phoneToAuthEmail(phone);

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name.trim(), 'phone': normalizedPhone},
    );

    if (response.user == null) {
      throw const AuthException('Sign up failed');
    }

    // Ensure profile has correct name (trigger may have run)
    await _client.from('profiles').update({
      'name': name.trim(),
      'phone': normalizedPhone,
    }).eq('id', response.user!.id);

    final profile = await fetchProfile();
    return profile ??
        UserProfile(name: name.trim(), phone: normalizedPhone);
  }

  Future<UserProfile> signIn({
    required String phone,
    required String password,
  }) async {
    final email = FormValidators.phoneToAuthEmail(phone);

    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

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
}
