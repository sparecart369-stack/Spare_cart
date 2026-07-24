import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/core/utils/app_currency.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/repositories/listings_repository.dart';

sealed class ListingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ListingsLoaded extends ListingsEvent {}

Future<void> refreshListings(ListingsBloc bloc) async {
  bloc.add(ListingsLoaded());
  await bloc.stream.firstWhere((state) => !state.isLoading);
}

class ListingPublishRequested extends ListingsEvent {
  ListingPublishRequested({
    required this.input,
    required this.sellerName,
  });

  final CreateListingInput input;
  final String sellerName;
}

class ListingSearchChanged extends ListingsEvent {
  ListingSearchChanged(this.query);
  final String query;
}

class ListingFiltersApplied extends ListingsEvent {
  ListingFiltersApplied(this.filters);
  final PartFilters filters;
}

enum FilterChipField {
  category,
  make,
  model,
  year,
  chassisNumber,
  partNumber,
  condition,
  state,
  district,
  price,
  sort,
}

class ListingFilterCleared extends ListingsEvent {
  ListingFilterCleared(this.field, {this.value});

  final FilterChipField field;
  final String? value;

  @override
  List<Object?> get props => [field, value];
}

class ListingAvailabilityChanged extends ListingsEvent {
  ListingAvailabilityChanged({
    required this.listingId,
    required this.isAvailable,
  });

  final String listingId;
  final bool isAvailable;

  @override
  List<Object?> get props => [listingId, isAvailable];
}

class ActiveFilterChip extends Equatable {
  const ActiveFilterChip({
    required this.label,
    required this.field,
    this.value,
  });

  final String label;
  final FilterChipField field;
  final String? value;

  @override
  List<Object?> get props => [label, field, value];
}

class ListingsState extends Equatable {
  const ListingsState({
    this.allParts = const [],
    this.filteredParts = const [],
    this.adminParts = const [],
    this.searchQuery = '',
    this.filters = const PartFilters(),
    this.isLoaded = false,
    this.isLoading = false,
    this.isPublishing = false,
    this.errorMessage,
  });

  final List<Part> allParts;
  final List<Part> filteredParts;
  final List<Part> adminParts;
  final String searchQuery;
  final PartFilters filters;
  final bool isLoaded;
  final bool isLoading;
  final bool isPublishing;
  final String? errorMessage;

  double get adminTotalSales =>
      adminParts.fold(0.0, (sum, p) => sum + p.price * 1.2);

  int get adminActiveListings => adminParts.length;

  int get adminPendingOrders => 0;

  ListingsState copyWith({
    List<Part>? allParts,
    List<Part>? filteredParts,
    List<Part>? adminParts,
    String? searchQuery,
    PartFilters? filters,
    bool? isLoaded,
    bool? isLoading,
    bool? isPublishing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ListingsState(
      allParts: allParts ?? this.allParts,
      filteredParts: filteredParts ?? this.filteredParts,
      adminParts: adminParts ?? this.adminParts,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      isPublishing: isPublishing ?? this.isPublishing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        allParts,
        filteredParts,
        adminParts,
        searchQuery,
        filters,
        isLoaded,
        isLoading,
        isPublishing,
        errorMessage,
      ];
}

class PartFilters extends Equatable {
  const PartFilters({
    this.category,
    this.make,
    this.model,
    this.year,
    this.chassisNumber,
    this.partNumber,
    this.condition,
    this.states = const [],
    this.districts = const [],
    this.minPrice = 0,
    this.maxPrice = AppCurrency.maxFilterPrice,
    this.sortBy = SortOption.relevance,
  });

  final String? category;
  final String? make;
  final String? model;
  final int? year;
  final String? chassisNumber;
  final String? partNumber;
  final PartCondition? condition;
  final List<String> states;
  final List<String> districts;
  final double minPrice;
  final double maxPrice;
  final SortOption sortBy;

  PartFilters copyWith({
    String? category,
    String? make,
    String? model,
    int? year,
    String? chassisNumber,
    String? partNumber,
    PartCondition? condition,
    List<String>? states,
    List<String>? districts,
    double? minPrice,
    double? maxPrice,
    SortOption? sortBy,
    bool clearCategory = false,
    bool clearMake = false,
    bool clearModel = false,
    bool clearYear = false,
    bool clearChassisNumber = false,
    bool clearPartNumber = false,
    bool clearCondition = false,
    bool clearStates = false,
    bool clearDistricts = false,
  }) {
    return PartFilters(
      category: clearCategory ? null : (category ?? this.category),
      make: clearMake ? null : (make ?? this.make),
      model: clearModel ? null : (model ?? this.model),
      year: clearYear ? null : (year ?? this.year),
      chassisNumber: clearChassisNumber ? null : (chassisNumber ?? this.chassisNumber),
      partNumber: clearPartNumber ? null : (partNumber ?? this.partNumber),
      condition: clearCondition ? null : (condition ?? this.condition),
      states: clearStates ? const [] : (states ?? this.states),
      districts: clearDistricts ? const [] : (districts ?? this.districts),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        category,
        make,
        model,
        year,
        chassisNumber,
        partNumber,
        condition,
        states,
        districts,
        minPrice,
        maxPrice,
        sortBy,
      ];

  List<ActiveFilterChip> get activeChips {
    final chips = <ActiveFilterChip>[];
    if (category != null) {
      chips.add(ActiveFilterChip(label: category!, field: FilterChipField.category));
    }
    if (make != null) {
      chips.add(ActiveFilterChip(label: make!, field: FilterChipField.make));
    }
    if (model != null) {
      chips.add(ActiveFilterChip(label: model!, field: FilterChipField.model));
    }
    if (year != null) {
      chips.add(ActiveFilterChip(label: '$year', field: FilterChipField.year));
    }
    if (chassisNumber != null && chassisNumber!.isNotEmpty) {
      chips.add(ActiveFilterChip(
        label: 'Chassis: $chassisNumber',
        field: FilterChipField.chassisNumber,
      ));
    }
    if (partNumber != null && partNumber!.isNotEmpty) {
      chips.add(ActiveFilterChip(
        label: 'Part: $partNumber',
        field: FilterChipField.partNumber,
      ));
    }
    if (condition != null) {
      chips.add(ActiveFilterChip(
        label: _filterConditionLabel(condition!),
        field: FilterChipField.condition,
      ));
    }
    for (final state in states) {
      chips.add(ActiveFilterChip(
        label: state,
        field: FilterChipField.state,
        value: state,
      ));
    }
    for (final district in districts) {
      chips.add(ActiveFilterChip(
        label: district,
        field: FilterChipField.district,
        value: district,
      ));
    }
    if (minPrice > 0 || maxPrice < AppCurrency.maxFilterPrice) {
      chips.add(ActiveFilterChip(
        label: '${AppCurrency.format(minPrice)} - ${AppCurrency.format(maxPrice)}',
        field: FilterChipField.price,
      ));
    }
    if (sortBy != SortOption.relevance) {
      chips.add(ActiveFilterChip(
        label: _filterSortLabel(sortBy),
        field: FilterChipField.sort,
      ));
    }
    return chips;
  }
}

String _filterConditionLabel(PartCondition condition) => switch (condition) {
      PartCondition.used => 'Used',
      PartCondition.refurbished => 'Refurbished',
      PartCondition.newPart => 'New',
    };

String _filterSortLabel(SortOption sort) => switch (sort) {
      SortOption.relevance => 'Relevance',
      SortOption.newest => 'Newest',
    };

enum SortOption { relevance, newest }

class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc({ListingsRepository? repository})
      : _repository = repository ?? ListingsRepository(),
        super(const ListingsState()) {
    on<ListingsLoaded>(_onLoaded);
    on<ListingPublishRequested>(_onPublish);
    on<ListingSearchChanged>(_onSearch);
    on<ListingFiltersApplied>(_onFilters);
    on<ListingFilterCleared>(_onFilterCleared);
    on<ListingAvailabilityChanged>(_onAvailabilityChanged);
  }

  final ListingsRepository _repository;

  Future<void> _onLoaded(ListingsLoaded event, Emitter<ListingsState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final sellerId = _repository.currentUserId;
      final results = await Future.wait([
        _repository.fetchActiveListings(),
        if (sellerId != null) _repository.fetchSellerListings(sellerId) else Future.value(const <Part>[]),
      ]);

      final allParts = results[0];
      final adminParts = results.length > 1 ? results[1] : const <Part>[];

      emit(state.copyWith(
        allParts: allParts,
        adminParts: adminParts,
        filteredParts: _applyFilters(allParts, state.searchQuery, state.filters),
        isLoaded: true,
        isLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        isLoaded: true,
        errorMessage: 'Could not load listings. Pull to refresh or try again.',
      ));
    }
  }

  Future<void> _onPublish(
    ListingPublishRequested event,
    Emitter<ListingsState> emit,
  ) async {
    final sellerId = _repository.currentUserId;
    if (sellerId == null) {
      emit(state.copyWith(errorMessage: 'Sign in to publish a listing.'));
      return;
    }

    emit(state.copyWith(isPublishing: true, clearError: true));
    try {
      final part = await _repository.createListing(
        sellerId: sellerId,
        sellerName: event.sellerName,
        input: event.input,
      );

      final allParts = [part, ...state.allParts];
      final adminParts = [part, ...state.adminParts];

      emit(state.copyWith(
        allParts: allParts,
        adminParts: adminParts,
        filteredParts: _applyFilters(allParts, state.searchQuery, state.filters),
        isPublishing: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        isPublishing: false,
        errorMessage: 'Could not publish listing. Please try again.',
      ));
    }
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

  void _onFilterCleared(ListingFilterCleared event, Emitter<ListingsState> emit) {
    final filters = switch (event.field) {
      FilterChipField.category => state.filters.copyWith(clearCategory: true),
      FilterChipField.make => state.filters.copyWith(
          clearMake: true,
          clearModel: true,
          clearYear: true,
        ),
      FilterChipField.model => state.filters.copyWith(clearModel: true, clearYear: true),
      FilterChipField.year => state.filters.copyWith(clearYear: true),
      FilterChipField.chassisNumber => state.filters.copyWith(clearChassisNumber: true),
      FilterChipField.partNumber => state.filters.copyWith(clearPartNumber: true),
      FilterChipField.condition => state.filters.copyWith(clearCondition: true),
      FilterChipField.state => event.value == null
          ? state.filters.copyWith(clearStates: true)
          : state.filters.copyWith(
              states: state.filters.states.where((value) => value != event.value).toList(),
            ),
      FilterChipField.district => event.value == null
          ? state.filters.copyWith(clearDistricts: true)
          : state.filters.copyWith(
              districts: state.filters.districts.where((value) => value != event.value).toList(),
            ),
      FilterChipField.price => state.filters.copyWith(
          minPrice: 0,
          maxPrice: AppCurrency.maxFilterPrice,
        ),
      FilterChipField.sort => state.filters.copyWith(sortBy: SortOption.relevance),
    };
    emit(state.copyWith(
      filters: filters,
      filteredParts: _applyFilters(state.allParts, state.searchQuery, filters),
    ));
  }

  void _onAvailabilityChanged(
    ListingAvailabilityChanged event,
    Emitter<ListingsState> emit,
  ) {
    Part updatePart(Part part) =>
        part.id == event.listingId ? part.copyWith(isAvailable: event.isAvailable) : part;

    final adminParts = state.adminParts.map(updatePart).toList();
    final List<Part> allParts;

    if (event.isAvailable) {
      final alreadyListed = state.allParts.any((part) => part.id == event.listingId);
      if (alreadyListed) {
        allParts = state.allParts.map(updatePart).toList();
      } else {
        final restoredIndex = adminParts.indexWhere((part) => part.id == event.listingId);
        final restored = restoredIndex == -1 ? null : adminParts[restoredIndex];
        allParts = restored == null ? state.allParts : [restored, ...state.allParts];
      }
    } else {
      allParts = state.allParts.where((part) => part.id != event.listingId).toList();
    }

    emit(state.copyWith(
      allParts: allParts,
      adminParts: adminParts,
      filteredParts: _applyFilters(allParts, state.searchQuery, state.filters),
    ));
  }

  List<Part> _applyFilters(List<Part> parts, String query, PartFilters filters) {
    var result = parts.where((part) {
      if (query.isNotEmpty && !_matchesSearchQuery(part, query)) {
        return false;
      }
      if (filters.category != null && part.category != filters.category) return false;
      if (filters.make != null && part.make != filters.make) return false;
      if (filters.model != null && part.model != filters.model) return false;
      if (filters.year != null && part.year != filters.year) return false;
      if (filters.chassisNumber != null && filters.chassisNumber!.isNotEmpty) {
        final chassis = part.chassisNumber?.toLowerCase() ?? '';
        if (!chassis.contains(filters.chassisNumber!.toLowerCase())) return false;
      }
      if (filters.partNumber != null && filters.partNumber!.isNotEmpty) {
        final partNo = part.partNumber?.toLowerCase() ?? '';
        if (!partNo.contains(filters.partNumber!.toLowerCase())) return false;
      }
      if (filters.condition != null && part.condition != filters.condition) return false;
      if (!_matchesLocationFilter(part.locationState, filters.states)) return false;
      if (!_matchesLocationFilter(part.locationDistrict, filters.districts)) return false;
      if (part.price < filters.minPrice || part.price > filters.maxPrice) return false;
      return true;
    }).toList();

    switch (filters.sortBy) {
      case SortOption.newest:
        result.sort((a, b) => b.year.compareTo(a.year));
      case SortOption.relevance:
        break;
    }
    return result;
  }

  bool _matchesLocationFilter(String? partValue, List<String> selected) {
    if (selected.isEmpty) return true;
    if (partValue == null || partValue.isEmpty) return false;
    final normalized = partValue.toLowerCase();
    return selected.any((value) => value.toLowerCase() == normalized);
  }

  bool _matchesSearchQuery(Part part, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;

    bool contains(String? value) =>
        value != null && value.trim().isNotEmpty && value.toLowerCase().contains(q);

    return part.fullTitle.toLowerCase().contains(q) ||
        part.category.toLowerCase().contains(q) ||
        part.location.toLowerCase().contains(q) ||
        part.description.toLowerCase().contains(q) ||
        part.make.toLowerCase().contains(q) ||
        part.model.toLowerCase().contains(q) ||
        contains(part.chassisNumber) ||
        contains(part.partNumber) ||
        part.compatibility.any((label) => label.toLowerCase().contains(q));
  }
}
