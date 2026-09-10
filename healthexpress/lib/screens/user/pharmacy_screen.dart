import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine_model.dart';
import '../../models/medical_store_model.dart';
import '../../providers/pharmacy_provider.dart';
import '../common/address_selection_modal.dart';
import 'cart_checkout_screen.dart';
import 'order_tracking_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fever & Pain',
    'Allergy & Cold',
    'Cough Relief',
    'Hydration',
    'Immunity Boost',
    'Antibiotics',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAddToCart(BuildContext context, MedicineModel med, MedicalStoreModel store) {
    final prov = context.read<PharmacyProvider>();
    if (!prov.canAddToCart(store)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.store_mall_directory_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Single Store Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Your cart already contains items from "${prov.cartStore?.name ?? "another store"}".\n\nAt a time, you can only order from ONE store to guarantee 15-minute quick delivery.\n\nWould you like to clear the cart and add "${med.name}" from "${store.name}"?',
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Existing Cart'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.of(ctx).pop();
                prov.addToCart(med, store);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text('Cart switched to ${store.name}'),
                  ),
                );
              },
              child: const Text('Replace & Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      prov.addToCart(med, store);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyProv = context.watch<PharmacyProvider>();
    final activeOrder = pharmacyProv.activeOrder;
    final selectedStore = pharmacyProv.selectedStore;

    final storeMedicines = pharmacyProv.getMedicinesForStore();
    final filteredMedicines = storeMedicines.where((m) {
      final matchesSearch = _searchController.text.isEmpty ||
          m.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          m.genericName.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || m.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medicines Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
            InkWell(
              onTap: () => AddressSelectionModal.show(context),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Deliver to: ${pharmacyProv.selectedAddress.split(',').first} ▼',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (activeOrder != null)
            IconButton(
              icon: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary),
              tooltip: 'Live Track Order',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderTrackingScreen()));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Box
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search medicines, wellness products...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 16),

            // 15-Minute Blinkit-style Delivery Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Flat 20% OFF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedStore != null ? 'Fulfilling from ${selectedStore.name}' : 'Quick Delivery in 12-15 mins',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedStore != null
                              ? '${selectedStore.address} (${selectedStore.distanceKm} km)'
                              : 'Doorstep dispatch from verified nearby dark store pharmacies.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    AppIllustrations.storeDeliveryBike,
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Nearby Medical Stores & Local Pharmacies Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nearby Medical Stores & Chemists', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (selectedStore != null)
                  GestureDetector(
                    onTap: () => pharmacyProv.selectStore(null),
                    child: const Text('View All Stores', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pharmacyProv.medicalStores.map((store) {
                  final isSelected = selectedStore?.id == store.id;
                  return GestureDetector(
                    onTap: () => pharmacyProv.selectStore(store),
                    child: Container(
                      width: 230,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  store.imageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.primaryLight,
                                    child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 2),
                                        Text('${store.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        const SizedBox(width: 4),
                                        Text('(${store.reviewCount})', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⚡ ${store.etaMinutes} MINS',
                                  style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                              Text(
                                '${store.distanceKm} km • ${store.area}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Order with Prescription Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order with Prescription', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Upload doctor note or Aarogyasri slip', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      pharmacyProv.uploadPrescription('Prescription_Uploaded.pdf');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prescription uploaded successfully! Pharmacist is reviewing.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Medicines List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedStore != null
                      ? 'Stock at ${selectedStore.name} (${filteredMedicines.length})'
                      : 'Available Medicines (${filteredMedicines.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (selectedStore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Store Filtered',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMedicines.length,
              itemBuilder: (context, index) {
                final med = filteredMedicines[index];
                final qty = pharmacyProv.getItemQuantity(med.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.medication_liquid_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('${med.genericName} • ${med.packSize}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('₹${med.price.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${med.originalPrice.toInt()}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: TextDecoration.lineThrough),
                                ),
                                if (med.requiresPrescription) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Rx Req', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      qty == 0
                          ? ElevatedButton(
                              onPressed: () => _handleAddToCart(
                                context,
                                med,
                                selectedStore ?? pharmacyProv.medicalStores[0],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16, color: AppColors.primary),
                                    onPressed: () => pharmacyProv.removeFromCart(med.id),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                                    onPressed: () => _handleAddToCart(
                                      context,
                                      med,
                                      selectedStore ?? pharmacyProv.medicalStores[0],
                                    ),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: pharmacyProv.totalCartCount > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartCheckoutScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('View Cart (${pharmacyProv.totalCartCount} items)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          ],
                        ),
                        Text('₹${pharmacyProv.cartTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
