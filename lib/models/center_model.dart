class CenterModel {
  final int id;
  final String name;
  final String address;
  final double price;

  CenterModel({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
  });

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      id: int.parse(json['id'].toString()),
      name: json['center_name'],
      address: json['address'],
      price: double.parse(json['price'].toString()),
    );
  }
}
