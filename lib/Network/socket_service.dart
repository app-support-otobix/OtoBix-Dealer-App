import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService {
  //  Single instance
  static final SocketService _instance = SocketService._internal();

  //  The actual socket
  late IO.Socket socket;

  // Instance for direct access using SocketService.instance
  static SocketService get instance => _instance;

  //  Private constructor
  SocketService._internal();

  // Initialize socket in main
  void initSocket(String serverUrl) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true, // ✅ enable auto reconnect
      'reconnectionAttempts': 10, // ✅ retry up to 10 times
      'reconnectionDelay': 3000, // ✅ every 3 seconds
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint('🟢 Connected to Otobix\'s Websocket Server.');
      _onReconnect(); // ✅ call a custom function on reconnect
    });

    socket.onDisconnect((_) {
      debugPrint('🔴 Disconnected from Otobix\'s Websocket Server');
    });

    // Optionally listen for errors
    socket.onConnectError((e) => debugPrint('⚠️ Connect error: $e'));
    socket.onError((e) => debugPrint('❌ Socket error: $e'));
  }

  // Join different rooms
  void joinRoom(String roomId) {
    socket.emit(SocketEvents.joinRoom, roomId);
    debugPrint('Joined room: $roomId');
  }

  // Join this dealer's private room. The server only admits the owner of a
  // valid access token, and it is re-joined after every reconnect.
  bool _dealerRoomWanted = false;

  Future<void> joinDealerRoom() async {
    _dealerRoomWanted = true;
    final token =
        await SharedPrefsHelper.getString(SharedPrefsHelper.accessTokenKey) ??
        '';
    if (token.isEmpty) return;
    socket.emitWithAck(
      SocketEvents.dealerJoin,
      {'token': token},
      ack: (response) {
        if (response is Map && response['ok'] != true) {
          debugPrint('Dealer room join refused: ${response['code']}');
        }
      },
    );
  }

  // Leave a room
  void leaveRoom(String roomId) {
    socket.emit(SocketEvents.leaveRoom, roomId);
    debugPrint('📤 Left room: $roomId');
  }

  // For listening to events
  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  // Stop listening to a specific event
  void off(String event, [void Function(dynamic)? handler]) {
    if (handler != null) {
      socket.off(event, handler); // removes only that handler
      debugPrint('🚫 Removed handler for event: $event');
    } else {
      socket.off(event); // removes all handlers for that event
      debugPrint('🚫 Removed all handlers for event: $event');
    }
  }

  // For sending events
  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  // Dispose socket on app closing
  void dispose() {
    socket.dispose();
  }

  // Add this helper
  void _onReconnect() {
    // ✅ Rejoin all rooms when reconnecting
    socket.emit(SocketEvents.joinRoom, SocketEvents.upcomingBidsSectionRoom);
    socket.emit(SocketEvents.joinRoom, SocketEvents.liveBidsSectionRoom);
    socket.emit(SocketEvents.joinRoom, SocketEvents.otobuyCarsSectionRoom);
    socket.emit(
      SocketEvents.joinRoom,
      SocketEvents.auctionCompletedCarsSectionRoom,
    );
    if (_dealerRoomWanted) joinDealerRoom();

    // ✅ Let the app know socket is reconnected (e.g., via callback or stream)
    debugPrint('🔄 Socket reconnected, rooms rejoined');
  }
}
