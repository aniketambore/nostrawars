class WithdrawLinkRM {
  final String id;
  final String title;
  final int waitTime;
  final int openTime;
  final int used;
  final String lnurl;

  WithdrawLinkRM({
    required this.id,
    required this.title,
    required this.waitTime,
    required this.openTime,
    required this.used,
    required this.lnurl,
  });

  factory WithdrawLinkRM.fromJson(Map<String, dynamic> json) {
    return WithdrawLinkRM(
      id: json['id'],
      title: json['title'],
      waitTime: json['wait_time'],
      openTime: json['open_time'],
      used: json['used'],
      lnurl: json['lnurl'],
    );
  }
}
