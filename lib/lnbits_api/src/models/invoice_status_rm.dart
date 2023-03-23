class InvoiceStatusRM {
  final bool paid;
  final String preimage;

  InvoiceStatusRM({
    required this.paid,
    required this.preimage,
  });

  factory InvoiceStatusRM.fromJson(Map<String, dynamic> json) {
    return InvoiceStatusRM(
      paid: json['paid'],
      preimage: json['preimage'],
    );
  }
}
