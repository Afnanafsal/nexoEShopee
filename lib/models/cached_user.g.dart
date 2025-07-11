// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedUserAdapter extends TypeAdapter<CachedUser> {
  @override
  final int typeId = 1;

  @override
  CachedUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedUser(
      id: fields[0] as String,
      displayName: fields[1] as String?,
      email: fields[2] as String?,
      phone: fields[3] as String?,
      profilePicture: fields[4] as String?,
      favoriteProducts: (fields[5] as List).cast<String>(),
      cartItems: (fields[6] as List).cast<String>(),
      cachedAt: fields[7] as DateTime,
      preferences: (fields[8] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CachedUser obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.profilePicture)
      ..writeByte(5)
      ..write(obj.favoriteProducts)
      ..writeByte(6)
      ..write(obj.cartItems)
      ..writeByte(7)
      ..write(obj.cachedAt)
      ..writeByte(8)
      ..write(obj.preferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
