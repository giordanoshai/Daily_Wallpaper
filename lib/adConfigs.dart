import 'dart:convert';
import 'package:http/http.dart' as http;

class AdConfig {

  static const String idUrl = 'https://www.ggwp.cn/ad_id.json';
  static int currentAdIdIndex = 0;

  static Future<String> getInterstitialId() async {

    String interstitialID = '';
    final response = await http.get(Uri.parse(idUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<dynamic> adIds = data[0]['adId'].values.toList();
      interstitialID = adIds[currentAdIdIndex % adIds.length];

      currentAdIdIndex++;
      if (currentAdIdIndex >= adIds.length) {
        currentAdIdIndex = 0;
      }
      return interstitialID;
    } else {
      throw Exception('Failed to get banner ID');
    }
  }

}

