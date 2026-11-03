import 'package:flutter/material.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_inventory_car_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/vehicle_spec_sheet.dart';

class InventoryCarCard extends StatelessWidget {
  final DealerInventoryCarModel car;
  final VoidCallback onEdit;
  final VoidCallback onOffers;

  const InventoryCarCard({
    super.key,
    required this.car,
    required this.onEdit,
    required this.onOffers,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomerCar = car.isCustomerCar;
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CarThumbnail(
                imageUrl: car.images.isEmpty ? '' : car.images.first,
                iconColor: isCustomerCar ? AppColors.blue : AppColors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        DealerStatusChip(
                          label:
                              car.status == 'LIVE'
                                  ? 'Live'
                                  : car.status[0] +
                                      car.status.substring(1).toLowerCase(),
                          color:
                              car.status == 'LIVE'
                                  ? AppColors.green
                                  : AppColors.deepOrange,
                          small: true,
                        ),
                        if (car.isQcPending)
                          const DealerStatusChip(
                            label: 'Photo check pending',
                            color: AppColors.blue,
                            small: true,
                          ),
                        if (car.isQcRejected)
                          const DealerStatusChip(
                            label: 'Photos rejected',
                            color: AppColors.red,
                            small: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (car.isQcPending || car.isQcRejected) ...[
            const SizedBox(height: 10),
            Text(
              car.isQcRejected
                  ? 'OtoBix could not approve the photos: ${car.qcReason}. Edit the car to upload new photos.'
                  : 'OtoBix is checking the photos. Other dealers will see this car once they are approved.',
              style: TextStyle(
                fontSize: 11,
                color: car.isQcRejected ? AppColors.red : AppColors.grey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isCustomerCar) ...[
                Expanded(
                  child: PriceBox(
                    label: 'Retail Price',
                    value:
                        car.retailEnabled
                            ? GlobalFunctions.formatRupees(car.retailPrice)
                            : '—',
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PriceBox(
                  label: isCustomerCar ? 'Expected Price' : 'Dealer Price',
                  value:
                      car.exchangeEnabled
                          ? GlobalFunctions.formatRupees(car.exchangePrice)
                          : 'Not offered',
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VehicleSpecSheet(
            specs: [
              ('Make', car.make),
              ('Model', car.model),
              ('Variant', car.variant),
              ('Mfg Year', car.mfgYear > 0 ? '${car.mfgYear}' : ''),
              ('Regn Year', car.regnYear > 0 ? '${car.regnYear}' : ''),
              (
                'Own Srl No',
                car.ownerSerialNo > 0 ? '${car.ownerSerialNo}' : '',
              ),
              ('Transmission', car.transmission),
              ('Fuel Type', car.fuelType),
              ('Tax Validity', car.taxValidity),
              ('Insurance Validity', car.insuranceValidity),
              ('RTO', car.rto),
              ('City', car.city),
              ('Kms', '${GlobalFunctions.formatNumber(car.kms)} km'),
              ('Listing', car.listingCode),
            ],
          ),
          const SizedBox(height: 12),
          // Customer leads are off for now (being reworked): dealer offers only.
          Row(
            children: [
              Expanded(
                child: _CounterButton(
                  icon: Icons.handshake_outlined,
                  count: car.offerCount,
                  label: 'Dealer Offers',
                  color: AppColors.deepOrange,
                  // The best price on the table, without opening the offers.
                  note:
                      car.bestOffer > 0
                          ? 'Best offer ${GlobalFunctions.formatRupees(car.bestOffer)}'
                          : '',
                  onTap: onOffers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// A line in red under the label; empty shows nothing.
  final String note;

  const _CounterButton({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.onTap,
    this.note = '',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.isNotEmpty)
                      // Shrinks to fit a half-width button rather than cut the amount.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          note,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.red,
                          ),
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
