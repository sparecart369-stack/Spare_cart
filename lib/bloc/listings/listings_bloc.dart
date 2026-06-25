import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/data/models/models.dart';

sealed class ListingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ListingsLoaded extends ListingsEvent {}

class ListingAdded extends ListingsEvent {
  ListingAdded(this.part);
  final Part part;
}

class ListingSearchChanged extends ListingsEvent {
  ListingSearchChanged(this.query);
  final String query;
}

class ListingFiltersApplied extends ListingsEvent {
  ListingFiltersApplied(this.filters);
  final PartFilters filters;
}

class ListingsState extends Equatable {
  const ListingsState({
    this.allParts = const [],
    this.filteredParts = const [],
    this.adminParts = const [],
    this.searchQuery = '',
    this.filters = const PartFilters(),
    this.isLoaded = false,
  });

  final List<Part> allParts;
  final List<Part> filteredParts;
  final List<Part> adminParts;
  final String searchQuery;
  final PartFilters filters;
  final bool isLoaded;

  double get adminTotalSales =>
      adminParts.fold(0.0, (sum, p) => sum + p.price * 1.2);

  int get adminActiveListings => adminParts.length;

  int get adminPendingOrders => 3;

  ListingsState copyWith({
    List<Part>? allParts,
    List<Part>? filteredParts,
    List<Part>? adminParts,
    String? searchQuery,
    PartFilters? filters,
    bool? isLoaded,
  }) {
    return ListingsState(
      allParts: allParts ?? this.allParts,
      filteredParts: filteredParts ?? this.filteredParts,
      adminParts: adminParts ?? this.adminParts,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [allParts, filteredParts, adminParts, searchQuery, filters, isLoaded];
}

class PartFilters extends Equatable {
  const PartFilters({
    this.category,
    this.make,
    this.model,
    this.year,
    this.condition,
    this.minPrice = 0,
    this.maxPrice = 2000,
    this.sortBy = SortOption.relevance,
  });

  final String? category;
  final String? make;
  final String? model;
  final int? year;
  final PartCondition? condition;
  final double minPrice;
  final double maxPrice;
  final SortOption sortBy;

  PartFilters copyWith({
    String? category,
    String? make,
    String? model,
    int? year,
    PartCondition? condition,
    double? minPrice,
    double? maxPrice,
    SortOption? sortBy,
    bool clearCategory = false,
    bool clearMake = false,
    bool clearModel = false,
    bool clearYear = false,
    bool clearCondition = false,
  }) {
    return PartFilters(
      category: clearCategory ? null : (category ?? this.category),
      make: clearMake ? null : (make ?? this.make),
      model: clearModel ? null : (model ?? this.model),
      year: clearYear ? null : (year ?? this.year),
      condition: clearCondition ? null : (condition ?? this.condition),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [category, make, model, year, condition, minPrice, maxPrice, sortBy];
}

enum SortOption { relevance, priceLow, priceHigh, newest }

class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc() : super(const ListingsState()) {
    on<ListingsLoaded>(_onLoaded);
    on<ListingAdded>(_onAdded);
    on<ListingSearchChanged>(_onSearch);
    on<ListingFiltersApplied>(_onFilters);
  }

  void _onLoaded(ListingsLoaded event, Emitter<ListingsState> emit) {
    final parts = generateDummyParts();
    emit(state.copyWith(
      allParts: parts,
      filteredParts: parts,
      isLoaded: true,
    ));
  }

  void _onAdded(ListingAdded event, Emitter<ListingsState> emit) {
    final adminPart = event.part.copyWith(isAdminListing: true);
    final allParts = [adminPart, ...state.allParts];
    final adminParts = [adminPart, ...state.adminParts];
    emit(state.copyWith(
      allParts: allParts,
      adminParts: adminParts,
      filteredParts: _applyFilters(allParts, state.searchQuery, state.filters),
    ));
  }

  void _onSearch(ListingSearchChanged event, Emitter<ListingsState> emit) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredParts: _applyFilters(state.allParts, event.query, state.filters),
    ));
  }

  void _onFilters(ListingFiltersApplied event, Emitter<ListingsState> emit) {
    emit(state.copyWith(
      filters: event.filters,
      filteredParts: _applyFilters(state.allParts, state.searchQuery, event.filters),
    ));
  }

  List<Part> _applyFilters(List<Part> parts, String query, PartFilters filters) {
    var result = parts.where((part) {
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!part.fullTitle.toLowerCase().contains(q) &&
            !part.category.toLowerCase().contains(q) &&
            !part.location.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (filters.category != null && part.category != filters.category) return false;
      if (filters.make != null && part.make != filters.make) return false;
      if (filters.model != null && part.model != filters.model) return false;
      if (filters.year != null && part.year != filters.year) return false;
      if (filters.condition != null && part.condition != filters.condition) return false;
      if (part.price < filters.minPrice || part.price > filters.maxPrice) return false;
      return true;
    }).toList();

    switch (filters.sortBy) {
      case SortOption.priceLow:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceHigh:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.newest:
        result.sort((a, b) => b.year.compareTo(a.year));
      case SortOption.relevance:
        break;
    }
    return result;
  }
}
