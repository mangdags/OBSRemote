import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ObsClient {
  WebSocketChannel? _ch;
  int _msgId = 0;

  final _pending = <String, Completer<Map<String, dynamic>>>{};

  bool get isConnected => _ch != null;

  Future<void> connect({
    required String host,
    int port = 4455,
  }) async {
    final uri = Uri.parse('ws://$host:$port');
    _ch = WebSocketChannel.connect(uri);

    _ch!.stream.listen((event) {
      final map = jsonDecode(event as String) as Map<String, dynamic>;
      final op = map['op'];

      // Response frames are op=7
      if (op == 7) {
        final d = (map['d'] as Map).cast<String, dynamic>();
        final requestId = d['requestId'] as String?;
        if (requestId != null && _pending.containsKey(requestId)) {
          _pending.remove(requestId)!.complete(d);
        }
      }
    }, onDone: () {
      for (final c in _pending.values) {
        c.completeError(StateError('Disconnected'));
      }
      _pending.clear();
      _ch = null;
    }, onError: (e) {
      for (final c in _pending.values) {
        c.completeError(e);
      }
      _pending.clear();
      _ch = null;
    });

    // Identify (no auth)
    _send({
      "op": 1,
      "d": {"rpcVersion": 1, "eventSubscriptions": 0}
    });

    await Future.delayed(const Duration(milliseconds: 150));
  }

  void disconnect() {
    _ch?.sink.close();
    _ch = null;
  }

  void _send(Map<String, dynamic> payload) {
    _ch?.sink.add(jsonEncode(payload));
  }

  Future<Map<String, dynamic>> request(
    String requestType, {
    Map<String, dynamic>? requestData,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_ch == null) throw StateError('Not connected');

    final requestId = (++_msgId).toString();
    final c = Completer<Map<String, dynamic>>();
    _pending[requestId] = c;

    _send({
      "op": 6,
      "d": {
        "requestType": requestType,
        "requestId": requestId,
        "requestData": requestData ?? {},
      }
    });

    final d = await c.future.timeout(timeout);

    // OBS returns requestStatus in ALL request responses
    final status = d["requestStatus"];
    if (status is Map) {
      final ok = status["result"] == true;
      if (!ok) {
        final code = status["code"];
        final comment = status["comment"];
        throw StateError("OBS $requestType failed: $code - $comment");
      }
    }

    return d;
  }

  // ---- Convenience wrappers ----

  Future<int?> getSceneItemId({
    required String sceneName,
    required String sourceName,
  }) async {
    final d = await request("GetSceneItemId", requestData: {
      "sceneName": sceneName,
      "sourceName": sourceName,
    });

    final rd = d["responseData"];
    if (rd is! Map) return null;

    final id = rd["sceneItemId"];
    if (id is int) return id;

    return null;
  }

  Future<void> setSceneItemEnabled({
    required String sceneName,
    required int sceneItemId,
    required bool enabled,
  }) async {
    await request("SetSceneItemEnabled", requestData: {
      "sceneName": sceneName,
      "sceneItemId": sceneItemId,
      "sceneItemEnabled": enabled,
    });
  }

  /// Updates a Text source:
  /// - For Text (GDI+) / Text (FreeType2), OBS uses "text" in inputSettings.
  Future<void> setTextSource({
    required String inputName,
    required String text,
  }) async {
    await request("SetInputSettings", requestData: {
      "inputName": inputName,
      "inputSettings": {"text": text},
      "overlay": true,
    });
  }

  /// Show entry banner inside fight scene (no scene switching)
  Future<void> showEntryBanner({
    required String fightSceneName,
    required String bannerSourceName, // SCENE ITEM name inside the fight scene
    required Duration duration,
  }) async {
    final id = await getSceneItemId(
      sceneName: fightSceneName,
      sourceName: bannerSourceName,
    );

    if (id == null) {
      throw StateError(
        "Banner scene item '$bannerSourceName' not found in scene '$fightSceneName'.",
      );
    }

    await setSceneItemEnabled(
        sceneName: fightSceneName, sceneItemId: id, enabled: true);
    await Future.delayed(duration);
    await setSceneItemEnabled(
        sceneName: fightSceneName, sceneItemId: id, enabled: false);
  }

  // Optional helpers (useful for Studio Mode decisions later)
  Future<bool> getStudioModeEnabled() async {
    final d = await request("GetStudioModeEnabled");
    final rd = d["responseData"];
    if (rd is Map && rd["studioModeEnabled"] is bool) {
      return rd["studioModeEnabled"] as bool;
    }
    return false;
  }

  Future<String?> getCurrentPreviewScene() async {
    final d = await request("GetCurrentPreviewScene");
    final rd = d["responseData"];
    if (rd is Map && rd["currentPreviewSceneName"] is String) {
      return rd["currentPreviewSceneName"] as String;
    }
    return null;
  }

  Future<void> setCurrentProgramScene(String sceneName) async {
    await request(
      "SetCurrentProgramScene",
      requestData: {"sceneName": sceneName},
    );
  }

  Future<void> setSceneItemVisibleByName({
    required String sceneName,
    required String sourceName,
    required bool visible,
  }) async {
    final id =
        await getSceneItemId(sceneName: sceneName, sourceName: sourceName);
    if (id == null) return;
    await setSceneItemEnabled(
        sceneName: sceneName, sceneItemId: id, enabled: visible);
  }
}
