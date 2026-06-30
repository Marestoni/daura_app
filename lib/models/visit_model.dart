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
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.latitude,
    this.longitude,
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
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }
}

// ============================================
// 2. MODELO CAMPAIGN INFO
// ============================================
class CampaignInfo {
  final String id;
  final String name;
  final String status;

  CampaignInfo({required this.id, required this.name, required this.status});

  factory CampaignInfo.fromJson(Map<String, dynamic> json) {
    return CampaignInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
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

  VisitorInfo({required this.id, required this.name, required this.email});

  factory VisitorInfo.fromJson(Map<String, dynamic> json) {
    return VisitorInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

// ============================================
// 4. MODELO VISIT
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
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando VisitModel: $json');

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
          );

    final campaign =
        json['campaign'] != null && json['campaign'] is Map<String, dynamic>
        ? CampaignInfo.fromJson(json['campaign'])
        : CampaignInfo(id: '', name: '', status: '');

    final visitor =
        json['visitor'] != null && json['visitor'] is Map<String, dynamic>
        ? VisitorInfo.fromJson(json['visitor'])
        : VisitorInfo(id: '', name: '', email: '');

    return VisitModel(
      id: json['id']?.toString() ?? '',
      visitorId: json['visitorId']?.toString() ?? '',
      campaignId: json['campaignId']?.toString() ?? '',
      addressId: json['addressId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString(),
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      completedDate: json['completedDate']?.toString(),
      address: address,
      campaign: campaign,
      visitor: visitor,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

// ============================================
// 5. MODELO VISIT RESPONSE
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
