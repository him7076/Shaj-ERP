import 'dart:convert';
void main() {
  try {
    var r = json.decode('123e4567-e89b-12d3-a456-426614174000');
    print('Success');
  } catch (e) {
    print('Error');
  }
}