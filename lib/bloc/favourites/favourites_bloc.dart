import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/repositories/listings_repository.dart';

sealed class FavouritesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FavouritesLoadRequested extends FavouritesEvent {
  FavouritesLoadRequested(this.userId);
  final String? userId;

  @override
  List<Object?> get props => [userId];
}

class FavouriteToggled extends FavouritesEvent {
  FavouriteToggled(this.part);
  final Part part;

  @override
  List<Object?> get props => [part.id];
}

class FavouritesCleared extends FavouritesEvent {}

class FavouritesState extends Equatable {
  const FavouritesState({this.parts = const []});

  final List<Part> parts;

  int get count => parts.length;

  bool contains(String partId) => parts.any((p) => p.id == partId);

  FavouritesState copyWith({List<Part>? parts}) =>
      FavouritesState(parts: parts ?? this.parts);

  @override
  List<Object?> get props => [parts];
}

class FavouritesBloc extends Bloc<FavouritesEvent, FavouritesState> {
  FavouritesBloc({ListingsRepository? repository})
      : _repository = repository ?? ListingsRepository(),
        super(const FavouritesState()) {
    on<FavouritesLoadRequested>(_onLoad);
    on<FavouriteToggled>(_onToggle);
    on<FavouritesCleared>((event, emit) => emit(const FavouritesState()));
  }

  final ListingsRepository _repository;

  Future<void> _onLoad(
    FavouritesLoadRequested event,
    Emitter<FavouritesState> emit,
  ) async {
    final userId = event.userId;
    if (userId == null) {
      emit(const FavouritesState());
      return;
    }

    try {
      final parts = await _repository.fetchSavedListings(userId);
      emit(FavouritesState(parts: parts));
    } catch (_) {}
  }

  Future<void> _onToggle(
    FavouriteToggled event,
    Emitter<FavouritesState> emit,
  ) async {
    final userId = _repository.currentUserId;
    if (userId == null) return;

    final wasSaved = state.contains(event.part.id);
    if (wasSaved) {
      final previous = state.parts;
      emit(state.copyWith(
        parts: previous.where((p) => p.id != event.part.id).toList(),
      ));
      try {
        await _repository.unsaveListing(userId, event.part.id);
      } catch (_) {
        emit(state.copyWith(parts: previous));
      }
    } else {
      final previous = state.parts;
      emit(state.copyWith(parts: [...previous, event.part]));
      try {
        await _repository.saveListing(userId, event.part.id);
      } catch (_) {
        emit(state.copyWith(parts: previous));
      }
    }
  }
}
