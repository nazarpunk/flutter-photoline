import 'package:flutter/foundation.dart';

class PhotolineDummys {
  PhotolineDummys._();

  static Uri item(int a, int b) {
    final la = _dummys[a % _dummys.length];
    return Uri.parse(la[b % la.length]);
  }

  static List<Uri> list(int a) => _dummys[a % _dummys.length].map(Uri.parse).toList();

  static int _a = 1;
  static int _b = -1;

  static Uri next() {
    if (_b >= _dummys[_a].length - 1) {
      _a++;
      _b = -1;
    }
    _b++;
    return Uri.parse(_dummys[_a][_b]);
  }
}

List<String> _gen(String template, int count, {int start = 0, int pad = 2}) => List.generate(count, (i) {
      final num = (i + start).toString().padLeft(pad, '0');
      return template.replaceFirst('{}', num);
    });

final _dummys = [
  if (kProfileMode) ...[
    _gen('https://content3.erosberry.com/watch4beauty.com/12763/{}.jpg', 16),
    _gen('https://content3.erosberry.com/femjoy.com/19589/{}.jpg', 16),
    _gen('https://content9.erosberry.com/zishy.com/2686/{}.jpg', 10),
    _gen('https://content9.erosberry.com/domai.com/1446/{}.jpg', 14),
    _gen('https://content9.erosberry.com/met-art.com/27716/{}.jpg', 14),
    _gen('https://content3.erosberry.com/femjoy.com/19590/{}.jpg', 16),
    _gen('https://content3.erosberry.com/averotica.com/0951/{}.jpg', 16),
    _gen('https://content3.erosberry.com/sexart.com/10546/{}.jpg', 16),
    _gen('https://content3.erosberry.com/suicidegirls.com/1553/{}.jpg', 15),
    _gen('https://content3.erosberry.com/femjoy.com/19595/{}.jpg', 16),
    _gen('https://content9.erosberry.com/met-art.com/57568/{}.jpg', 16),
    _gen('https://content9.erosberry.com/met-art.com/57567/{}.jpg', 15),
    _gen('https://content9.erosberry.com/met-art.com/15238/{}.jpg', 13),
    _gen('https://content3.erosberry.com/photodromm.com/7198/{}.jpg', 12),
    _gen('https://content3.erosberry.com/met-art.com/57573/{}.jpg', 16),
    _gen('https://content3.erosberry.com/stasyq.com/1795/{}.jpg', 14),
    _gen('https://content3.erosberry.com/art-lingerie.com/0789/{}.jpg', 12),
    _gen('https://content3.erosberry.com/met-art.com/57592/{}.jpg', 16),
    _gen('https://content3.erosberry.com/zemani.com/0815/{}.jpg', 12),
    _gen('https://content9.erosberry.com/photodromm.com/7202/{}.jpg', 12),
    _gen('https://content3.erosberry.com/stasyq.com/1798/{}.jpg', 12),
    _gen('https://content9.erosberry.com/eroticbeauty.com/1069/{}.jpg', 12),
    _gen('https://content3.erosberry.com/watch4beauty.com/12781/{}.jpg', 16),
    _gen('https://content9.erosberry.com/sexart.com/10582/{}.jpg', 16),
    _gen('https://cdn.elitebabes.com/content/2210118/0001-{}_1200.jpg', 15, start: 1)
  ],
  _gen('https://cdn.elitebabes.com/content/190267/0004-{}.jpg', 20, start: 1),
  _gen('https://cdn.elitebabes.com/content/190922/0005-{}.jpg', 15, start: 1),
  _gen('https://cdn.elitebabes.com/content/231261/0008-{}_1200.jpg', 18, start: 1),
  _gen('https://cdn.elitebabes.com/content/240306/0001-{}_1200.jpg', 15, start: 1),
  _gen('https://cdn.elitebabes.com/content/190103/0005-{}.jpg', 20, start: 1),
  _gen('https://cdn.elitebabes.com/content/190127/0001-{}.jpg', 15, start: 1),
  _gen('https://cdn.elitebabes.com/content/171039/0005-{}.jpg', 20, start: 1),
  _gen('https://cdn.elitebabes.com/content/240128/0001-{}_1200.jpg', 15, start: 1),
];
