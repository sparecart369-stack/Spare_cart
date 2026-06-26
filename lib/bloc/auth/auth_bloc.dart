import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/core/validation/form_validators.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/repositories/auth_repository.dart';

// Events
sealed class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthSessionChecked extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  AuthLoginRequested({required this.phone, required this.password});
  final String phone;
  final String password;
}

class AuthSignupRequested extends AuthEvent {
  AuthSignupRequested({
    required this.phone,
    required this.password,
    required this.name,
  });
  final String phone;
  final String password;
  final String name;
}

class AuthLogoutRequested extends AuthEvent {}

class AuthBankAccountUpdated extends AuthEvent {
  AuthBankAccountUpdated(this.bankAccount);
  final SellerBankAccount bankAccount;
}

// States
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, user, isLoading, errorMessage];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const AuthState(status: AuthStatus.unknown)) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignupRequested>(_onSignup);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthBankAccountUpdated>(_onBankAccountUpdated);
  }

  final AuthRepository _repository;

  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final profile = await _repository.fetchProfile();
      if (profile != null) {
        emit(AuthState(status: AuthStatus.authenticated, user: profile));
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    } catch (_) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await _repository.signIn(
        phone: event.phone,
        password: event.password,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: FormValidators.authErrorMessage(e),
      ));
    }
  }

  Future<void> _onSignup(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await _repository.signUp(
        name: event.name,
        phone: event.phone,
        password: event.password,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: FormValidators.authErrorMessage(e),
      ));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onBankAccountUpdated(
    AuthBankAccountUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final user = state.user;
    if (user == null) return;

    try {
      final saved = await _repository.saveBankAccount(event.bankAccount);
      emit(state.copyWith(user: user.copyWith(bankAccount: saved)));
    } catch (e) {
      emit(state.copyWith(errorMessage: FormValidators.authErrorMessage(e)));
    }
  }
}
