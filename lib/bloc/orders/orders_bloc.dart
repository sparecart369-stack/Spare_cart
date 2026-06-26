import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/models/models.dart';

sealed class OrdersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrdersLoaded extends OrdersEvent {}

class OrderPlaced extends OrdersEvent {
  OrderPlaced(this.order);
  final Order order;
}

class OrdersState extends Equatable {
  const OrdersState({this.orders = const [], this.isLoaded = false});

  final List<Order> orders;
  final bool isLoaded;

  OrdersState copyWith({List<Order>? orders, bool? isLoaded}) =>
      OrdersState(orders: orders ?? this.orders, isLoaded: isLoaded ?? this.isLoaded);

  @override
  List<Object?> get props => [orders, isLoaded];
}

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc() : super(const OrdersState()) {
    on<OrdersLoaded>(_onLoaded);
    on<OrderPlaced>(_onPlaced);
  }

  void _onLoaded(OrdersLoaded event, Emitter<OrdersState> emit) {
    emit(const OrdersState(isLoaded: true));
  }

  void _onPlaced(OrderPlaced event, Emitter<OrdersState> emit) {
    emit(state.copyWith(orders: [event.order, ...state.orders]));
  }
}
