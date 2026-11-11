import 'package:flutter/material.dart';

enum UserRole {
  owner,
  inspector,
  tenant,
}

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.inspector:
        return 'Inspector';
      case UserRole.tenant:
        return 'Tenant';
    }
  }

  String get subtitle {
    switch (this) {
      case UserRole.owner:
        return 'Pemilik Properti • Full CRUD';
      case UserRole.inspector:
        return 'Appraiser B2B • Audit & Verifikasi';
      case UserRole.tenant:
        return 'Penyewa • View-Only (Masked)';
    }
  }

  bool get canViewFinancials => this != UserRole.tenant;
  bool get canScanLidar => this != UserRole.tenant;
  bool get canCreateOrDeleteAsset => this == UserRole.owner;
  bool get canEditOwnerFields => this == UserRole.owner;
  bool get canAppraiseAsset => this == UserRole.inspector;
  bool get canExportClaim => this != UserRole.tenant;
  bool get canManageServerConfig => this == UserRole.owner;
  bool get canManageShareLinks => this == UserRole.owner;
}

enum AssetCategory {
  electronics,
  furniture,
  appliances,
  collectibles,
}

extension AssetCategoryExt on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.electronics:
        return 'Elektronik';
      case AssetCategory.furniture:
        return 'Furnitur';
      case AssetCategory.appliances:
        return 'Perangkat';
      case AssetCategory.collectibles:
        return 'Koleksi';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetCategory.electronics:
        return Icons.devices_rounded;
      case AssetCategory.furniture:
        return Icons.chair_rounded;
      case AssetCategory.appliances:
        return Icons.kitchen_rounded;
      case AssetCategory.collectibles:
        return Icons.diamond_rounded;
    }
  }
}

enum VerificationStatus {
  verified,
  pending,
  flagged,
}

extension VerificationStatusExt on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.flagged:
        return 'Flagged';
    }
  }
}

enum VisibilityScope {
  allAuthorized,
  insuranceOnly,
  ownerPrivate,
}

extension VisibilityScopeExt on VisibilityScope {
  String get label {
    switch (this) {
      case VisibilityScope.allAuthorized:
        return 'ALL_AUTHORIZED';
      case VisibilityScope.insuranceOnly:
        return 'INSURANCE_ONLY';
      case VisibilityScope.ownerPrivate:
        return 'OWNER_PRIVATE';
    }
  }

  String get displayName {
    switch (this) {
      case VisibilityScope.allAuthorized:
        return 'Semua Akses (Termasuk Tenant)';
      case VisibilityScope.insuranceOnly:
        return 'Owner & Inspector Asuransi';
      case VisibilityScope.ownerPrivate:
        return 'Privat Pemilik Saja';
    }
  }
}

enum WarrantyState {
  active,
  expiringSoon,
  expired,
  noWarranty,
}

class Room3D {
  final String id;
  final String name;
  final int floorLevel;
  final double areaSqm;
  final double widthM;
  final double depthM;
  final double heightM;
  final double offsetX;
  final double offsetY;
  final double offsetZ;
  final bool scanVerified;
  final String scanSource;
  final Color accentColor;

  const Room3D({
    required this.id,
    required this.name,
    required this.floorLevel,
    required this.areaSqm,
    required this.widthM,
    required this.depthM,
    required this.heightM,
    required this.offsetX,
    required this.offsetY,
    required this.offsetZ,
    required this.scanVerified,
    required this.scanSource,
    required this.accentColor,
  });

  Room3D copyWith({
    String? name,
    bool? scanVerified,
    String? scanSource,
    double? areaSqm,
  }) {
    return Room3D(
      id: id,
      name: name ?? this.name,
      floorLevel: floorLevel,
      areaSqm: areaSqm ?? this.areaSqm,
      widthM: widthM,
      depthM: depthM,
      heightM: heightM,
      offsetX: offsetX,
      offsetY: offsetY,
      offsetZ: offsetZ,
      scanVerified: scanVerified ?? this.scanVerified,
      scanSource: scanSource ?? this.scanSource,
      accentColor: accentColor,
    );
  }
}

class AssetItem {
  final String id;
  final String roomId;
  final String name;
  final AssetCategory category;
  final String serialNumber;
  final double purchasePrice;
  final double currentValuation;
  final double? appraisedValue;
  final DateTime purchaseDate;
  final DateTime? warrantyExpiryDate;
  final VerificationStatus verificationStatus;
  final VisibilityScope visibilityScope;
  final String conditionGrade;
  final double pinX;
  final double pinY;
  final double pinZ;
  final String appraisalNote;
  final String tenantConditionNote;
  final bool isClaimed;
  final bool isArchived;

  const AssetItem({
    required this.id,
    required this.roomId,
    required this.name,
    required this.category,
    required this.serialNumber,
    required this.purchasePrice,
    required this.currentValuation,
    this.appraisedValue,
    required this.purchaseDate,
    this.warrantyExpiryDate,
    required this.verificationStatus,
    required this.visibilityScope,
    required this.conditionGrade,
    required this.pinX,
    required this.pinY,
    required this.pinZ,
    this.appraisalNote = '',
    this.tenantConditionNote = '',
    this.isClaimed = false,
    this.isArchived = false,
  });

  double get effectiveValuation => appraisedValue ?? currentValuation;

  WarrantyState get warrantyState {
    if (warrantyExpiryDate == null) return WarrantyState.noWarranty;
    final now = DateTime.now();
    final diff = warrantyExpiryDate!.difference(now).inDays;
    if (diff < 0) return WarrantyState.expired;
    if (diff <= 30) return WarrantyState.expiringSoon;
    return WarrantyState.active;
  }

  int get warrantyDaysRemaining {
    if (warrantyExpiryDate == null) return 0;
    return warrantyExpiryDate!.difference(DateTime.now()).inDays;
  }

  bool isVisibleTo(UserRole role) {
    if (isArchived) return false;
    switch (role) {
      case UserRole.owner:
        return true;
      case UserRole.inspector:
        return visibilityScope != VisibilityScope.ownerPrivate;
      case UserRole.tenant:
        return visibilityScope == VisibilityScope.allAuthorized;
    }
  }

  AssetItem copyWith({
    String? roomId,
    String? name,
    AssetCategory? category,
    String? serialNumber,
    double? purchasePrice,
    double? currentValuation,
    double? appraisedValue,
    DateTime? purchaseDate,
    DateTime? warrantyExpiryDate,
    VerificationStatus? verificationStatus,
    VisibilityScope? visibilityScope,
    String? conditionGrade,
    double? pinX,
    double? pinY,
    double? pinZ,
    String? appraisalNote,
    String? tenantConditionNote,
    bool? isClaimed,
    bool? isArchived,
  }) {
    return AssetItem(
      id: id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      category: category ?? this.category,
      serialNumber: serialNumber ?? this.serialNumber,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValuation: currentValuation ?? this.currentValuation,
      appraisedValue: appraisedValue ?? this.appraisedValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      visibilityScope: visibilityScope ?? this.visibilityScope,
      conditionGrade: conditionGrade ?? this.conditionGrade,
      pinX: pinX ?? this.pinX,
      pinY: pinY ?? this.pinY,
      pinZ: pinZ ?? this.pinZ,
      appraisalNote: appraisalNote ?? this.appraisalNote,
      tenantConditionNote: tenantConditionNote ?? this.tenantConditionNote,
      isClaimed: isClaimed ?? this.isClaimed,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

class ActivityEvent {
  final String id;
  final String title;
  final String subtitle;
  final String timestampLabel;
  final VerificationStatus status;

  const ActivityEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestampLabel,
    required this.status,
  });
}

class ShareLinkItem {
  final String id;
  final UserRole targetRole;
  final String label;
  final int ttlHours;
  final bool hasPin;
  final DateTime createdAt;
  final bool revoked;

  const ShareLinkItem({
    required this.id,
    required this.targetRole,
    required this.label,
    required this.ttlHours,
    required this.hasPin,
    required this.createdAt,
    this.revoked = false,
  });

  ShareLinkItem copyWith({bool? revoked}) {
    return ShareLinkItem(
      id: id,
      targetRole: targetRole,
      label: label,
      ttlHours: ttlHours,
      hasPin: hasPin,
      createdAt: createdAt,
      revoked: revoked ?? this.revoked,
    );
  }
}
