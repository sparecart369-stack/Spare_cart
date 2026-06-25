import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/models/models.dart';

sealed class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  CartItemAdded(this.part);
  final Part part;
}

class CartItemRemoved extends CartEvent {
  CartItemRemoved(this.partId);
  final String partId;
}

class CartQuantityChanged extends CartEvent {
  CartQuantityChanged({required this.partId, required this.quantity});
  final String partId;
  final int quantity;
}

class CartCleared extends CartEvent {}

class CartState extends Equatable {
  const CartState({this.items = const []});

  final List<CartItem> items;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get shipping => items.isEmpty ? 0 : 12.99;

  double get total => subtotal + shipping;

  bool contains(String partId) => items.any((i) => i.part.id == partId);

  CartState copyWith({List<CartItem>? items}) => CartState(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>(_onAdd);
    on<CartItemRemoved>(_onRemove);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartCleared>((event, emit) => emit(const CartState()));
  }

  void _onAdd(CartItemAdded event, Emitter<CartState> emit) {
    final existing = state.items.indexWhere((i) => i.part.id == event.part.id);
    if (existing >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[existing] = updated[existing].copyWith(quantity: updated[existing].quantity + 1);
      emit(state.copyWith(items: updated));
    } else {
      emit(state.copyWith(items: [...state.items, CartItem(part: event.part)]));
    }
  }

  void _onRemove(CartItemRemoved event, Emitter<CartState> emit) {
    emit(state.copyWith(
      items: state.items.where((i) => i.part.id != event.partId).toList(),
    ));
  }

  void _onQuantityChanged(CartQuantityChanged event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(CartItemRemoved(event.partId));
      return;
    }
    final updated = state.items.map((item) {
      if (item.part.id == event.partId) return item.copyWith(quantity: event.quantity);
      return item;
    }).toList();
    emit(state.copyWith(items: updated));
  }
}
