import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/services/location_service.dart';
import 'package:spare_kart/core/services/seller_location_store.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/validation/form_validators.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/vehicle_identifier_fields.dart';
import 'package:spare_kart/core/widgets/vehicle_picker_field.dart';
import 'package:spare_kart/data/india_locations.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/repositories/listings_repository.dart';
import 'package:spare_kart/data/vehicle_catalog.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  static const _maxPhotos = 3;

  int _step = 0;
  static const _steps = ['Details', 'Location', 'Photos', 'Review'];
  final _nameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _descController = TextEditingController();
  final _chassisController = TextEditingController();
  String? _category;
  String? _make;
  String? _model;
  int? _year;
  String? _sellerState;
  String? _sellerDistrict;
  final _sellerLocationStore = SellerLocationStore();
  PartCondition _condition = PartCondition.used;
  ListingFulfillment _fulfillment = ListingFulfillment.doorstepDelivery;
  PickupLocationSource _pickupLocationSource = PickupLocationSource.current;
  final _locationService = const LocationService();
  DeviceLocation? _currentDeviceLocation;
  bool _currentLocationLoading = false;
  String? _currentLocationError;
  final _customPickupLocationController = TextEditingController();
  final List<String> _photoPaths = [];
  final _imagePicker = ImagePicker();
  bool _awaitingPublishResult = false;

  int get _lastStep => _steps.length - 1;

  bool get _usesCurrentPickupLocation =>
      _fulfillment == ListingFulfillment.inStorePickup &&
      _pickupLocationSource == PickupLocationSource.current;

  @override
  void initState() {
    super.initState();
    _loadSavedSellerLocation();
  }

  Future<void> _loadSavedSellerLocation() async {
    final saved = await _sellerLocationStore.load();
    if (!mounted || saved == null) return;
    if (!IndiaLocations.instance.isValidSelection(
      state: saved.state,
      district: saved.district,
    )) {
      return;
    }
    setState(() {
      _sellerState = saved.state;
      _sellerDistrict = saved.district;
    });
  }

  Future<void> _persistSellerLocation() async {
    final state = _sellerState;
    final district = _sellerDistrict;
    if (state == null || district == null) return;
    await _sellerLocationStore.save(state: state, district: district);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partNumberController.dispose();
    _descController.dispose();
    _chassisController.dispose();
    _customPickupLocationController.dispose();
    super.dispose();
  }

  void _next() {
    final stepName = _steps[_step];
    if (stepName == 'Details' && !_validateDetails()) return;
    if (stepName == 'Location' && !_validateLocation()) return;
    if (stepName == 'Photos' && !_validatePhotos()) return;
    if (stepName == 'Location') _persistSellerLocation();

    if (_step < _lastStep) {
      setState(() => _step++);
    } else {
      _publishListing();
    }
  }

  bool _validateDetails() {
    final nameError = FormValidators.listingName(_nameController.text);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameError)));
      return false;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return false;
    }
    if (_make == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a make')),
      );
      return false;
    }
    if (_model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a model')),
      );
      return false;
    }
    if (_year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a year')),
      );
      return false;
    }
    final descError = FormValidators.listingDescription(_descController.text);
    if (descError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(descError)));
      return false;
    }
    return true;
  }

  bool _validateLocation() {
    if (_sellerState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your state')),
      );
      return false;
    }
    if (_sellerDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your district')),
      );
      return false;
    }
    return true;
  }

  bool _validatePhotos() {
    if (_photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return false;
    }
    if (_fulfillment == ListingFulfillment.inStorePickup) {
      if (_pickupLocationSource == PickupLocationSource.other &&
          _customPickupLocationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your pickup location')),
        );
        return false;
      }
      if (_pickupLocationSource == PickupLocationSource.current) {
        if (_currentLocationLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Still fetching your current location')),
          );
          return false;
        }
        if (_currentDeviceLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _currentLocationError ?? 'Please allow location access to continue',
              ),
            ),
          );
          _fetchCurrentLocation();
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _fetchCurrentLocation() async {
    if (!_usesCurrentPickupLocation || _currentLocationLoading) return;

    setState(() {
      _currentLocationLoading = true;
      _currentLocationError = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted || !_usesCurrentPickupLocation) return;
      setState(() {
        _currentDeviceLocation = location;
        _currentLocationLoading = false;
        _currentLocationError = null;
      });
    } on LocationServiceException catch (error) {
      if (!mounted || !_usesCurrentPickupLocation) return;
      setState(() {
        _currentDeviceLocation = null;
        _currentLocationLoading = false;
        _currentLocationError = error.message;
      });
    } catch (_) {
      if (!mounted || !_usesCurrentPickupLocation) return;
      setState(() {
        _currentDeviceLocation = null;
        _currentLocationLoading = false;
        _currentLocationError = 'Unable to fetch your current location. Try again.';
      });
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  void _onFulfillmentChanged(ListingFulfillment fulfillment) {
    setState(() => _fulfillment = fulfillment);
    if (fulfillment == ListingFulfillment.inStorePickup &&
        _pickupLocationSource == PickupLocationSource.current) {
      _fetchCurrentLocation();
    }
  }

  void _onPickupLocationSourceChanged(PickupLocationSource source) {
    setState(() => _pickupLocationSource = source);
    if (source == PickupLocationSource.current) {
      _fetchCurrentLocation();
    }
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= _maxPhotos) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _photoPaths.add(image.path));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick photo. Please try again.')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _photoPaths.removeAt(index));
  }

  SellerBankAccount? get _bankAccountForReview {
    final saved = context.read<AuthBloc>().state.user?.bankAccount;
    if (saved != null && saved.isComplete) return saved;
    return null;
  }

  String _formatSellerLocation() {
    final district = _sellerDistrict?.trim() ?? '';
    final state = _sellerState?.trim() ?? '';
    if (district.isEmpty || state.isEmpty) return '';
    return '$district, $state';
  }

  String _resolveListingLocation() {
    if (_fulfillment == ListingFulfillment.doorstepDelivery) {
      final sellerLocation = _formatSellerLocation();
      if (sellerLocation.isNotEmpty) return sellerLocation;
      return kDefaultSellerAddress.split(',').skip(1).join(',').trim();
    }
    if (_pickupLocationSource == PickupLocationSource.current) {
      return _currentDeviceLocation?.address ?? '';
    }
    return _customPickupLocationController.text.trim();
  }

  String _fulfillmentDescription(ListingFulfillment fulfillment) => switch (fulfillment) {
        ListingFulfillment.doorstepDelivery =>
          'Ship the part to the buyer\'s address after payment. Great for buyers who prefer home delivery.',
        ListingFulfillment.inStorePickup =>
          'Let buyers collect the part from your store or location. No shipping required.',
      };

  double _footerBarHeight(bool compact) =>
      (compact ? 10.0 : 12.0) + (compact ? 50.0 : 54.0) + (compact ? 10.0 : 12.0);

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final pad = r.horizontalPadding();
    final compact = r.height < 740;
    final navOverlay = r.mainShellNavOverlayHeight();
    final footerHeight = _footerBarHeight(compact);

    return BlocListener<ListingsBloc, ListingsState>(
      listenWhen: (previous, current) =>
          previous.isPublishing != current.isPublishing ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (!_awaitingPublishResult || state.isPublishing) return;

        if (state.errorMessage != null) {
          _awaitingPublishResult = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          return;
        }

        _awaitingPublishResult = false;
        _resetForm();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SellHeader(step: _step, stepCount: _steps.length, steps: _steps, compact: compact),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    bottom: footerHeight + navOverlay,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        pad,
                        compact ? 6 : 10,
                        pad,
                        compact ? 12 : 16,
                      ),
                      child: switch (_steps[_step]) {
                        'Details' => _buildDetails(compact),
                        'Location' => _buildLocation(compact),
                        'Photos' => _buildPhotos(compact),
                        _ => _buildReview(compact),
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: navOverlay,
                    child: _SellActionBar(
                      pad: pad,
                      compact: compact,
                      step: _step,
                      lastStep: _lastStep,
                      onBack: () => setState(() => _step--),
                      onNext: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDetails(bool compact) {
    final gap = compact ? 6.0 : 8.0;
    final years = VehicleCatalog.vehicleYears;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Part Details', compact: compact),
        SizedBox(height: gap),
        _FormField(
          controller: _nameController,
          hint: 'Part Name',
          icon: Icons.inventory_2_outlined,
          compact: compact,
        ),
        SizedBox(height: gap),
        _FormField(
          controller: _partNumberController,
          hint: 'Part No.',
          icon: Icons.tag_outlined,
          compact: compact,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
            TextInputFormatter.withFunction(
              (old, next) => next.copyWith(text: next.text.toUpperCase()),
            ),
          ],
        ),
        SizedBox(height: gap),
        _DropdownField<String>(
          hint: 'Category',
          value: _category,
          items: categories.map((c) => c.$1).toList(),
          icon: Icons.category_outlined,
          compact: compact,
          onChanged: (v) => setState(() => _category = v),
        ),
        SizedBox(height: gap),
        Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusMd),
          child: Column(
            children: [
              VehiclePickerField(
                hint: 'Make',
                value: _make,
                items: VehicleCatalog.instance.makes,
                icon: Icons.directions_car_rounded,
                compact: compact,
                onChanged: (v) => setState(() {
                  _make = v;
                  _model = VehicleCatalog.instance.defaultModelFor(v);
                  _year = null;
                }),
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: VehiclePickerField(
                      hint: 'Model',
                      value: VehicleCatalog.instance.modelDisplayLabel(make: _make, model: _model),
                      items: VehicleCatalog.instance.modelPickerItems(_make),
                      icon: Icons.apps_rounded,
                      compact: compact,
                      enabled: _make != null,
                      onChanged: _make == null
                          ? null
                          : (v) {
                              if (v == null) return;
                              setState(() {
                                _model = VehicleCatalog.instance.modelValueFromPicker(
                                  make: _make!,
                                  pickerLabel: v,
                                );
                              });
                            },
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: _DropdownField<int>(
                      hint: 'Year',
                      value: _year,
                      items: years,
                      icon: Icons.calendar_month_rounded,
                      compact: compact,
                      enabled: _model != null,
                      display: (v) => '$v',
                      onChanged: _model == null ? null : (v) => setState(() => _year = v),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              VehicleIdentifierFields(
                chassisController: _chassisController,
                compact: compact,
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        _SectionLabel('Condition', compact: compact),
        SizedBox(height: gap),
        SizedBox(
          height: compact ? 34 : 38,
          child: Row(
            children: PartCondition.values.map((c) {
              final selected = _condition == c;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: c != PartCondition.newPart ? 6 : 0),
                  child: _ConditionChip(
                    label: _conditionLabel(c),
                    selected: selected,
                    compact: compact,
                    onTap: () => setState(() => _condition = c),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: gap),
        _FormField(
          controller: _descController,
          hint: 'Description',
          icon: Icons.notes_rounded,
          compact: compact,
          maxLines: compact ? 4 : 5,
        ),
      ],
    );
  }

  Widget _buildLocation(bool compact) {
    final gap = compact ? 6.0 : 8.0;
    final states = IndiaLocations.instance.states;
    final districts = IndiaLocations.instance.districtsFor(_sellerState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Seller Location', compact: compact),
        SizedBox(height: gap),
        Text(
          'Where are you selling from? This is saved for your next listing — you can change it anytime.',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 11 : 12,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: gap + 2),
        _DropdownField<String>(
          hint: 'State / Union Territory',
          value: _sellerState,
          items: states,
          icon: Icons.map_outlined,
          compact: compact,
          onChanged: (v) => setState(() {
            _sellerState = v;
            _sellerDistrict = null;
          }),
        ),
        SizedBox(height: gap),
        _DropdownField<String>(
          hint: 'District',
          value: _sellerDistrict,
          items: districts,
          icon: Icons.location_city_outlined,
          compact: compact,
          enabled: _sellerState != null,
          onChanged: _sellerState == null ? null : (v) => setState(() => _sellerDistrict = v),
        ),
      ],
    );
  }

  Widget _buildFulfillmentSection(bool compact) {
    final gap = compact ? 6.0 : 8.0;

    if (_usesCurrentPickupLocation &&
        !_currentLocationLoading &&
        _currentDeviceLocation == null &&
        _currentLocationError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCurrentLocation());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Fulfillment', compact: compact),
        SizedBox(height: gap),
        SizedBox(
          height: compact ? 34 : 38,
          child: Row(
            children: ListingFulfillment.values.map((f) {
              final selected = _fulfillment == f;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: f != ListingFulfillment.inStorePickup ? 6 : 0,
                  ),
                  child: _ConditionChip(
                    label: f == ListingFulfillment.doorstepDelivery
                        ? 'Doorstep Delivery'
                        : 'In-Store Pickup',
                    selected: selected,
                    compact: compact,
                    onTap: () => _onFulfillmentChanged(f),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: gap),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _fulfillment == ListingFulfillment.doorstepDelivery
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                size: compact ? 16 : 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fulfillmentDescription(_fulfillment),
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 11 : 12,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_fulfillment == ListingFulfillment.inStorePickup) ...[
          SizedBox(height: gap),
          _SectionLabel('Pickup Location', compact: compact),
          SizedBox(height: gap),
          SizedBox(
            height: compact ? 34 : 38,
            child: Row(
              children: PickupLocationSource.values.map((source) {
                final selected = _pickupLocationSource == source;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: source != PickupLocationSource.other ? 6 : 0,
                    ),
                    child: _ConditionChip(
                      label: source == PickupLocationSource.current
                          ? 'Current Location'
                          : 'Other Location',
                      selected: selected,
                      compact: compact,
                      onTap: () => _onPickupLocationSourceChanged(source),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: gap),
          if (_pickupLocationSource == PickupLocationSource.current)
            _CurrentLocationCard(
              compact: compact,
              loading: _currentLocationLoading,
              address: _currentDeviceLocation?.address,
              error: _currentLocationError,
              onRetry: _fetchCurrentLocation,
              onOpenSettings: _openLocationSettings,
            )
          else
            _FormField(
              controller: _customPickupLocationController,
              hint: 'Enter store or pickup address',
              icon: Icons.edit_location_alt_outlined,
              compact: compact,
              maxLines: 2,
            ),
        ],
      ],
    );
  }

  Widget _buildPhotos(bool compact) {
    final r = Responsive(context);
    final gap = compact ? 6.0 : 8.0;
    final columns = r.gridColumns(mobile: 3, tablet: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Upload Photos', compact: compact),
        SizedBox(height: gap),
        Text(
          'Add at least 1 photo (up to $_maxPhotos) of your part',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 11 : 12,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: gap + 2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: 1,
          ),
          itemCount: _photoPaths.length < _maxPhotos ? _photoPaths.length + 1 : _photoPaths.length,
          itemBuilder: (context, i) {
            if (i == _photoPaths.length && _photoPaths.length < _maxPhotos) {
              return _PhotoAddTile(compact: compact, onTap: _pickPhoto);
            }
            return _PhotoTile(
              path: _photoPaths[i],
              index: i,
              compact: compact,
              onRemove: () => _removePhoto(i),
            );
          },
        ),
        SizedBox(height: compact ? 4 : 6),
        _buildFulfillmentSection(compact),
      ],
    );
  }

  Widget _buildReview(bool compact) {
    final gap = compact ? 8.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Review Listing', compact: compact),
        SizedBox(height: gap),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                    child: _photoPaths.isNotEmpty
                        ? _ListingPhoto(
                            path: _photoPaths.first,
                            width: compact ? 64 : 72,
                            height: compact ? 64 : 72,
                          )
                        : Container(
                            width: compact ? 64 : 72,
                            height: compact ? 64 : 72,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 32),
                          ),
                  ),
                  SizedBox(width: gap + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty ? 'Part Name' : _nameController.text,
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            fontSize: compact ? 15 : 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          '${_make ?? 'Make'} · ${_model ?? 'Model'} · ${_year ?? 'Year'}',
                          style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: compact ? 11 : 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        ConditionChip(label: _conditionLabel(_condition)),
                        if (_chassisController.text.trim().isNotEmpty) ...[
                          SizedBox(height: compact ? 4 : 6),
                          Text(
                            'Chassis: ${_chassisController.text.trim()}',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              fontSize: compact ? 10 : 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              if (_category != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _category!.toUpperCase(),
                    style: AppTypography.overline.copyWith(
                      fontSize: compact ? 9 : 10,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _descController.text.isEmpty ? 'No description provided' : _descController.text,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 12 : 13,
                    color: _descController.text.isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: gap),
              if (_formatSellerLocation().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: compact ? 8 : 10),
                  child: _ReviewDetailRow(
                    label: 'Seller at',
                    value: _formatSellerLocation(),
                    compact: compact,
                  ),
                ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _fulfillment == ListingFulfillment.doorstepDelivery
                              ? Icons.local_shipping_outlined
                              : Icons.storefront_outlined,
                          size: compact ? 14 : 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fulfillment.label,
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Text(
                      _fulfillmentDescription(_fulfillment),
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 11 : 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (_fulfillment == ListingFulfillment.inStorePickup) ...[
                      SizedBox(height: compact ? 8 : 10),
                      _ReviewDetailRow(
                        label: 'Pickup at',
                        value: _resolveListingLocation(),
                        compact: compact,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: gap),
              if (_bankAccountForReview != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_rounded, size: compact ? 14 : 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Payout Account',
                            style: AppTypography.textTheme.labelMedium?.copyWith(
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      _ReviewDetailRow(label: 'UPI ID', value: _bankAccountForReview!.upiId, compact: compact),
                      _ReviewDetailRow(label: 'Bank', value: _bankAccountForReview!.bankName, compact: compact),
                      _ReviewDetailRow(label: 'Account No.', value: _bankAccountForReview!.accountNumber, compact: compact),
                      _ReviewDetailRow(label: 'Account Name', value: _bankAccountForReview!.accountName, compact: compact),
                      _ReviewDetailRow(label: 'IFSC', value: _bankAccountForReview!.ifscCode, compact: compact),
                    ],
                  ),
                ),
                SizedBox(height: gap),
              ],
              Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: compact ? 14 : 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '${_photoPaths.length} photo${_photoPaths.length == 1 ? '' : 's'} attached',
                    style: AppTypography.textTheme.labelSmall?.copyWith(fontSize: compact ? 10 : 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _publishListing() {
    final user = context.read<AuthBloc>().state.user;
    final make = _make ?? 'Toyota';
    final model = _model ?? 'Corolla';
    final year = _year ?? 2020;
    final location = _resolveListingLocation();

    _awaitingPublishResult = true;
    _persistSellerLocation();
    context.read<ListingsBloc>().add(
          ListingPublishRequested(
            sellerName: user?.name ?? 'You',
            input: CreateListingInput(
              name: _nameController.text.isEmpty ? 'My Part' : _nameController.text.trim(),
              category: _category ?? 'Engine',
              make: make,
              model: model,
              year: year,
              condition: _condition,
              description:
                  _descController.text.isEmpty ? 'Listed part' : _descController.text.trim(),
              fulfillment: _fulfillment,
              location: location,
              pickupAddress: _fulfillment == ListingFulfillment.inStorePickup ? location : null,
              localPhotoPaths: List<String>.from(_photoPaths),
              chassisNumber: _chassisController.text.trim(),
              partNumber: _partNumberController.text.trim(),
              compatibility: [
                '$make $model $year',
                '$make $model ${year - 1}',
                '$make $model ${year + 1}',
              ],
            ),
          ),
        );
  }

  void _resetForm() {
    final savedState = _sellerState;
    final savedDistrict = _sellerDistrict;
    setState(() {
      _step = 0;
      _nameController.clear();
      _partNumberController.clear();
      _descController.clear();
      _chassisController.clear();
      _category = null;
      _make = null;
      _model = null;
      _year = null;
      _sellerState = savedState;
      _sellerDistrict = savedDistrict;
      _condition = PartCondition.used;
      _fulfillment = ListingFulfillment.doorstepDelivery;
      _pickupLocationSource = PickupLocationSource.current;
      _currentDeviceLocation = null;
      _currentLocationLoading = false;
      _currentLocationError = null;
      _customPickupLocationController.clear();
      _photoPaths.clear();
    });
    _showPublishedDialog();
  }

  void _showPublishedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDecorations.radiusLg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Listing Published')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your part is now live on SpareKart. Pricing will be set after review.',
              style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _conditionLabel(PartCondition c) => switch (c) {
        PartCondition.used => 'Used',
        PartCondition.refurbished => 'Refurbished',
        PartCondition.newPart => 'New',
      };
}

class _SellActionBar extends StatelessWidget {
  const _SellActionBar({
    required this.pad,
    required this.compact,
    required this.step,
    required this.lastStep,
    required this.onBack,
    required this.onNext,
  });

  final double pad;
  final bool compact;
  final int step;
  final int lastStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppDecorations.shadowNav,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        pad,
        compact ? 10 : 12,
        pad,
        compact ? 10 : 12,
      ),
      child: BlocBuilder<ListingsBloc, ListingsState>(
        builder: (context, listingsState) {
          final isPublishing = listingsState.isPublishing;
          return Row(
            children: [
              if (step > 0) ...[
                Expanded(
                  child: SecondaryButton(
                    label: 'Back',
                    onPressed: () {
                      if (isPublishing) return;
                      onBack();
                    },
                  ),
                ),
                SizedBox(width: compact ? 10 : 12),
              ],
              Expanded(
                flex: step > 0 ? 2 : 1,
                child: PrimaryButton(
                  label: step < lastStep ? 'Next' : 'Publish Listing',
                  height: compact ? 50 : 54,
                  icon: step < lastStep
                      ? Icons.arrow_forward_rounded
                      : Icons.publish_rounded,
                  isLoading: step == lastStep && isPublishing,
                  onPressed: () {
                    if (isPublishing) return;
                    onNext();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SellHeader extends StatelessWidget {
  const _SellHeader({
    required this.step,
    required this.stepCount,
    required this.steps,
    required this.compact,
  });

  final int step;
  final int stepCount;
  final List<String> steps;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, compact ? 10 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight,
            AppColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Sell Your Part', style: AppTypography.textTheme.titleLarge),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppDecorations.shadowSm,
                ),
                child: Text(
                  'Step ${step + 1}/$stepCount',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 10 : 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: List.generate(steps.length, (i) {
              final active = i == step;
              final done = i < step;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: compact ? 3 : 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: active || done ? AppColors.primaryGradient : null,
                              color: active || done ? null : AppColors.divider,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 8),
                          Text(
                            steps[i],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              fontSize: compact ? 9 : 10,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                              color: active
                                  ? AppColors.primary
                                  : done
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1) SizedBox(width: compact ? 6 : 8),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.overline.copyWith(
        fontSize: compact ? 10 : 11,
        color: AppColors.primary.withValues(alpha: 0.75),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.compact,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool compact;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textAlignVertical: (maxLines ?? 1) > 1 ? TextAlignVertical.top : TextAlignVertical.center,
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        prefixIcon: Icon(icon, size: compact ? 18 : 20, color: AppColors.textTertiary),
        prefixIconConstraints: BoxConstraints(minWidth: compact ? 40 : 44, minHeight: compact ? 40 : 44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.icon,
    required this.compact,
    required this.onChanged,
    this.display,
    this.enabled = true,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final IconData icon;
  final bool compact;
  final ValueChanged<T?>? onChanged;
  final String Function(T)? display;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return DropdownButtonFormField<T>(
      key: ValueKey('$hint-$value-${enabled ? 'on' : 'off'}'),
      initialValue: value,
      isExpanded: true,
      isDense: true,
      hint: Text(
        hint,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: compact ? 18 : 20,
        color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.4),
      ),
      dropdownColor: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? AppColors.surfaceElevated : AppColors.chipBg,
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 8 : 10),
        prefixIcon: Icon(
          icon,
          size: compact ? 16 : 18,
          color: hasValue
              ? AppColors.primary
              : enabled
                  ? AppColors.textTertiary
                  : AppColors.textTertiary.withValues(alpha: 0.4),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: compact ? 36 : 40, minHeight: compact ? 36 : 40),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(
                display != null ? display!(v) : '$v',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.bodySmall,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
            border: Border.all(color: selected ? Colors.transparent : AppColors.border),
            boxShadow: selected ? AppDecorations.shadowSm : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingPhoto extends StatelessWidget {
  const _ListingPhoto({
    required this.path,
    this.width,
    this.height,
  });

  final String path;
  final double? width;
  final double? height;

  static bool _isNetworkPath(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final error = Container(
      width: width,
      height: height,
      color: AppColors.primaryLight,
      child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 32),
    );

    if (_isNetworkPath(path)) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => error,
      );
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => error,
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.path,
    required this.index,
    required this.compact,
    required this.onRemove,
  });

  final String path;
  final int index;
  final bool compact;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ListingPhoto(path: path),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: AppTypography.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: compact ? 14 : 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoAddTile extends StatelessWidget {
  const _PhotoAddTile({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
            boxShadow: AppDecorations.shadowSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: compact ? 20 : 24),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                'Add',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontSize: compact ? 10 : 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({
    required this.compact,
    required this.loading,
    required this.address,
    required this.error,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final bool compact;
  final bool loading;
  final String? address;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final showSettings = error != null &&
        (error!.toLowerCase().contains('permanently denied') ||
            error!.toLowerCase().contains('settings'));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_rounded, size: compact ? 18 : 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current location',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 10 : 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                if (loading)
                  Row(
                    children: [
                      SizedBox(
                        width: compact ? 14 : 16,
                        height: compact ? 14 : 16,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fetching your location...',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            fontSize: compact ? 11 : 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (address != null)
                  Text(
                    address!,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 11 : 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  )
                else
                  Text(
                    error ?? 'Location unavailable',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 11 : 12,
                      color: AppColors.error,
                      height: 1.4,
                    ),
                  ),
                if (!loading && error != null) ...[
                  SizedBox(height: compact ? 8 : 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      TextButton(
                        onPressed: onRetry,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Retry'),
                      ),
                      if (showSettings)
                        TextButton(
                          onPressed: onOpenSettings,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Open Settings'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!loading && address != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: compact ? 18 : 20, color: AppColors.primary),
              tooltip: 'Refresh location',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _ReviewDetailRow extends StatelessWidget {
  const _ReviewDetailRow({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 88 : 96,
            child: Text(
              label,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 10 : 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
