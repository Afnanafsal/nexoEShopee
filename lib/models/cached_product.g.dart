// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedProductAdapter extends TypeAdapter<CachedProduct> {
  @override
  final int typeId = 0;

  @override
  CachedProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProduct(
      id: fields[0] as String,
      title: fields[1] as String?,
      description: fields[2] as String?,
      images: (fields[3] as List?)?.cast<String>(),
      originalPrice: fields[4] as double?,
      discountPrice: fields[5] as double?,
      seller: fields[6] as String?,
      owner: fields[7] as String?,
      cachedAt: fields[8] as DateTime,
      productType: fields[9] as String?,
      highlights: fields[10] as String?,
      searchTags: (fields[11] as List?)?.cast<String>(),
      variant: fields[12] as String?,
      rating: fields[13] as double,
      dateAdded: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedProduct obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.images)
      ..writeByte(4)
      ..write(obj.originalPrice)
      ..writeByte(5)
      ..write(obj.discountPrice)
      ..writeByte(6)
      ..write(obj.seller)
      ..writeByte(7)
      ..write(obj.owner)
      ..writeByte(8)
      ..write(obj.cachedAt)
      ..writeByte(9)
      ..write(obj.productType)
      ..writeByte(10)
      ..write(obj.highlights)
      ..writeByte(11)
      ..write(obj.searchTags)
      ..writeByte(12)
      ..write(obj.variant)
      ..writeByte(13)
      ..write(obj.rating)
      ..writeByte(14)
      ..write(obj.dateAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
