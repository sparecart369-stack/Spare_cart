class FormValidators {
  FormValidators._();

  static final _phoneDigits = RegExp(r'^[0-9]{10,15}$');
  static final _namePattern = RegExp(r"^[a-zA-Z\s'.-]{2,60}$");
  static final _upiPattern = RegExp(r'^[\w.\-]{2,}@[\w.\-]{2,}$');
  static final _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final _zipPattern = RegExp(r'^[0-9]{5,10}$');

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    if (phone.trim().startsWith('+')) return phone.trim();
    return '+$digits';
  }

  static String phoneToAuthEmail(String phone) {
    final digits = normalizePhone(phone).replaceAll(RegExp(r'\D'), '');
    return '$digits@phone.sparekart.app';
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (!_namePattern.hasMatch(v)) return 'Enter a valid name';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (!_phoneDigits.hasMatch(digits)) {
      return 'Enter a valid 10–15 digit phone number';
    }
    return null;
  }

  static String? phoneLocal(String? value, {String dialCode = '+91'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (dialCode == '+91') {
      if (digits.length != 10) return 'Enter a valid 10-digit phone number';
      return null;
    }
    if (digits.length < 4 || digits.length > 14) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? password(String? value, {bool isSignup = false}) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (isSignup) {
      if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
      if (!RegExp(r'[a-z]').hasMatch(v)) return 'Include at least one lowercase letter';
      if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? upiId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'UPI ID is required';
    if (!_upiPattern.hasMatch(v)) return 'Enter a valid UPI ID (e.g. name@bank)';
    return null;
  }

  static String? bankName(String? value) {
    return requiredField(value, 'Bank name');
  }

  static String? accountNumber(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Account number is required';
    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(v)) return 'Enter a valid account number';
    return null;
  }

  static String? accountHolderName(String? value) {
    return name(value);
  }

  static String? ifscCode(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'IFSC code is required';
    if (!_ifscPattern.hasMatch(v)) return 'Enter a valid IFSC code (e.g. SBIN0001234)';
    return null;
  }

  static String? streetAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Street address is required';
    if (v.length < 5) return 'Enter a complete street address';
    return null;
  }

  static String? city(String? value) {
    return requiredField(value, 'City');
  }

  static String? state(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'State is required';
    if (v.length < 2) return 'Enter a valid state';
    return null;
  }

  static String? zipCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'ZIP / PIN code is required';
    if (!_zipPattern.hasMatch(v)) return 'Enter a valid ZIP / PIN code';
    return null;
  }

  static String? listingName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Part name is required';
    if (v.length < 3) return 'Part name must be at least 3 characters';
    return null;
  }

  static String? listingDescription(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Description is required';
    if (v.length < 10) return 'Description must be at least 10 characters';
    return null;
  }

  static String? price(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Price is required';
    final price = double.tryParse(v.replaceAll(',', ''));
    if (price == null || price <= 0) return 'Enter a valid price';
    return null;
  }

  static String? messageText(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Message cannot be empty';
    if (v.length > 2000) return 'Message is too long';
    return null;
  }

  static String authErrorMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Invalid phone number or password';
    }
    if (msg.contains('user already registered') || msg.contains('already been registered')) {
      return 'An account with this phone number already exists. Try logging in.';
    }
    if (msg.contains('already linked to an account')) {
      return 'This phone number is already linked to an account. Try logging in.';
    }
    if (msg.contains('password')) return 'Password does not meet requirements';
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Check your connection and try again';
    }
    if (msg.contains('operating_countries') ||
        msg.contains('operates_globally') ||
        msg.contains('database migration')) {
      return 'Server setup incomplete. Apply the latest Supabase migration and try again.';
    }
    if (msg.contains('permission denied') || msg.contains('row-level security')) {
      return 'Account created but profile sync failed. Try logging in.';
    }
    return 'Something went wrong. Please try again';
  }
}
