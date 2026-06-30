class CampaignModel {
  final String id;
  final String name;
  final String description;
  final String objective;
  final String startDate;
  final String endDate;
  final String status;
  final List<Visitor> visitors;
  final int progress;
  final int totalVisits;
  final int completedVisits;
  final int pendingVisits;
  final CreatedBy createdBy;
  final String createdAt;
  final String updatedAt;

  CampaignModel({
    required this.id,
    required this.name,
    required this.description,
    required this.objective,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.visitors,
    required this.progress,
    required this.totalVisits,
    required this.completedVisits,
    required this.pendingVisits,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      objective: json['objective'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? '',
      visitors:
          (json['visitors'] as List?)
              ?.map((v) => Visitor.fromJson(v))
              .toList() ??
          [],
      progress: json['progress'] ?? 0,
      totalVisits: json['totalVisits'] ?? 0,
      completedVisits: json['completedVisits'] ?? 0,
      pendingVisits: json['pendingVisits'] ?? 0,
      createdBy: CreatedBy.fromJson(json['createdBy'] ?? {}),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class Visitor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Visitor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class CreatedBy {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  CreatedBy({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class CampaignResponse {
  final List<CampaignModel> data;
  final int total;
  final int page;
  final int limit;

  CampaignResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory CampaignResponse.fromJson(Map<String, dynamic> json) {
    return CampaignResponse(
      data:
          (json['data'] as List?)
              ?.map((v) => CampaignModel.fromJson(v))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
    );
  }
}
