import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppMode { buyer, admin }

sealed class AppModeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppModeToggled extends AppModeEvent {}

class AppModeSet extends AppModeEvent {
  AppModeSet(this.mode);
  final AppMode mode;
}

class AppModeState extends Equatable {
  const AppModeState({this.mode = AppMode.buyer});

  final AppMode mode;

  bool get isAdmin => mode == AppMode.admin;

  AppModeState copyWith({AppMode? mode}) => AppModeState(mode: mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}

class AppModeBloc extends Bloc<AppModeEvent, AppModeState> {
  AppModeBloc() : super(const AppModeState()) {
    on<AppModeToggled>((event, emit) {
      emit(state.copyWith(
        mode: state.mode == AppMode.buyer ? AppMode.admin : AppMode.buyer,
      ));
    });
    on<AppModeSet>((event, emit) => emit(state.copyWith(mode: event.mode)));
  }
}
