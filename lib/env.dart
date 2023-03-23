import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'lnbits-invoice-key', obfuscate: true)
  static final lnbitsInvoiceKey = _Env.lnbitsInvoiceKey;

  @EnviedField(varName: 'lnbits-admin-key', obfuscate: true)
  static final lnbitsAdminKey = _Env.lnbitsAdminKey;

  @EnviedField(varName: 'lnbits-base-url', obfuscate: true)
  static final lnbitsBaseUrl = _Env.lnbitsBaseUrl;

  @EnviedField(varName: 'lnbits-withdraw-base-url', obfuscate: true)
  static final lnbitsWithdrawBaseUrl = _Env.lnbitsWithdrawBaseUrl;
}
