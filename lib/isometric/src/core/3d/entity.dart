import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:uuid/uuid.dart';

abstract class Entity {
  late Uuid _id;
  Entity? parent;
  List<Entity>? children;
  
  void tickClient(double dt);
  void tickServer(double dt);
  
  void receivePacket(Packet packet);
}

abstract class Packet {
  const Packet(ByteData data);
}

class SummonEntityPacket extends Packet {
  SummonEntityPacket(ByteData data) : super(data) {
    entityType = data.getInt16(8, Endian.little);
    
    final double pos1 = data.getFloat32(10, Endian.little);
    final double pos2 = data.getFloat32(14, Endian.little); //! not sure if xzy or xyz or completely different or everything is offset by 1
    final double pos3 = data.getFloat32(18, Endian.little);
    
    position = Vector3(pos1, pos3, pos2);
    
    final double rot1 = data.getFloat32(22, Endian.little);
    final double rot2 = data.getFloat32(26, Endian.little);
    final double rot3 = data.getFloat32(30, Endian.little);

    rotation = Vector3(rot1, rot3, rot2);
    
    final int customDataLength = data.getInt16(34, Endian.little);
    customData = data.buffer.asByteData(36, customDataLength);
  }
  
  
  late int entityType;
  late Vector3 position;
  late Vector3 rotation;
  late ByteData customData;
}

const int MsgTypeSummonEntity     = 0x00;
const int MsgTypeNewEntity        = 0x01;
const int MsgTypeEntityCustomData = 0x02;
const int MsgTypeRemoveEntity     = 0x03;
const int MsgTypeRequestChunkData = 0x04;
const int MsgTypeChunkData        = 0x05;
const int MsgTypeChatMessage      = 0x06;

const int MsgTypeEntityMove = 0x81;
const int MsgTypePing       = 0x82;
const int MsgTypePong       = 0x83;