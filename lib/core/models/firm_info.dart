import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';

class FirmInfo {
  final String name;
  final String gst;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String bankName;
  final String bankAcc;
  final String ifsc;
  final String upi;

  const FirmInfo({
    this.name = 'Business Sahaj ERP',
    this.gst = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.bankName = '',
    this.bankAcc = '',
    this.ifsc = '',
    this.upi = '',
  });

  String get fullAddress {
    final parts = [address, city, state, pincode].where((p) => p != null && p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'Main Market Area';
    return parts.join(', ');
  }

  static Future<FirmInfo> getActiveFirmInfo(SharedPreferences prefs, Isar isar) async {
    final activeId = prefs.getString('active_firm_id') ?? 'firm_default';

    String name = prefs.getString('firm_name_$activeId') ?? '';
    String gst = prefs.getString('firm_gst_$activeId') ?? '';
    String phone = prefs.getString('firm_mobile_$activeId') ?? '';
    String email = prefs.getString('firm_email_$activeId') ?? '';
    String address = prefs.getString('firm_address_$activeId') ?? '';
    String city = prefs.getString('firm_city_$activeId') ?? '';
    String state = prefs.getString('firm_state_$activeId') ?? '';
    String pincode = prefs.getString('firm_pincode_$activeId') ?? '';
    String bankName = prefs.getString('firm_bank_name_$activeId') ?? '';
    String bankAcc = prefs.getString('firm_bank_acc_$activeId') ?? '';
    String ifsc = prefs.getString('firm_ifsc_$activeId') ?? '';
    String upi = prefs.getString('firm_upi_$activeId') ?? '';

    // Fallback to Isar Settings if SharedPreferences firm fields are empty
    try {
      final isarSettings = await isar.settings.filter().idGreaterThan(-1).findFirst();
      if (isarSettings != null) {
        if (name.trim().isEmpty) name = isarSettings.companyName ?? '';
        if (gst.trim().isEmpty) gst = isarSettings.companyGST ?? '';
        if (phone.trim().isEmpty) phone = isarSettings.companyPhone ?? '';
        if (address.trim().isEmpty) address = isarSettings.companyAddress ?? '';
      }
    } catch (_) {}

    if (name.trim().isEmpty) name = 'Business Sahaj ERP';

    return FirmInfo(
      name: name,
      gst: gst,
      phone: phone,
      email: email,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      bankName: bankName,
      bankAcc: bankAcc,
      ifsc: ifsc,
      upi: upi,
    );
  }
}
