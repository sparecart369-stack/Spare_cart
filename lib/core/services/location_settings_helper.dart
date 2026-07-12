import 'package:flutter/material.dart';
import 'package:spare_kart/core/services/location_service.dart';

Future<bool> handleLocationServiceException(
  BuildContext context,
  LocationServiceException error, {
  String title = 'Enable location',
  String? followUpNote,
}) async {
  if (!context.mounted) return false;

  final note = followUpNote ??
      'After you enable location, come back to this chat and your address will be shared automatically.';

  if (!error.canOpenSettings) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location unavailable'),
        content: Text(error.message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text('${error.message}\n\n$note'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(error.settingsButtonLabel),
        ),
      ],
    ),
  );

  if (shouldOpen != true || !context.mounted) return false;
  return LocationService.openSettingsFor(error);
}
