class Variable {
  final String id;
  final String kdRecord;
  final String kdWits;
  final String param;
  final String name;
  final String field;
  final String? cluster;

  Variable({
    required this.id,
    required this.kdRecord,
    required this.kdWits,
    required this.param,
    required this.name,
    required this.field,
    this.cluster,
  });

  factory Variable.fromJson(Map<String, dynamic> json) {
    return Variable(
      id:        json['id']        != null ? json['id'].toString()        : '',
      kdRecord:  json['kd_record'] != null ? json['kd_record'].toString() : '',
      kdWits:    json['kd_wits']   != null ? json['kd_wits'].toString()   : '',
      param:     json['param']     != null ? json['param'].toString()     : '',
      name:      json['name']      != null ? json['name'].toString()      : '',
      field:     json['field']     != null ? json['field'].toString()     : '',
      cluster:   json['cluster']?.toString(),
    );
  }
}