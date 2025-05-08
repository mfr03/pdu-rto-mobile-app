class Unit {
  final String unitId;
  final String unitmne;
  final String unitabv;
  final String unitfact;
  final String unitoffs;
  final String cluster;
  final String? createdAt;
  final String? updatedAt;
  final String isDeleted;
  final String clustername;

  Unit({
    required this.unitId,
    required this.unitmne,
    required this.unitabv,
    required this.unitfact,
    required this.unitoffs,
    required this.cluster,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
    required this.clustername,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      unitId:      json['unit_id']    ?.toString() ?? '',
      unitmne:     json['unitmne']     ?.toString() ?? '',
      unitabv:     json['unitabv']     ?.toString() ?? '',
      unitfact:    json['unitfact']    ?.toString() ?? '',
      unitoffs:    json['unitoffs']    ?.toString() ?? '',
      cluster:     json['cluster']     ?.toString() ?? '',
      createdAt:   json['createdAt']?.toString() ?? '',
      updatedAt:   json['updatedAt']?.toString() ?? '',
      isDeleted:   json['isDeleted']   ?.toString() ?? '',
      clustername: json['clustername'] ?.toString() ?? '',
    );
  }
}
