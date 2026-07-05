abstract final class AppAssets {
  static const appLogo = 'assets/images/app_logo.png';
  static const heroBrakeRotor = 'assets/images/hero_brake_rotor.png';

  static const categoryEngine = 'assets/images/category_engine.png';
  static const categoryTransmission = 'assets/images/category_transmission.png';
  static const categoryAcSystem = 'assets/images/category_ac_system.png';
  static const categoryBodyParts = 'assets/images/category_body_parts.png';
  static const categorySuspension = 'assets/images/category_suspension.png';
  static const categoryBrakes = 'assets/images/category_brakes.png';
  static const categoryElectrical = 'assets/images/category_electrical.png';
  static const categoryAccessories = 'assets/images/category_accessories.png';
  static const categorySensorsModules = 'assets/images/category_sensors_modules.png';
  static const categoryInterior = 'assets/images/category_interior.png';
  static const categoryWheels = 'assets/images/category_wheels.png';
  static const categoryLighting = 'assets/images/category_lighting.png';
  static const categoryBearing = 'assets/images/category_bearing.png';
  static const categoryFuelSystem = 'assets/images/category_fuel_system.png';

  static String? categoryImageFor(String name) => switch (name) {
        'Engine' => categoryEngine,
        'Transmission' => categoryTransmission,
        'AC System' => categoryAcSystem,
        'Body Parts' => categoryBodyParts,
        'Suspension' => categorySuspension,
        'Brakes' => categoryBrakes,
        'Electrical' => categoryElectrical,
        'Accessories' => categoryAccessories,
        'Sensors & Modules' => categorySensorsModules,
        'Interior' => categoryInterior,
        'Wheels' => categoryWheels,
        'Lighting' => categoryLighting,
        'Bearing' => categoryBearing,
        'Fuel System' => categoryFuelSystem,
        _ => null,
      };
}
