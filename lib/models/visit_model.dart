// ============================================
// 1. MODELO ADDRESS
// ============================================
class Address {
  final String id;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final String? residentName;
  final String? phone;
  final String? observations;
  final double? latitude;
  final double? longitude;
  final String? sector;
  final String? groupId;
  final String? fullAddress;
  final bool? hasCoordinates;
  final String createdAt;
  final String updatedAt;

  Address({
    required this.id,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.residentName,
    this.phone,
    this.observations,
    this.latitude,
    this.longitude,
    this.sector,
    this.groupId,
    this.fullAddress,
    this.hasCoordinates,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      complement: json['complement']?.toString(),
      neighborhood: json['neighborhood']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      residentName: json['residentName']?.toString(),
      phone: json['phone']?.toString(),
      observations: json['observations']?.toString(),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      sector: json['sector']?.toString(),
      groupId: json['groupId']?.toString(),
      fullAddress: json['fullAddress']?.toString(),
      hasCoordinates: json['hasCoordinates'] as bool?,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

// ============================================
// 2. MODELO CAMPAIGN INFO
// ============================================
class CampaignInfo {
  final String id;
  final String name;
  final String? description;
  final String? objective;
  final String? startDate;
  final String? endDate;
  final String status;
  final int? progress;
  final int? totalVisits;
  final int? completedVisits;
  final int? pendingVisits;
  final dynamic createdBy;
  final String createdAt;
  final String updatedAt;

  CampaignInfo({
    required this.id,
    required this.name,
    this.description,
    this.objective,
    this.startDate,
    this.endDate,
    required this.status,
    this.progress,
    this.totalVisits,
    this.completedVisits,
    this.pendingVisits,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CampaignInfo.fromJson(Map<String, dynamic> json) {
    return CampaignInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      objective: json['objective']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      status: json['status']?.toString() ?? '',
      progress: json['progress'] as int?,
      totalVisits: json['totalVisits'] as int?,
      completedVisits: json['completedVisits'] as int?,
      pendingVisits: json['pendingVisits'] as int?,
      createdBy: json['createdBy'],
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

// ============================================
// 3. MODELO VISITOR INFO
// ============================================
class VisitorInfo {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final bool? isActive;
  final String createdAt;
  final String updatedAt;

  VisitorInfo({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitorInfo.fromJson(Map<String, dynamic> json) {
    return VisitorInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

// ============================================
// 4. MODELO PHOTO
// ============================================
class Photo {
  final String id;
  final String visitId;
  final String filename;
  final String path;
  final String mimeType;
  final int size;
  final dynamic metadata;
  final String? takenAt;
  final double? latitude;
  final double? longitude;
  final String createdAt;

  Photo({
    required this.id,
    required this.visitId,
    required this.filename,
    required this.path,
    required this.mimeType,
    required this.size,
    this.metadata,
    this.takenAt,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id']?.toString() ?? '',
      visitId: json['visitId']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: json['size'] as int? ?? 0,
      metadata: json['metadata'],
      takenAt: json['takenAt']?.toString(),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

// ============================================
// 5. MODELO VISIT (ATUALIZADO)
// ============================================
class VisitModel {
  final String id;
  final String visitorId;
  final String campaignId;
  final String addressId;
  final String status;
  final String? notes;
  final String scheduledDate;
  final String? completedDate;
  final Address address;
  final CampaignInfo campaign;
  final VisitorInfo visitor;
  final String createdAt;
  final String updatedAt;

  // ✅ NOVOS CAMPOS DO FORMULÁRIO
  final String? attempt;
  final String? startedAt;
  final String? completedAt;
  final String? observation;
  final dynamic formData;
  final dynamic answers;
  final String? attendedBy;
  final String? situation;
  final int? visitOrder;
  final double? distanceFromPrevious;
  final bool isFinished;
  final String? statusLabel;
  final String? statusColor;
  final String? attemptLabel;
  final List<Photo> photos;

  VisitModel({
    required this.id,
    required this.visitorId,
    required this.campaignId,
    required this.addressId,
    required this.status,
    this.notes,
    required this.scheduledDate,
    this.completedDate,
    required this.address,
    required this.campaign,
    required this.visitor,
    required this.createdAt,
    required this.updatedAt,
    this.attempt,
    this.startedAt,
    this.completedAt,
    this.observation,
    this.formData,
    this.answers,
    this.attendedBy,
    this.situation,
    this.visitOrder,
    this.distanceFromPrevious,
    this.isFinished = false,
    this.statusLabel,
    this.statusColor,
    this.attemptLabel,
    this.photos = const [],
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    // ✅ EXTRAIR OS DADOS COM SEGURANÇA
    final address =
        json['address'] != null && json['address'] is Map<String, dynamic>
        ? Address.fromJson(json['address'])
        : Address(
            id: '',
            street: '',
            number: '',
            neighborhood: '',
            city: '',
            state: '',
            zipCode: '',
            createdAt: '',
            updatedAt: '',
          );

    final campaign =
        json['campaign'] != null && json['campaign'] is Map<String, dynamic>
        ? CampaignInfo.fromJson(json['campaign'])
        : CampaignInfo(
            id: '',
            name: '',
            status: '',
            createdAt: '',
            updatedAt: '',
          );

    final visitor =
        json['visitor'] != null && json['visitor'] is Map<String, dynamic>
        ? VisitorInfo.fromJson(json['visitor'])
        : VisitorInfo(
            id: '',
            name: '',
            email: '',
            createdAt: '',
            updatedAt: '',
          );

    // ✅ Parse das fotos
    List<Photo> photos = [];
    if (json['photos'] != null && json['photos'] is List) {
      photos = (json['photos'] as List).map((p) => Photo.fromJson(p)).toList();
    }

    return VisitModel(
      id: json['id']?.toString() ?? '',

      // ✅ CORRIGIDO
      visitorId: visitor.id,
      campaignId: campaign.id,
      addressId: address.id,

      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString(),
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      completedDate: json['completedDate']?.toString(),

      address: address,
      campaign: campaign,
      visitor: visitor,

      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      attempt: json['attempt']?.toString(),
      startedAt: json['startedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      observation: json['observation']?.toString(),
      formData: json['formData'],
      answers: json['answers'],
      attendedBy: json['attendedBy']?.toString(),
      situation: json['situation']?.toString(),
      visitOrder: json['visitOrder'] as int?,
      distanceFromPrevious: json['distanceFromPrevious'] != null
          ? (json['distanceFromPrevious'] as num).toDouble()
          : null,
      isFinished: json['isFinished'] ?? false,
      statusLabel: json['statusLabel']?.toString(),
      statusColor: json['statusColor']?.toString(),
      attemptLabel: json['attemptLabel']?.toString(),
      photos: photos,
    );
  }
}

// ============================================
// 6. MODELO VISIT RESPONSE
// ============================================
class VisitResponse {
  final List<VisitModel> data;
  final int total;
  final int page;
  final int limit;

  VisitResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory VisitResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando VisitResponse: $json');

    List<VisitModel> dataList = [];

    // ✅ TENTAR DIFERENTES ESTRUTURAS DE RESPOSTA
    if (json['data'] != null && json['data'] is List) {
      dataList = (json['data'] as List)
          .map((v) => VisitModel.fromJson(v))
          .toList();
    } else if (json['visits'] != null && json['visits'] is List) {
      dataList = (json['visits'] as List)
          .map((v) => VisitModel.fromJson(v))
          .toList();
    } else if (json is List) {
      dataList = (json as List).map((v) => VisitModel.fromJson(v)).toList();
    }

    // ✅ FUNÇÃO SEGURA PARA CONVERTER PARA INT
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      if (value is double) {
        return value.toInt();
      }
      if (value is bool) {
        return value ? 1 : 0;
      }
      return 0;
    }

    // ✅ TENTAR PEGAR total, page, limit de diferentes lugares
    int total = safeParseInt(json['total']);
    int page = safeParseInt(json['page']);
    int limit = safeParseInt(json['limit']);

    // Se não encontrou no root, tentar procurar em data
    if (total == 0 &&
        json['data'] != null &&
        json['data'] is Map<String, dynamic>) {
      total = safeParseInt(json['data']['total']);
      page = safeParseInt(json['data']['page']);
      limit = safeParseInt(json['data']['limit']);
    }

    // Fallback: usar o tamanho da lista
    if (total == 0) {
      total = dataList.length;
    }
    if (page == 0) {
      page = 1;
    }
    if (limit == 0 && dataList.isNotEmpty) {
      limit = dataList.length;
    }

    print('✅ VisitResponse - dataList.length: ${dataList.length}');
    print('✅ VisitResponse - total: $total');
    print('✅ VisitResponse - page: $page');
    print('✅ VisitResponse - limit: $limit');

    return VisitResponse(
      data: dataList,
      total: total,
      page: page,
      limit: limit,
    );
  }
}
