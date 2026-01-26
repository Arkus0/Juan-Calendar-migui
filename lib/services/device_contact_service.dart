import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceContactService {
  Future<bool> requestPermission() async {
    var status = await Permission.contacts.status;
    if (status.isDenied || status.isLimited) {
      status = await Permission.contacts.request();
    }
    return status.isGranted;
  }

  Future<void> saveContact({
    required String firstName,
    required String phone,
  }) async {
    final bool granted = await requestPermission();
    if (!granted) {
      throw 'Permiso de contactos denegado';
    }

    Contact newContact = Contact(
      givenName: firstName,
      phones: [Item(label: 'mobile', value: phone)],
    );

    await ContactsService.addContact(newContact);
  }
}
