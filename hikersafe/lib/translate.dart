import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;

class Translate {
  final translator = GoogleTranslator();

  printText(List text) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? language = pref.getString('language');
    if (language != "en") {
      language = 'zh-tw';
    }
    String val = "";
    final response = await http.get(Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?target=$language&key=AIzaSyBfG6onSh1iHDdGpDH_A5ukn995O-vyYX8&q=$text'));
    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      val = jsonDecode(response.body)['data']['translations'][0]
          ['translatedText'];
    }
    print(val);
  }
}
