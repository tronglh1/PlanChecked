/// Climate/region grouping used for the helper text under the location field.
enum VnRegion { north, central, south }

class Province {
  const Province(this.code, this.name, this.region);

  /// Stable slug stored in `users.province_code`.
  final String code;

  /// Display name (Vietnamese; official names are used for both locales).
  final String name;
  final VnRegion region;
}

/// The 34 provincial-level units in force since the 2025 merger
/// (28 provinces + 6 centrally-governed cities). Region level only.
const List<Province> kProvinces = [
  Province('ha-noi', 'Hà Nội', VnRegion.north),
  Province('hai-phong', 'Hải Phòng', VnRegion.north),
  Province('hue', 'Huế', VnRegion.central),
  Province('da-nang', 'Đà Nẵng', VnRegion.central),
  Province('can-tho', 'Cần Thơ', VnRegion.south),
  Province('tp-hcm', 'TP. Hồ Chí Minh', VnRegion.south),
  Province('tuyen-quang', 'Tuyên Quang', VnRegion.north),
  Province('lao-cai', 'Lào Cai', VnRegion.north),
  Province('thai-nguyen', 'Thái Nguyên', VnRegion.north),
  Province('phu-tho', 'Phú Thọ', VnRegion.north),
  Province('bac-ninh', 'Bắc Ninh', VnRegion.north),
  Province('hung-yen', 'Hưng Yên', VnRegion.north),
  Province('ninh-binh', 'Ninh Bình', VnRegion.north),
  Province('cao-bang', 'Cao Bằng', VnRegion.north),
  Province('lang-son', 'Lạng Sơn', VnRegion.north),
  Province('lai-chau', 'Lai Châu', VnRegion.north),
  Province('dien-bien', 'Điện Biên', VnRegion.north),
  Province('son-la', 'Sơn La', VnRegion.north),
  Province('quang-ninh', 'Quảng Ninh', VnRegion.north),
  Province('thanh-hoa', 'Thanh Hóa', VnRegion.central),
  Province('nghe-an', 'Nghệ An', VnRegion.central),
  Province('ha-tinh', 'Hà Tĩnh', VnRegion.central),
  Province('quang-tri', 'Quảng Trị', VnRegion.central),
  Province('quang-ngai', 'Quảng Ngãi', VnRegion.central),
  Province('gia-lai', 'Gia Lai', VnRegion.central),
  Province('khanh-hoa', 'Khánh Hòa', VnRegion.central),
  Province('lam-dong', 'Lâm Đồng', VnRegion.central),
  Province('dak-lak', 'Đắk Lắk', VnRegion.central),
  Province('dong-nai', 'Đồng Nai', VnRegion.south),
  Province('tay-ninh', 'Tây Ninh', VnRegion.south),
  Province('vinh-long', 'Vĩnh Long', VnRegion.south),
  Province('dong-thap', 'Đồng Tháp', VnRegion.south),
  Province('ca-mau', 'Cà Mau', VnRegion.south),
  Province('an-giang', 'An Giang', VnRegion.south),
];

Province? provinceByCode(String? code) {
  if (code == null) return null;
  for (final p in kProvinces) {
    if (p.code == code) return p;
  }
  return null;
}
