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
      userId: fields[0] as String,
      displayName: fields[1] as String?,
      email: fields[2] as String?,
      profilePicture: fields[3] as String?,
      favoriteProducts: (fields[4] as List).cast<String>(),
      cartItems: (fields[5] as List).cast<String>(),
      cachedAt: fields[6] as DateTime,
      cacheDuration: fields[7] as Duration,
      preferences: (fields[8] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CachedUser obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.profilePicture)
      ..writeByte(4)
      ..write(obj.favoriteProducts)
      ..writeByte(5)
      ..write(obj.cartItems)
      ..writeByte(6)
      ..write(obj.cachedAt)
      ..writeByte(7)
      ..write(obj.cacheDuration)
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
