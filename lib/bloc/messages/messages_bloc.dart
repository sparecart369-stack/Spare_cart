import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/features/messages/chat_session_store.dart';

sealed class MessagesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MessagesLoaded extends MessagesEvent {}

class MessagesSyncedFromStore extends MessagesEvent {
  MessagesSyncedFromStore({required this.isSeller, this.currentUserId});
  final bool isSeller;
  final String? currentUserId;

  @override
  List<Object?> get props => [isSeller, currentUserId];
}

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

  MessagesState copyWith({
    List<MessageThread>? threads,
    bool? isLoaded,
  }) =>
      MessagesState(
        threads: threads ?? this.threads,
        isLoaded: isLoaded ?? this.isLoaded,
      );

  @override
  List<Object?> get props => [threads, isLoaded];
}

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  MessagesBloc() : super(const MessagesState()) {
    on<MessagesLoaded>((event, emit) {
      emit(state.copyWith(isLoaded: true));
    });
    on<MessagesSyncedFromStore>((event, emit) {
      final threads = ChatSessionStore.instance
          .sessionsFor(isSeller: event.isSeller, userId: event.currentUserId)
          .map((session) => session.toThread(isSeller: event.isSeller))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      emit(MessagesState(threads: threads, isLoaded: true));
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
