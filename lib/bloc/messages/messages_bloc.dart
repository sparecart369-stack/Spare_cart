import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/models/models.dart';

sealed class MessagesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MessagesLoaded extends MessagesEvent {}

class MessagesThreadUpserted extends MessagesEvent {
  MessagesThreadUpserted(this.thread);
  final MessageThread thread;

  @override
  List<Object?> get props => [thread];
}

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
      emit(const MessagesState(isLoaded: true));
    });
    on<MessagesThreadUpserted>((event, emit) {
      final threads = List<MessageThread>.from(state.threads);
      final index = threads.indexWhere((t) => t.id == event.thread.id);
      if (index >= 0) {
        threads[index] = event.thread;
      } else {
        threads.insert(0, event.thread);
      }
      threads.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      emit(MessagesState(threads: threads, isLoaded: true));
    });
  }
}
