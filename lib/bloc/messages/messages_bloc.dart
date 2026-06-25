import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/data/models/models.dart';

sealed class MessagesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MessagesLoaded extends MessagesEvent {}

class MessagesState extends Equatable {
  const MessagesState({this.threads = const [], this.isLoaded = false});

  final List<MessageThread> threads;
  final bool isLoaded;

  @override
  List<Object?> get props => [threads, isLoaded];
}

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  MessagesBloc() : super(const MessagesState()) {
    on<MessagesLoaded>((event, emit) {
      emit(MessagesState(threads: generateDummyMessages(), isLoaded: true));
    });
  }
}
