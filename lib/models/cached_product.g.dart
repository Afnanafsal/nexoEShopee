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
      images: (fields[1] as List?)?.cast<String>(),
      title: fields[2] as String?,
      variant: fields[3] as String?,
      discountPrice: fields[4] as num?,
      originalPrice: fields[5] as num?,
      rating: fields[6] as num,
      highlights: fields[7] as String?,
      description: fields[8] as String?,
      seller: fields[9] as String?,
      owner: fields[10] as String?,
      productType: fields[11] as String?,
      searchTags: (fields[12] as List?)?.cast<String>(),
      dateAdded: fields[13] as DateTime?,
      cachedAt: fields[14] as DateTime,
      cacheDuration: fields[15] as Duration,
      reviews: (fields[16] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      totalReviews: fields[17] as int?,
      averageRating: fields[18] as double?,
      stockQuantity: fields[19] as int?,
      isAvailable: fields[20] as bool?,
      specifications: (fields[21] as Map?)?.cast<String, dynamic>(),
      relatedProductIds: (fields[22] as List?)?.cast<String>(),
      viewCount: fields[23] as int?,
      purchaseCount: fields[24] as int?,
      lastUpdated: fields[25] as DateTime?,
      metadata: (fields[26] as Map?)?.cast<String, dynamic>(),
      isFeatured: fields[27] as bool?,
      category: fields[28] as String?,
      subcategory: fields[29] as String?,
      tags: (fields[30] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CachedProduct obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.images)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.variant)
      ..writeByte(4)
      ..write(obj.discountPrice)
      ..writeByte(5)
      ..write(obj.originalPrice)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.highlights)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.seller)
      ..writeByte(10)
      ..write(obj.owner)
      ..writeByte(11)
      ..write(obj.productType)
      ..writeByte(12)
      ..write(obj.searchTags)
      ..writeByte(13)
      ..write(obj.dateAdded)
      ..writeByte(14)
      ..write(obj.cachedAt)
      ..writeByte(15)
      ..write(obj.cacheDuration)
      ..writeByte(16)
      ..write(obj.reviews)
      ..writeByte(17)
      ..write(obj.totalReviews)
      ..writeByte(18)
      ..write(obj.averageRating)
      ..writeByte(19)
      ..write(obj.stockQuantity)
      ..writeByte(20)
      ..write(obj.isAvailable)
      ..writeByte(21)
      ..write(obj.specifications)
      ..writeByte(22)
      ..write(obj.relatedProductIds)
      ..writeByte(23)
      ..write(obj.viewCount)
      ..writeByte(24)
      ..write(obj.purchaseCount)
      ..writeByte(25)
      ..write(obj.lastUpdated)
      ..writeByte(26)
      ..write(obj.metadata)
      ..writeByte(27)
      ..write(obj.isFeatured)
      ..writeByte(28)
      ..write(obj.category)
      ..writeByte(29)
      ..write(obj.subcategory)
      ..writeByte(30)
      ..write(obj.tags);
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
