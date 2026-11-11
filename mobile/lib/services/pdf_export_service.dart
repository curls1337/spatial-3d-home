import 'dart:convert';
import '../core/app_state.dart';
import '../core/security/crypto_service.dart';
import '../data/seed_data.dart';
import '../models/app_models.dart';

class ExportDocumentResult {
  final String reportId;
  final String bundleType;
  final String format;
  final DateTime generatedAtUtc;
  final String sha256Integrity;
  final bool appraiserStamped;
  final double totalClaimedValue;
  final int assetCount;
  final String content;

  const ExportDocumentResult({
    required this.reportId,
    required this.bundleType,
    required this.format,
    required this.generatedAtUtc,
    required this.sha256Integrity,
    required this.appraiserStamped,
    required this.totalClaimedValue,
    required this.assetCount,
    required this.content,
  });
}

class PdfExportService {
  PdfExportService._();

  static ExportDocumentResult buildBundle({
    required List<Room3D> rooms,
    required List<AssetItem> visibleAssets,
    required UserRole actorRole,
    required String format, // 'PDF_PREVIEW' | 'JSON' | 'CSV'
  }) {
    final now = DateTime.now().toUtc();
    final isTenant = !actorRole.canViewFinancials;
    final bundleType = isTenant ? 'LEASE_HANDOVER' : 'INSURANCE_CLAIM';
    final appraiserStamped = actorRole == UserRole.inspector;
    final totalClaimed = isTenant
        ? 0.0
        : visibleAssets.fold<double>(0, (s, a) => s + a.effectiveValuation);

    final roomNames = {for (final r in rooms) r.id: r.name};

    final canonicalRows = visibleAssets.map((a) {
      return <String, dynamic>{
        'id': a.id,
        'name': a.name,
        'room': roomNames[a.roomId] ?? a.roomId,
        'category': a.category.label,
        'serialNumber': a.serialNumber,
        'condition': a.conditionGrade,
        'verificationStatus': a.verificationStatus.label,
        'pin': {'x': a.pinX, 'y': a.pinY, 'z': a.pinZ},
        if (!isTenant) 'purchasePriceIdr': a.purchasePrice,
        if (!isTenant) 'currentValuationIdr': a.effectiveValuation,
      };
    }).toList();

    final canonicalJson = jsonEncode(<String, dynamic>{
      'property': SeedData.propertyName,
      'bundleType': bundleType,
      'actorRole': actorRole.label,
      'appraiserStamped': appraiserStamped,
      'generatedAtUtc': now.toIso8601String(),
      'totalClaimedValueIdr': totalClaimed,
      'assets': canonicalRows,
    });

    final sha256 = CryptoService.sha256Hex(canonicalJson);
    final reportId =
        'RPT-${now.year}${now.month.toString().padLeft(2, '0')}-${sha256.substring(0, 8).toUpperCase()}';

    String content;
    if (format == 'JSON') {
      content = const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'reportId': reportId,
        'bundleType': bundleType,
        'generatedAtUtc': now.toIso8601String(),
        'sha256Integrity': sha256,
        'appraiserStamped': appraiserStamped,
        'property': {
          'name': SeedData.propertyName,
          'address': SeedData.propertyAddress,
          if (!isTenant) 'policyNo': 'POL-HOME-2026-88412',
        },
        'summary': {
          'totalRooms': rooms.length,
          'totalAreaSqm': rooms.fold<double>(0, (s, r) => s + r.areaSqm),
          'assetCount': visibleAssets.length,
          if (!isTenant) 'totalClaimedValueIdr': totalClaimed,
        },
        'assets': canonicalRows,
      });
    } else if (format == 'CSV') {
      final buf = StringBuffer();
      if (isTenant) {
        buf.writeln('ID,Nama Aset,Ruangan,Kategori,Nomor Seri,Kondisi,Status');
        for (final a in visibleAssets) {
          buf.writeln(
            '"${a.id}","${_csvSafe(a.name)}","${_csvSafe(roomNames[a.roomId] ?? '')}","${a.category.label}","${_csvSafe(a.serialNumber)}","${a.conditionGrade}","${a.verificationStatus.label}"',
          );
        }
      } else {
        buf.writeln(
          'ID,Nama Aset,Ruangan,Kategori,Nomor Seri,Harga Beli (IDR),Valuasi Kini (IDR),Status Verifikasi,SHA256_Integrity',
        );
        for (final a in visibleAssets) {
          buf.writeln(
            '"${a.id}","${_csvSafe(a.name)}","${_csvSafe(roomNames[a.roomId] ?? '')}","${a.category.label}","${_csvSafe(a.serialNumber)}",${a.purchasePrice.round()},${a.effectiveValuation.round()},"${a.verificationStatus.label}","$sha256"',
          );
        }
      }
      content = buf.toString();
    } else {
      final buf = StringBuffer();
      buf.writeln('====================================================');
      buf.writeln('SPATIAL 3D HOME — VERIFIED INVENTORY & CLAIM REPORT');
      buf.writeln('====================================================');
      buf.writeln('Report ID       : $reportId');
      buf.writeln('Jenis Dokumen   : $bundleType');
      buf.writeln('Properti        : ${SeedData.propertyName}');
      buf.writeln('Timestamp (UTC) : ${now.toIso8601String()}');
      buf.writeln(
        'Stempel Audit   : ${appraiserStamped ? "APPRAISER VERIFIED STAMP" : "OWNER / DRAFT"}',
      );
      buf.writeln('----------------------------------------------------');
      buf.writeln(
        'Total Ruangan   : ${rooms.length} (${rooms.fold<double>(0, (s, r) => s + r.areaSqm).toStringAsFixed(1)} m²)',
      );
      buf.writeln('Jumlah Aset     : ${visibleAssets.length} Item');
      if (!isTenant) {
        buf.writeln('Total Nilai Klaim: ${AppState.formatIdr(totalClaimed)}');
      }
      buf.writeln('----------------------------------------------------');
      for (var i = 0; i < visibleAssets.length; i++) {
        final a = visibleAssets[i];
        final room = roomNames[a.roomId] ?? '-';
        final valPart = isTenant
            ? 'Kondisi: ${a.conditionGrade}'
            : AppState.formatIdr(a.effectiveValuation);
        buf.writeln(
          '${i + 1}. ${a.name} [$room] • S/N: ${a.serialNumber} • ${a.verificationStatus.label} • $valPart',
        );
      }
      buf.writeln('----------------------------------------------------');
      buf.writeln('SHA-256 Document Integrity Hash:');
      buf.writeln(sha256);
      content = buf.toString();
    }

    return ExportDocumentResult(
      reportId: reportId,
      bundleType: bundleType,
      format: format,
      generatedAtUtc: now,
      sha256Integrity: sha256,
      appraiserStamped: appraiserStamped,
      totalClaimedValue: totalClaimed,
      assetCount: visibleAssets.length,
      content: content,
    );
  }

  static String _csvSafe(String raw) => raw.replaceAll('"', '""');
}
