import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Models/car_model.dart';
import 'package:otobix/Utils/app_constants.dart';
import '../Models/car_gallery_sections_model.dart';

class CarImagesGalleryController extends GetxController {
  final CarModel car;
  final String initialSectionId;
  final int initialSectionIndex;
  final String currentOpenSection;
  final RxString remainingAuctionTime;

  // Constructor to get car details, initial section id and index
  CarImagesGalleryController(
    this.car,
    this.initialSectionId,
    this.initialSectionIndex,
    this.currentOpenSection,
    this.remainingAuctionTime,
  );

  // Observables
  final sections = <CarGallerySectionsModel>[].obs;
  final selectedIndex = 0.obs;
  final scrollController = ScrollController();
  final sectionKeys = <String, GlobalKey>{};
  final headerKey = GlobalKey();

  // Configurations
  final int gridColumns = 3;
  final double gridGap = 12;
  final double outerPad = 16;

  bool _updatingFromTap = false;

  Worker? _timerWatcher;
  bool _closedOnce = false;

  @override
  void onInit() {
    super.onInit();
    selectedIndex.value = initialSectionIndex;
    _seedDemoData();
    _initKeys();
    scrollController.addListener(_onScrollUpdateActiveChip);

    // Close screen when timer ends
    final homeController = Get.find<HomeController>();
    watchAndCloseOnTimerEnd(
      remainingAuctionTime:
          currentOpenSection == homeController.upcomingSectionScreen ||
                  currentOpenSection == homeController.liveBidsSectionScreen
              ? remainingAuctionTime
              : null,
    );
  }

  @override
  void onReady() {
    super.onReady();
    final i = sections.indexWhere((s) => s.id == initialSectionId);
    if (i >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureSectionsAreBuildBeforeShowing(i);
      });
    }
  }

  Future<void> _ensureSectionsAreBuildBeforeShowing(int index) async {
    // Try a few times to force-build the target item
    final maxTries = 8;
    int tries = 0;
    while ((sectionKeys[sections[index].id]?.currentContext) == null &&
        tries < maxTries &&
        scrollController.hasClients) {
      // Rough estimate to get close enough so ListView.builder builds it.
      final estOffset = (index * 420.0) // tune per your average section height
          .clamp(0.0, scrollController.position.maxScrollExtent);
      await scrollController.animateTo(
        estOffset,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(milliseconds: 16)); // next frame
      tries++;
    }

    // Now it should exist; fall back to a normal onChipTap scrolling
    await onChipTap(index);
  }

  // Seed demo data for car sections (replace with real data from API)
  void _seedDemoData() {
    sections.value = [
      CarGallerySectionsModel(
        id: AppConstants.imagesSectionIds.exterior,
        title: 'Exterior',
        images: [
          ...car.bonnetImages,
          ...car.frontBumperImages,
          ...car.lhsHeadlampImages,
          ...car.rhsHeadlampImages,
          ...car.frontWindshieldImages,
          ...car.lhsFenderImages,
          ...car.rhsFenderImages,
          ...car.lhsFrontDoorImages,
          ...car.rhsFrontDoorImages,
          ...car.lhsOrvmImages,
          ...car.rhsOrvmImages,
        ],
      ),
      CarGallerySectionsModel(
        id: AppConstants.imagesSectionIds.interior,
        title: 'Interior',
        images: [
          ...car.frontSeatsFromDriverSideDoorOpen,
          ...car.rearSeatsFromRightSideDoorOpen,
          ...car.dashboardFromRearSeat,
          ...car
              .additionalImages2, // Additional Images 2 Column is for Interior Images
        ],
      ),

      CarGallerySectionsModel(
        id: AppConstants.imagesSectionIds.engine,
        title: 'Engine',
        images: [
          ...car.engineBay,
          ...car.batteryImages,
          ...car.apronLhsRhs,
          ...car
              .additionalImages, // Additional Images 1 Column is for Engine Images
        ],
      ),
      CarGallerySectionsModel(
        id: AppConstants.imagesSectionIds.tyres,
        title: 'Tyres',
        images: [
          ...car.spareTyreImages,
          ...car.lhsRearTyreImages,
          ...car.rhsRearTyreImages,
          ...car.lhsFrontTyreImages,
          ...car.rhsFrontTyreImages,
        ],
      ),

      // CarGallerySectionsModel(
      //   id: AppConstants.imagesSectionIds.suspension,
      //   title: 'Suspension',
      //   images: [
      //     ...car.lhsFrontAlloyImages,
      //     ...car.rhsFrontAlloyImages,
      //     ...car.lhsRearAlloyImages,
      //     ...car.rhsRearAlloyImages,
      //     ...car.lhsFrontTyreImages,
      //     ...car.rhsFrontTyreImages,
      //     ...car.lhsRearTyreImages,
      //     ...car.rhsRearTyreImages,
      //   ],
      // ),
      CarGallerySectionsModel(
        id: AppConstants.imagesSectionIds.damages,
        title: 'Damages',
        // images: [...car.damangesImages],
        images: _collectDamageImages(),
      ),
    ];
  }

  // Initialize GlobalKeys for each section
  void _initKeys() {
    for (final s in sections) {
      sectionKeys[s.id] = GlobalKey(debugLabel: 'section_${s.id}');
    }
  }

  // Handle chip tap (smooth scroll to section)
  Future<void> onChipTap(int index) async {
    if (index < 0 || index >= sections.length) return;

    _updatingFromTap = true;
    selectedIndex.value = index;

    // 👇 ensure the target widget actually exists
    await _ensureSectionBuiltOnTappingChip(index);

    final key = sectionKeys[sections[index].id];
    final ctx = key?.currentContext;
    if (ctx == null) {
      // still not there? bail gracefully
      _updatingFromTap = false;
      return;
    }

    // Smooth scroll into view
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.02,
    );

    // Adjust for header overlap (chips bar + app bar if any)
    final headerHeight = _getHeaderHeight();
    final overlapFix = (scrollController.offset - headerHeight - 8).clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    await scrollController.animateTo(
      overlapFix,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );

    _updatingFromTap = false;
  }

  // Track scroll to update active chip
  void _onScrollUpdateActiveChip() {
    if (_updatingFromTap) return;
    final headerHeight = _getHeaderHeight();
    const tolerance = 60.0;

    int best = selectedIndex.value;
    double dist = double.infinity;

    for (var i = 0; i < sections.length; i++) {
      final key = sectionKeys[sections[i].id];
      final ctx = key?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final top = box.localToGlobal(Offset.zero).dy;
      final d = (top - headerHeight).abs();
      if (d < dist) {
        dist = d;
        best = i;
      }
    }

    if (best != selectedIndex.value && dist < tolerance) {
      selectedIndex.value = best;
    }
  }

  // Get the header height (for offset adjustment)
  double _getHeaderHeight() {
    final ctx = headerKey.currentContext;
    if (ctx == null) return 0;
    final box = ctx.findRenderObject() as RenderBox?;
    return (box?.attached ?? false) ? box!.size.height : 0;
  }

  /// Call this once (e.g., from the view) and pass the RxString that displays the timer.
  void watchAndCloseOnTimerEnd({RxString? remainingAuctionTime}) {
    // No timer? Nothing to watch.
    if (remainingAuctionTime == null) return;

    bool _isZero(String s) => s.trim() == '00h : 00m : 00s';

    void _maybeClose() {
      if (_closedOnce) return;
      _closedOnce = true;

      // Close the current screen
      Get.back<void>();
    }

    // Immediate defensive check (in case it's already zero)
    if (_isZero(remainingAuctionTime.value)) {
      _maybeClose();
      return;
    }

    // Watch future changes
    _timerWatcher?.dispose(); // ensure only one watcher
    _timerWatcher = ever<String>(remainingAuctionTime, (val) {
      if (_isZero(val)) {
        _maybeClose();
      }
    });
  }

  // Make sure the target section is built before scrolling to it
  Future<void> _ensureSectionBuiltOnTappingChip(int index) async {
    // Try a few frames to nudge the list so the target gets built.
    // Tune avgHeight for your sections; start with ~420–600.
    const avgHeight = 520.0;
    const tries = 8;

    for (var t = 0; t < tries; t++) {
      final ctx = sectionKeys[sections[index].id]?.currentContext;
      if (ctx != null) return; // it's built, good to go

      if (!scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 16));
        continue;
      }

      // Estimate an offset near the section; clamp to bounds.
      final est = (index * avgHeight).clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      );

      // Use a tiny jump so it's fast and doesn't animate visibly.
      await scrollController.animateTo(
        est,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
      // Let the frame render
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScrollUpdateActiveChip);
    scrollController.dispose();
    _timerWatcher?.dispose();
    super.onClose();
  }

  // Gather all damaged parts' images (deduped)
  List<String> _collectDamageImages() {
    // Build your parts matrix once from CarModel → status + images
    final parts = <_DamagedPartModel>[
      // ---- Exterior (Front / Left / Rear / Right) ----
      _DamagedPartModel('Bonnet', car.bonnet, car.bonnetImages),
      _DamagedPartModel(
        'Front Windshield',
        car.frontWindshield,
        car.frontWindshieldImages,
      ),
      _DamagedPartModel('Roof', car.roof, car.roofImages),
      _DamagedPartModel('Front Bumper', car.frontBumper, car.frontBumperImages),

      _DamagedPartModel('LHS Headlamp', car.lhsHeadlamp, car.lhsHeadlampImages),
      _DamagedPartModel('LHS Foglamp', car.lhsFoglamp, car.lhsFoglampImages),
      _DamagedPartModel('RHS Headlamp', car.rhsHeadlamp, car.rhsHeadlampImages),
      _DamagedPartModel('RHS Foglamp', car.rhsFoglamp, car.rhsFoglampImages),

      _DamagedPartModel('LHS Fender', car.lhsFender, car.lhsFenderImages),
      _DamagedPartModel('LHS ORVM', car.lhsOrvm, car.lhsOrvmImages),
      _DamagedPartModel('LHS A Pillar', car.lhsAPillar, car.lhsAPillarImages),
      _DamagedPartModel('LHS B Pillar', car.lhsBPillar, car.lhsBPillarImages),
      _DamagedPartModel('LHS C Pillar', car.lhsCPillar, car.lhsCPillarImages),
      _DamagedPartModel(
        'LHS Front Alloy',
        car.lhsFrontAlloy,
        car.lhsFrontAlloyImages,
      ),

      _DamagedPartModel(
        'LHS Rear Alloy',
        car.lhsRearAlloy,
        car.lhsRearAlloyImages,
      ),

      _DamagedPartModel(
        'LHS Front Door',
        car.lhsFrontDoor,
        car.lhsFrontDoorImages,
      ),
      _DamagedPartModel(
        'LHS Rear Door',
        car.lhsRearDoor,
        car.lhsRearDoorImages,
      ),
      _DamagedPartModel(
        'LHS Running Border',
        car.lhsRunningBorder,
        car.lhsRunningBorderImages,
      ),
      _DamagedPartModel(
        'LHS Quarter Panel',
        car.lhsQuarterPanel,
        car.lhsQuarterPanelImages,
      ),

      _DamagedPartModel('Rear Bumper', car.rearBumper, car.rearBumperImages),
      _DamagedPartModel(
        'LHS Tail Lamp',
        car.lhsTailLamp,
        car.lhsTailLampImages,
      ),
      _DamagedPartModel(
        'RHS Tail Lamp',
        car.rhsTailLamp,
        car.rhsTailLampImages,
      ),
      _DamagedPartModel(
        'Rear Windshield',
        car.rearWindshield,
        car.rearWindshieldImages,
      ),
      _DamagedPartModel(
        'Boot Door',
        car.bootDoor,
        car.rearMain /* fallback main rear shots */,
      ),
      _DamagedPartModel('Boot Floor', car.bootFloor, car.bootFloorImages),

      _DamagedPartModel(
        'RHS Rear Alloy',
        car.rhsRearAlloy,
        car.rhsRearAlloyImages,
      ),

      _DamagedPartModel(
        'RHS Front Alloy',
        car.rhsFrontAlloy,
        car.rhsFrontAlloyImages,
      ),

      _DamagedPartModel(
        'RHS Quarter Panel',
        car.rhsQuarterPanel,
        car.rhsQuarterPanelImages,
      ),
      _DamagedPartModel('RHS A Pillar', car.rhsAPillar, car.rhsAPillarImages),
      _DamagedPartModel('RHS B Pillar', car.rhsBPillar, car.rhsBPillarImages),
      _DamagedPartModel('RHS C Pillar', car.rhsCPillar, car.rhsCPillarImages),
      _DamagedPartModel(
        'RHS Running Border',
        car.rhsRunningBorder,
        car.rhsRunningBorderImages,
      ),
      _DamagedPartModel(
        'RHS Rear Door',
        car.rhsRearDoor,
        car.rhsRearDoorImages,
      ),
      _DamagedPartModel(
        'RHS Front Door',
        car.rhsFrontDoor,
        car.rhsFrontDoorImages,
      ),
      _DamagedPartModel('RHS ORVM', car.rhsOrvm, car.rhsOrvmImages),
      _DamagedPartModel('RHS Fender', car.rhsFender, car.rhsFenderImages),

      // ---- Engine bay / mechanicals ----
      _DamagedPartModel('Battery', car.battery, car.batteryImages),
      // _DamagedPartModel('Upper Cross Member', car.upperCrossMember, car.engineBay),
      // _DamagedPartModel('Radiator Support', car.radiatorSupport, car.engineBay),
      // _DamagedPartModel('Headlight Support', car.headlightSupport, car.engineBay),
      // _DamagedPartModel('Lower Cross Member', car.lowerCrossMember, car.engineBay),
      // _DamagedPartModel('LHS Apron', car.lhsApron, car.apronLhsRhs),
      // _DamagedPartModel('RHS Apron', car.rhsApron, car.apronLhsRhs),
      // _DamagedPartModel('Firewall', car.firewall, car.engineBay),
      // _DamagedPartModel('Cowl Top', car.cowlTop, car.engineBay),
      // _DamagedPartModel('Engine', car.engine, car.engineBay),
      // _DamagedPartModel('Coolant', car.coolant, car.engineBay),
      // _DamagedPartModel('Engine Oil Dipstick', car.engineOilLevelDipstick, car.engineBay),
      // _DamagedPartModel('Engine Oil', car.engineOil, car.engineBay),
      // _DamagedPartModel('Engine Mount', car.engineMount, car.engineBay),
      // _DamagedPartModel('Permissible Blow-By', car.enginePermisableBlowBy, car.engineSound),
      // _DamagedPartModel('Exhaust Smoke', car.exhaustSmoke, car.exhaustSmokeImages),
      // _DamagedPartModel('Clutch', car.clutch, car.engineBay),
      // _DamagedPartModel('Gear Shift', car.gearShift, car.engineBay),

      // ---- Interior / features (use available images as proxies) ----
      _DamagedPartModel(
        'Electricals',
        car.electricals,
        car.meterConsoleWithEngineOn,
      ),
      _DamagedPartModel(
        'Airbags',
        '${car.noOfAirBags} | ${car.airbagFeaturesDriverSide} | ${car.airbagFeaturesCoDriverSide}',
        car.airbags,
      ),
      _DamagedPartModel('Sunroof', car.sunroof, car.sunroofImages),
      _DamagedPartModel(
        'Front Seats',
        car.commentOnInterior,
        car.frontSeatsFromDriverSideDoorOpen,
      ),
      _DamagedPartModel(
        'Rear Seats',
        car.commentOnInterior,
        car.rearSeatsFromRightSideDoorOpen,
      ),
      _DamagedPartModel(
        'Dashboard',
        car.commentOnInterior,
        car.dashboardFromRearSeat,
      ),
    ];

    final seen = <String>{};
    final damagedImages = <String>[];

    for (final p in parts) {
      if (_isDamageStatus(p.status)) {
        for (final url in p.images) {
          if (url.isNotEmpty && _isValidImageUrl(url) && seen.add(url)) {
            damagedImages.add(url);
          }
        }
      }
    }

    // Also include any "additional" images under the same Damages section (client asked).
    for (final extra in [...car.additionalImages, ...car.additionalImages2]) {
      if (extra.isNotEmpty && seen.add(extra)) {
        damagedImages.add(extra);
      }
    }
    return damagedImages;
  }

  // Helper: check if a part is damaged
  bool _isDamageStatus(String? s) {
    if (s == null) return false; // ignore nulls
    final v = s.trim().toLowerCase();
    // Only these 3 mean "not a damage"
    return !(v == 'okay' || v == 'replaced' || v == 'not applicable');
  }

  // Helper: Check if image URL is valid
  bool _isValidImageUrl(String? s) {
    if (s == null) return false;
    final u = s.trim();
    if (u.isEmpty) return false;

    // Allow http/https (covers cloudinary, gdrive, s3, etc.)
    final uri = Uri.tryParse(u);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return true;
    }

    return false;
  }
}

//  Damaged Part Model
class _DamagedPartModel {
  final String label;
  final String? status;
  final List<String> images;
  const _DamagedPartModel(this.label, this.status, this.images);
}
