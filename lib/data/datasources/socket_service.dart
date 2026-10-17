import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/api_endpoints.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  void connect() {
    if (_socket != null && _connected) return;

    _socket = IO.io(
      ApiEndpoints.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _connected = true;
      print('🟢 Socket connected');
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      print('🔴 Socket disconnected');
    });

    _socket!.onConnectError((err) {
      print('❌ Socket connect error: $err');
    });
  }

  void joinListing(int listingId) {
    _socket?.emit('join_listing', listingId);
  }

  void leaveListing(int listingId) {
    _socket?.emit('leave_listing', listingId);
  }

  void joinUser(int userId) {
    _socket?.emit('join_user', userId);
  }

  void onCommentAdded(Function(dynamic) callback) {
    _socket?.off('comment_added');
    _socket?.on('comment_added', callback);
  }

  void onReactionUpdate(Function(dynamic) callback) {
    _socket?.off('reaction_update');
    _socket?.on('reaction_update', callback);
  }

  void onRatingUpdate(Function(dynamic) callback) {
    _socket?.off('rating_update');
    _socket?.on('rating_update', callback);
  }

  void onNewOrder(Function(dynamic) callback) {
    _socket?.off('new_order');
    _socket?.on('new_order', callback);
  }

  void onOrderUpdate(Function(dynamic) callback) {
    _socket?.off('order_update');
    _socket?.on('order_update', callback);
  }

  void onNotification(Function(dynamic) callback) {
    _socket?.off('notification');
    _socket?.on('notification', callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }
}