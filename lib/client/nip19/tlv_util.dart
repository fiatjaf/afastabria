class TLVUtil {
  static TLVData? readTLVEntry(
    final List<int> data, {
    final int startIndex = 0,
  }) {
    final dataLength = data.length;
    if (dataLength < startIndex + 2) {
      return null;
    }

    final typ = data[startIndex];
    final length = data[startIndex + 1];

    if (dataLength >= startIndex + 2 + length) {
      final d = data.sublist(startIndex + 2, startIndex + 2 + length);

      return TLVData(typ, length, d);
    }

    return null;
  }

  static writeTLVEntry(
      final List<int> buf, final int typ, final List<int> data) {
    final length = data.length;
    buf.add(typ);
    buf.add(length);
    buf.addAll(data);
  }
}

class TLVData {
  TLVData(this.typ, this.length, this.data);
  int typ;

  int length;

  List<int> data;
}

class TLVType {
  static const int Default = 0;
  static const int Relay = 1;
  static const int Author = 2;
  static const int Kind = 3;
}
