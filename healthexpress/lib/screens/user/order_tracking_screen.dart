import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../widgets/real_mapbox_map.dart';
import 'pharmacy_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  void _showStoreCallDialog(BuildContext context, String storeName, String storePhone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.store_mall_directory_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                storeName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Verified Pharmacy Partner • $storePhone',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Licensed Pharmacist On-Duty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text('Calling $storeName at $storePhone...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_rounded, color: Colors.white),
                      label: const Text('Call Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStoreChatDialog(BuildContext context, String storeName) {
    final msgController = TextEditingController();
    final List<Map<String, String>> chatMessages = [
      {'sender': 'store', 'text': 'Hello! This is $storeName. We are packing your order right now. How can we help you?', 'time': 'Just now'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFDCFCE7),
                        child: const Icon(Icons.store_mall_directory_rounded, size: 20, color: AppColors.success),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Text('Pharmacist Support • Online', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: chatMessages.length,
                  itemBuilder: (c, i) {
                    final m = chatMessages[i];
                    final isUser = m['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      decoration: InputDecoration(
                        hintText: 'Message pharmacist (e.g. Check expiry date)...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: () {
                      final txt = msgController.text.trim();
                      if (txt.isEmpty) return;
                      setModalState(() {
                        chatMessages.add({'sender': 'user', 'text': txt, 'time': 'Just now'});
                        msgController.clear();
                      });
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (mounted) {
                          setModalState(() {
                            chatMessages.add({
                              'sender': 'store',
                              'text': 'Noted! Our certified pharmacist has verified and added your request.',
                              'time': 'Just now',
                            });
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverCallDialog(BuildContext context, String driverName, String driverPhone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                driverName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Express Delivery Partner • $driverPhone',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Vaccinated • Sanitized Delivery Kit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text('Calling delivery partner $driverName ($driverPhone)...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_rounded, color: Colors.white),
                      label: const Text('Call Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverChatDialog(BuildContext context, String driverName) {
    final msgController = TextEditingController();
    final List<Map<String, String>> chatMessages = [
      {'sender': 'driver', 'text': 'Hello! I have picked up your medicines and am en route.', 'time': 'Just now'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.two_wheeler_rounded, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Text('Live Delivery Chat', style: TextStyle(fontSize: 11, color: AppColors.success)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: chatMessages.length,
                  itemBuilder: (c, i) {
                    final m = chatMessages[i];
                    final isUser = m['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      decoration: InputDecoration(
                        hintText: 'Type instructions (e.g. Leave at gate)...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: () {
                      final txt = msgController.text.trim();
                      if (txt.isEmpty) return;
                      setModalState(() {
                        chatMessages.add({'sender': 'user', 'text': txt, 'time': 'Just now'});
                        msgController.clear();
                      });
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (mounted) {
                          setModalState(() {
                            chatMessages.add({
                              'sender': 'driver',
                              'text': 'Understood! I will follow that instruction.',
                              'time': 'Just now',
                            });
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pharmacyProv = context.watch<PharmacyProvider>();
    final order = pharmacyProv.getActiveOrderForUser(auth.currentUser.id) ?? pharmacyProv.activeOrder;

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Order Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delivery_dining_rounded, size: 80, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('No Active Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('You have not placed any 15-minute medicine orders yet. Place an order to track live doorstep delivery.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PharmacyScreen()));
                  },
                  icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                  label: const Text('Browse Pharmacy Catalog', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isConfirmed = true;
    final isPacked = order.status == DeliveryStatus.packed ||
        order.status == DeliveryStatus.outForDelivery ||
        order.status == DeliveryStatus.delivered;
    final isDispatched = order.status == DeliveryStatus.outForDelivery ||
        order.status == DeliveryStatus.delivered;
    final isDelivered = order.status == DeliveryStatus.delivered;

    final df = DateFormat('hh:mm a');
    final timeConfirmed = df.format(order.orderTime);
    final timePacked = df.format(order.orderTime.add(const Duration(minutes: 5)));
    final timeDispatched = df.format(order.orderTime.add(const Duration(minutes: 10)));
    final timeDelivered = df.format(order.orderTime.add(const Duration(minutes: 18)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
            ),
            Text(
              'Order ID: ${order.orderId}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: AppColors.primary),
            tooltip: 'Live Support',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connecting to 24/7 HealthExpress Pharmacy Helpdesk...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDelivered
                      ? [const Color(0xFF059669), const Color(0xFF10B981)]
                      : [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDelivered ? const Color(0xFF059669) : const Color(0xFF0284C7)).withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivered
                              ? 'Delivered to Doorstep'
                              : (isDispatched
                                  ? 'Out for Delivery'
                                  : (isPacked ? 'Packed & Ready' : 'Order Confirmed')),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDelivered
                              ? 'Medicine packet handed over securely.'
                              : 'Arriving in approx ${order.etaMinutes} at your doorstep',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    AppIllustrations.storeDeliveryBike,
                    height: 72,
                    width: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // REAL Interactive Mapbox GL JS Live Delivery Route Map
            RealMapboxMap(
              height: 240,
              initialLng: 78.3880,
              initialLat: 17.4420,
              initialZoom: 13.5,
              borderRadius: BorderRadius.circular(20),
              markers: const [
                MapboxMarkerItem(
                  id: 'pharmacy-pin',
                  lng: 78.3820,
                  lat: 17.4475,
                  title: 'Apollo / HealthExpress Pharmacy Hub',
                  color: '#0D9488',
                  iconHtml: '🏥',
                  popupText: 'Pharmacy Partner Hub',
                ),
                MapboxMarkerItem(
                  id: 'rider-pin',
                  lng: 78.3880,
                  lat: 17.4420,
                  title: 'Delivery Executive En-Route',
                  color: '#2563EB',
                  iconHtml: '🛵',
                  popupText: 'Live Delivery Rider (ETA: 12 mins)',
                ),
                MapboxMarkerItem(
                  id: 'destination-pin',
                  lng: 78.3950,
                  lat: 17.4380,
                  title: 'Your Delivery Address',
                  color: '#EF4444',
                  iconHtml: '🏠',
                  popupText: 'Your Delivery Destination',
                ),
              ],
              routeCoordinates: const [
                [78.3820, 17.4475],
                [78.3840, 17.4460],
                [78.3860, 17.4440],
                [78.3880, 17.4420],
                [78.3910, 17.4400],
                [78.3950, 17.4380],
              ],
            ),
            const SizedBox(height: 18),

            // FULFILLING PHARMACY STORE DETAILS CARD (WITH CALL & CHAT BUTTONS)
            const Text(
              'Fulfilling Pharmacy Store',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.store_mall_directory_rounded, size: 26, color: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    order.storeName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, size: 15, color: AppColors.success),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.storeAddress,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Drug Lic: ${order.storeLicense}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showStoreCallDialog(context, order.storeName, order.storePhone),
                          icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.primary),
                          label: const Text('Call Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showStoreChatDialog(context, order.storeName),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                          label: const Text('Chat with Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // DELIVERY PARTNER DETAILS CARD (WITH CALL & CHAT BUTTONS)
            const Text(
              'Delivery Partner Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.two_wheeler_rounded, size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.driverName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const Text(
                          'Express Rider • Sanitized Kit',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                    tooltip: 'Call Driver',
                    onPressed: () => _showDriverCallDialog(context, order.driverName, order.driverPhone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                    tooltip: 'Chat with Driver',
                    onPressed: () => _showDriverChatDialog(context, order.driverName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4-Step Timeline Stepper
            const Text(
              'Delivery Status',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _TimelineStep(
                    title: 'Order Confirmed',
                    time: timeConfirmed,
                    isDone: isConfirmed,
                    isFirst: true,
                  ),
                  _TimelineStep(
                    title: 'Packed by ${order.storeName}',
                    time: isPacked ? timePacked : 'Preparing...',
                    isDone: isPacked,
                    isActive: !isPacked,
                  ),
                  _TimelineStep(
                    title: 'Out for Delivery',
                    time: isDispatched ? timeDispatched : 'Standby Rider',
                    isDone: isDispatched,
                    isActive: isPacked && !isDispatched,
                  ),
                  _TimelineStep(
                    title: 'Delivered to Doorstep',
                    time: isDelivered ? timeDelivered : 'Estimated $timeDelivered',
                    isDone: isDelivered,
                    isActive: isDispatched && !isDelivered,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Ordered Items Summary Card
            const Text(
              'Items in this Order',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.medicine.name} (x${item.quantity})',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            Text('₹${item.totalPrice.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('₹${order.total.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Demo Simulation: Advance Rider Status
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚡ Real-time Order Transition',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Status: ${order.status.name}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: isDelivered ? null : () => pharmacyProv.advanceOrderStatus(auth.currentUser.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      isDelivered ? 'Completed' : 'Advance Status →',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.time,
    required this.isDone,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? AppColors.success : (isActive ? AppColors.primary : Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : (isActive ? Icons.two_wheeler_rounded : Icons.circle),
                color: Colors.white,
                size: 13,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isDone ? AppColors.success : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isDone || isActive ? FontWeight.bold : FontWeight.normal,
                    color: isDone || isActive ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
