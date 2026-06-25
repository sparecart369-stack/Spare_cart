import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/models/models.dart';

// Events
sealed class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  AuthLoginRequested({required this.phone, required this.password});
  final String phone;
  final String password;
}

class AuthSignupRequested extends AuthEvent {
  AuthSignupRequested({required this.phone, required this.password, this.name});
  final String phone;
  final String password;
  final String? name;
}

class AuthLogoutRequested extends AuthEvent {}

// States
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
  });

  final AuthStatus status;
  final UserProfile? user;

  AuthState copyWith({AuthStatus? status, UserProfile? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);

  @override
  List<Object?> get props => [status, user];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState(status: AuthStatus.unauthenticated)) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignupRequested>(_onSignup);
    on<AuthLogoutRequested>(_onLogout);
  }

  void _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) {
    emit(AuthState(
      status: AuthStatus.authenticated,
      user: UserProfile(
        name: 'John Driver',
        phone: event.phone.isEmpty ? '+1 555-0100' : event.phone,
      ),
    ));
  }

  void _onSignup(AuthSignupRequested event, Emitter<AuthState> emit) {
    emit(AuthState(
      status: AuthStatus.authenticated,
      user: UserProfile(
        name: event.name ?? 'New User',
        phone: event.phone.isEmpty ? '+1 555-0199' : event.phone,
      ),
    ));
  }

  void _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
