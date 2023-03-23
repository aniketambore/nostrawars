class InvoiceRM {
  final String paymentHash;
  final String paymentRequest;
  final String checkingId;

  InvoiceRM({
    required this.paymentHash,
    required this.paymentRequest,
    required this.checkingId,
  });

  factory InvoiceRM.fromJson(Map<String, dynamic> json) {
    return InvoiceRM(
      paymentHash: json['payment_hash'],
      paymentRequest: json['payment_request'],
      checkingId: json['checking_id'],
    );
  }
}
