import 'package:spare_kart/core/utils/app_currency.dart';
import 'package:spare_kart/data/models/models.dart';

const categories = [
  ('Engine', 'engineering'),
  ('Transmission', 'settings'),
  ('Body Parts', 'directions_car'),
  ('Lighting', 'lightbulb'),
  ('Wheels', 'tire_repair'),
  ('Brakes', 'stop_circle'),
  ('Suspension', 'height'),
  ('Electrical', 'bolt'),
];

const makes = ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes', 'Nissan', 'Hyundai', 'Chevrolet'];
const models = ['Corolla', 'Civic', 'F-150', '3 Series', 'C-Class', 'Altima', 'Elantra', 'Malibu'];

List<Part> generateDummyParts() {
  final parts = <Part>[
    _part('1', 'Alternator', 'Electrical', 'Toyota', 'Corolla', 2016, PartCondition.used, 89.99, 'Los Angeles, CA', 's1', 'Mike Auto Parts', 4.8),
    _part('2', 'Transmission Assembly', 'Transmission', 'Honda', 'Civic', 2018, PartCondition.refurbished, 1249.00, 'Houston, TX', 's2', 'Texas Motors', 4.6),
    _part('3', 'Front Bumper', 'Body Parts', 'Ford', 'F-150', 2019, PartCondition.used, 245.50, 'Chicago, IL', 's3', 'Windy City Parts', 4.5),
    _part('4', 'LED Headlight Pair', 'Lighting', 'BMW', '3 Series', 2020, PartCondition.newPart, 399.00, 'Miami, FL', 's4', 'Euro Parts Hub', 4.9),
    _part('5', 'Alloy Wheel Set', 'Wheels', 'Mercedes', 'C-Class', 2017, PartCondition.used, 550.00, 'Phoenix, AZ', 's5', 'Desert Wheels', 4.4),
    _part('6', 'Brake Caliper', 'Brakes', 'Nissan', 'Altima', 2015, PartCondition.used, 75.00, 'Seattle, WA', 's6', 'Pacific Auto', 4.7),
    _part('7', 'Shock Absorber Kit', 'Suspension', 'Hyundai', 'Elantra', 2019, PartCondition.refurbished, 189.99, 'Denver, CO', 's7', 'Mountain Parts', 4.3),
    _part('8', 'Starter Motor', 'Electrical', 'Chevrolet', 'Malibu', 2016, PartCondition.used, 120.00, 'Atlanta, GA', 's8', 'Peach State Auto', 4.6),
    _part('9', 'Radiator', 'Engine', 'Toyota', 'Corolla', 2017, PartCondition.used, 95.00, 'Dallas, TX', 's1', 'Mike Auto Parts', 4.8),
    _part('10', 'Fuel Pump', 'Engine', 'Honda', 'Civic', 2016, PartCondition.used, 65.00, 'Portland, OR', 's9', 'Northwest Parts', 4.5),
    _part('11', 'Side Mirror', 'Body Parts', 'Ford', 'F-150', 2020, PartCondition.used, 85.00, 'Boston, MA', 's10', 'East Coast Auto', 4.2),
    _part('12', 'Tail Light Assembly', 'Lighting', 'BMW', '3 Series', 2018, PartCondition.refurbished, 175.00, 'San Diego, CA', 's4', 'Euro Parts Hub', 4.9),
    _part('13', 'Tire Set (4)', 'Wheels', 'Toyota', 'Corolla', 2021, PartCondition.used, 280.00, 'Las Vegas, NV', 's11', 'Vegas Wheels', 4.1),
    _part('14', 'Brake Rotor Pair', 'Brakes', 'Honda', 'Civic', 2019, PartCondition.newPart, 110.00, 'Minneapolis, MN', 's12', 'Twin Cities Parts', 4.7),
    _part('15', 'Control Arm', 'Suspension', 'Nissan', 'Altima', 2017, PartCondition.used, 55.00, 'Detroit, MI', 's13', 'Motor City Parts', 4.4),
    _part('16', 'ECU Module', 'Electrical', 'Mercedes', 'C-Class', 2019, PartCondition.refurbished, 450.00, 'San Francisco, CA', 's14', 'Bay Area Auto', 4.8),
    _part('17', 'Timing Belt Kit', 'Engine', 'Hyundai', 'Elantra', 2018, PartCondition.newPart, 89.00, 'Austin, TX', 's15', 'Lone Star Parts', 4.6),
    _part('18', 'Clutch Kit', 'Transmission', 'Ford', 'F-150', 2016, PartCondition.used, 320.00, 'Nashville, TN', 's16', 'Music City Motors', 4.3),
    _part('19', 'Hood Panel', 'Body Parts', 'Chevrolet', 'Malibu', 2018, PartCondition.used, 195.00, 'Charlotte, NC', 's17', 'Carolina Parts', 4.5),
    _part('20', 'Fog Light Kit', 'Lighting', 'Toyota', 'Corolla', 2020, PartCondition.newPart, 68.00, 'Orlando, FL', 's18', 'Sunshine Auto', 4.4),
    _part('21', 'Wheel Bearing', 'Wheels', 'Honda', 'Civic', 2015, PartCondition.used, 42.00, 'Philadelphia, PA', 's19', 'Philly Parts Co', 4.2),
    _part('22', 'Master Cylinder', 'Brakes', 'BMW', '3 Series', 2017, PartCondition.refurbished, 135.00, 'Columbus, OH', 's20', 'Buckeye Auto', 4.6),
    _part('23', 'Strut Assembly', 'Suspension', 'Ford', 'F-150', 2019, PartCondition.used, 145.00, 'Indianapolis, IN', 's21', 'Indy Parts', 4.3),
    _part('24', 'Alternator', 'Electrical', 'Nissan', 'Altima', 2016, PartCondition.used, 78.00, 'Kansas City, MO', 's22', 'KC Auto Supply', 4.5),
    _part('25', 'Water Pump', 'Engine', 'Mercedes', 'C-Class', 2018, PartCondition.used, 110.00, 'Salt Lake City, UT', 's23', 'Wasatch Parts', 4.7),
    _part('26', 'CV Axle', 'Transmission', 'Hyundai', 'Elantra', 2017, PartCondition.used, 88.00, 'Tampa, FL', 's24', 'Gulf Coast Auto', 4.4),
    _part('27', 'Door Panel', 'Body Parts', 'Toyota', 'Corolla', 2019, PartCondition.used, 125.00, 'Raleigh, NC', 's25', 'Triangle Parts', 4.5),
    _part('28', 'Daytime Running Light', 'Lighting', 'Honda', 'Civic', 2021, PartCondition.newPart, 95.00, 'Sacramento, CA', 's26', 'Capital Auto', 4.8),
    _part('29', 'Hub Assembly', 'Wheels', 'Chevrolet', 'Malibu', 2016, PartCondition.refurbished, 72.00, 'Milwaukee, WI', 's27', 'Lakefront Parts', 4.3),
    _part('30', 'Oxygen Sensor', 'Engine', 'Ford', 'F-150', 2020, PartCondition.newPart, 48.00, 'Cleveland, OH', 's28', 'Great Lakes Auto', 4.6),
  ];
  return parts;
}

Part _part(
  String id,
  String name,
  String category,
  String make,
  String model,
  int year,
  PartCondition condition,
  double price,
  String location,
  String sellerId,
  String sellerName,
  double rating,
) {
  return Part(
    id: id,
    name: name,
    category: category,
    make: make,
    model: model,
    year: year,
    condition: condition,
    price: price,
    location: location,
    sellerId: sellerId,
    sellerName: sellerName,
    sellerRating: rating,
    imageUrl: 'https://picsum.photos/seed/spare$id/400/300',
    imageUrls: [
      'https://picsum.photos/seed/spare$id-a/400/300',
      'https://picsum.photos/seed/spare$id-b/400/300',
      'https://picsum.photos/seed/spare$id-c/400/300',
    ],
    description:
        'High-quality $name for $make $model ($year). Professionally inspected and ready to ship. '
        'Compatible with multiple trim levels. Contact seller for fitment verification.',
    compatibility: ['$make $model $year', '$make $model ${year - 1}', '$make $model ${year + 1}'],
  );
}

List<Order> generateDummyOrders(List<Part> parts) {
  return [
    Order(
      id: 'ORD-1001',
      items: [CartItem(part: parts[0], quantity: 1)],
      status: OrderStatus.delivered,
      date: DateTime.now().subtract(const Duration(days: 14)),
      total: parts[0].price + AppCurrency.standardShipping,
      trackingNumber: 'TRK789456123',
    ),
    Order(
      id: 'ORD-1002',
      items: [CartItem(part: parts[3], quantity: 1), CartItem(part: parts[5], quantity: 2)],
      status: OrderStatus.shipped,
      date: DateTime.now().subtract(const Duration(days: 5)),
      total: parts[3].price + parts[5].price * 2 + AppCurrency.expressShipping,
      trackingNumber: 'TRK456123789',
    ),
    Order(
      id: 'ORD-1003',
      items: [CartItem(part: parts[8], quantity: 1)],
      status: OrderStatus.paid,
      date: DateTime.now().subtract(const Duration(days: 2)),
      total: parts[8].price + 79,
      trackingNumber: 'Pending',
    ),
    Order(
      id: 'ORD-1004',
      items: [CartItem(part: parts[12], quantity: 1)],
      status: OrderStatus.cancelled,
      date: DateTime.now().subtract(const Duration(days: 30)),
      total: parts[12].price,
      trackingNumber: 'N/A',
    ),
  ];
}

List<MessageThread> generateDummyMessages() {
  return [
    MessageThread(
      id: 'm1',
      participantName: 'Mike Auto Parts',
      lastMessage: 'Yes, the alternator is still available!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 2,
      partTitle: 'Alternator Toyota Corolla 2016',
    ),
    MessageThread(
      id: 'm2',
      participantName: 'Euro Parts Hub',
      lastMessage: 'I can offer a 5% discount if you buy today.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      partTitle: 'LED Headlight Pair BMW 3 Series',
    ),
    MessageThread(
      id: 'm3',
      participantName: 'Texas Motors',
      lastMessage: 'Shipping would take 3-5 business days.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 1,
      partTitle: 'Transmission Assembly Honda Civic',
    ),
    MessageThread(
      id: 'm4',
      participantName: 'Pacific Auto',
      lastMessage: 'Thanks for your purchase!',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      unreadCount: 0,
      partTitle: 'Brake Caliper Nissan Altima',
    ),
  ];
}

List<AppNotification> generateDummyNotifications() {
  return [
    AppNotification(
      id: 'n1',
      title: 'Order Shipped',
      body: 'Your order #SK-1042 has been shipped. Track it in My Orders.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    AppNotification(
      id: 'n2',
      title: 'New Message',
      body: 'Mike Auto Parts replied about the Alternator Toyota Corolla 2016.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n3',
      title: 'Price Drop',
      body: 'LED Headlight Pair BMW 3 Series is now 10% off.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    AppNotification(
      id: 'n4',
      title: 'Listing Approved',
      body: 'Your listing "Brake Pads Honda Accord" is now live.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: 'n5',
      title: 'Welcome to SpareKart',
      body: 'Start browsing quality auto parts from trusted sellers.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];
}

List<ChatMessage> generateChatMessages() {
  return [
    ChatMessage(
      id: 'c1',
      text: 'Hi, is this alternator still available?',
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      id: 'c2',
      text: 'Yes, the alternator is still available!',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
    ),
    ChatMessage(
      id: 'c3',
      text: 'Great! Does it come with a warranty?',
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    ChatMessage(
      id: 'c4',
      text: 'Yes, 30-day warranty included. Free return if defective.',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];
}
