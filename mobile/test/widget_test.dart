import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_3d_home/core/app_state.dart';
import 'package:spatial_3d_home/core/security/crypto_service.dart';
import 'package:spatial_3d_home/core/utils/formatters.dart';
import 'package:spatial_3d_home/main.dart';
import 'package:spatial_3d_home/models/app_models.dart';
import 'package:spatial_3d_home/services/pdf_export_service.dart';

void main() {
  group('Domain & RBAC Unit Tests', () {
    test('Seed KPI totals match baseline Villa Kemang Selatan #14B', () {
      final state = AppState();
      expect(state.rooms.length, 4);
      expect(state.totalAreaSqm, closeTo(111.0, 0.01));
      expect(state.visibleAssets.length, 8);
      expect(state.totalPurchaseValue, closeTo(433000000, 0.1));
      expect(state.totalCurrentValuation, closeTo(402925000, 0.1));
      expect(state.verifiedAssetsPct, closeTo(62.5, 0.01));
    });

    test('Tenant RBAC masks financials and restricts private assets', () {
      final state = AppState();
      state.loginWithRole(UserRole.tenant);
      expect(state.visibleAssets.length, 4);
      expect(state.totalPurchaseValue, 0);
      expect(state.totalCurrentValuation, 0);

      // Tenant cannot delete assets or manage server config
      final beforeCount = state.visibleAssets.length;
      state.deleteOrArchiveAsset(state.visibleAssets.first.id);
      expect(state.visibleAssets.length, beforeCount);
      expect(state.currentRole.canManageServerConfig, isFalse);
      expect(state.currentRole.canExportClaim, isFalse);
    });

    test('Inspector can verify appraisal without deleting owner assets', () {
      final state = AppState();
      state.loginWithRole(UserRole.inspector);
      // Inspector sees ALL_AUTHORIZED + INSURANCE_ONLY (7 of 8, excluding OWNER_PRIVATE Rolex)
      expect(state.visibleAssets.length, 7);

      final pendingAsset = state.visibleAssets
          .firstWhere((a) => a.verificationStatus == VerificationStatus.pending);
      state.verifyAppraisal(
        assetId: pendingAsset.id,
        appraisedValue: 35000000,
        status: VerificationStatus.verified,
        note: 'Verified physical condition',
      );
      final updated = state.visibleAssets.firstWhere((a) => a.id == pendingAsset.id);
      expect(updated.verificationStatus, VerificationStatus.verified);
      expect(updated.appraisedValue, 35000000);

      // Delete is rejected for Inspector
      state.deleteOrArchiveAsset(pendingAsset.id);
      expect(state.visibleAssets.length, 7);
    });

    test('Straight-line depreciation obeys salvage floor', () {
      final val = SpatialMath.calculateStraightLineValuation(
        purchasePrice: 10000000,
        category: AssetCategory.electronics,
        purchaseDate: DateTime(2015, 1, 1),
        referenceDate: DateTime(2026, 1, 1),
      );
      // 10% salvage floor for electronics
      expect(val, closeTo(1000000, 0.1));
    });

    test('SHA-256 and PDF export produce deterministic integrity hash', () {
      expect(
        CryptoService.sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );

      final state = AppState();
      final result = PdfExportService.buildBundle(
        rooms: state.rooms,
        visibleAssets: state.visibleAssets,
        actorRole: UserRole.inspector,
        format: 'PDF_PREVIEW',
      );
      expect(result.sha256Integrity.length, 64);
      expect(result.appraiserStamped, isTrue);
      expect(result.content, contains('APPRAISER VERIFIED STAMP'));
    });
  });

  testWidgets('Spatial 3D Home login smoke and quick role switch test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Spatial3DHomeApp());
    await tester.pumpAndSettle();

    expect(find.text('SPATIAL 3D HOME'), findsOneWidget);
    expect(find.text('LiDAR Property & Asset Vault'), findsOneWidget);

    final ownerQuickButton = find.text('Owner');
    expect(ownerQuickButton, findsWidgets);

    await tester.tap(ownerQuickButton.first);
    await tester.pumpAndSettle();

    expect(find.text('Villa Kemang Selatan #14B'), findsOneWidget);
    expect(find.text('BENTO KPI OVERVIEW'), findsOneWidget);
    expect(find.text('Home 3D'), findsOneWidget);
    expect(find.text('Inventaris'), findsOneWidget);
  });
}
