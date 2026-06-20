import 'package:supabase_flutter/supabase_flutter.dart';
void test(RealtimeChannel c) {
  c.sendBroadcastMessage(event: 'chat', payload: {});
}
