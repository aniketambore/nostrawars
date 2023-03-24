import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nostrawars/env.dart';
import 'models/models.dart';

class LNBitsApi {
  // Create an invoice
  static Future<InvoiceRM> createInvoice({
    required int amount,
    required String memo,
    required String unit,
  }) async {
    final url = Uri.parse('${Env.lnbitsBaseUrl}/payments');
    final headers = {
      "X-Api-Key": Env.lnbitsInvoiceKey,
      "Content-Type": "application/json",
    };
    final body = {
      "out": false,
      "amount": amount,
      "memo": memo,
      "unit": unit,
    };
    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));
    final statusCode = response.statusCode;
    if (statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final invoice = InvoiceRM.fromJson(responseData);
      return invoice;
    } else {
      // throw Exception('Failed to create invoice. Status code: $statusCode');
      throw CreateInvoiceLNBitsException();
    }
  }

  // Check the status of an invoice
  static Future<InvoiceStatusRM> checkInvoiceStatus(String paymentHash) async {
    final url = Uri.parse('${Env.lnbitsBaseUrl}/payments/$paymentHash');
    final headers = {'X-Api-Key': Env.lnbitsInvoiceKey};
    final response = await http.get(url, headers: headers);
    final statusCode = response.statusCode;
    if (statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final invoiceStatus = InvoiceStatusRM.fromJson(responseData);
      return invoiceStatus;
    } else {
      // throw Exception('Failed to check invoice status. Status code: $statusCode');
      throw CheckInvoiceStatusLNBitsException();
    }
  }

  // Create a withdraw link
  static Future<WithdrawLinkRM> createWithdrawLink({
    required String title,
    required int minWithdrawable,
    required int maxWithdrawable,
    required int uses,
    required int waitTime,
    required bool isUnique,
  }) async {
    final url = Uri.parse('${Env.lnbitsWithdrawBaseUrl}/links');
    final headers = {
      'X-Api-Key': Env.lnbitsAdminKey,
      "Content-Type": "application/json",
    };
    final body = {
      'title': title,
      'min_withdrawable': minWithdrawable,
      'max_withdrawable': maxWithdrawable,
      'uses': uses,
      'wait_time': waitTime,
      'is_unique': isUnique,
    };
    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));
    final statusCode = response.statusCode;
    if (statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final withdrawLink = WithdrawLinkRM.fromJson(responseData);
      return withdrawLink;
    } else {
      // throw Exception(
      //     'Failed to create withdraw link. Status code: $statusCode');
      throw CreateWithdrawLinkLNBitsException();
    }
  }
}
