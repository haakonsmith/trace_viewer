import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:xqflite/xqflite.dart';

final class XDatabase extends XqfliteDatabase {
  XDatabase._();

  static final XDatabase _instance = XDatabase._();
  static XDatabase get instance => _instance;
}

extension TodoDatabase on XqfliteDatabase {
  Future<void> init() async {
    // final canMessages = Table.builder('clients') //
    //     .primaryKey(XClient.idName)
    //     .text('name')
    //     .text('abn')
    //     .text('phone')
    //     .text('email')
    //     .text('address')
    //     .build();

    final traces = Table.builder('traces') //
        .primaryKey('id')
        .text('name')
        .build();

    final schema = Schema([traces]);

    await open(
      schema,
      nukeDb: true,
      migrations: [],
      dbPath: ':memory:',
      relativeToSqflitePath: false,
    );
  }

  // DbTableWithConverter<XClient> get traces => tables['clients']!.withConverter(XClient.converter)
  DbTableWithConverter<CanMessage> data(int index) {
    return tables['data_$index']!.withConverter(CanMessage.converter);
  }
}
