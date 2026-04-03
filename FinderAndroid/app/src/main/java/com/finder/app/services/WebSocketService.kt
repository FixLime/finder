package com.finder.app.services

import com.finder.app.models.ServerMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import okhttp3.*
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object WebSocketService {
    private const val WS_URL = "ws://155.212.165.134:3001"

    private var webSocket: WebSocket? = null
    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .pingInterval(30, TimeUnit.SECONDS)
        .build()
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val _isConnected = MutableStateFlow(false)
    val isConnected = _isConnected.asStateFlow()

    // Events
    private val _messageReceived = MutableSharedFlow<ServerMessage>(extraBufferCapacity = 64)
    val messageReceived = _messageReceived.asSharedFlow()

    private val _typingReceived = MutableSharedFlow<Pair<String, String>>(extraBufferCapacity = 64) // chatId, userId
    val typingReceived = _typingReceived.asSharedFlow()

    private val _userStatusChanged = MutableSharedFlow<Pair<String, Boolean>>(extraBufferCapacity = 64) // userId, isOnline
    val userStatusChanged = _userStatusChanged.asSharedFlow()

    private val _incomingCall = MutableSharedFlow<IncomingCallData>(extraBufferCapacity = 16)
    val incomingCall = _incomingCall.asSharedFlow()

    private val _callEnded = MutableSharedFlow<String>(extraBufferCapacity = 16)
    val callEnded = _callEnded.asSharedFlow()

    // WebRTC signaling
    private val _webrtcOffer = MutableSharedFlow<WebRTCSignal>(extraBufferCapacity = 16)
    val webrtcOffer = _webrtcOffer.asSharedFlow()

    private val _webrtcAnswer = MutableSharedFlow<WebRTCSignal>(extraBufferCapacity = 16)
    val webrtcAnswer = _webrtcAnswer.asSharedFlow()

    private val _iceCandidate = MutableSharedFlow<WebRTCSignal>(extraBufferCapacity = 16)
    val iceCandidate = _iceCandidate.asSharedFlow()

    private var token: String? = null
    private var reconnectAttempts = 0

    fun connect(authToken: String) {
        token = authToken
        reconnectAttempts = 0
        doConnect()
    }

    private fun doConnect() {
        val request = Request.Builder().url(WS_URL).build()
        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                _isConnected.value = true
                reconnectAttempts = 0
                // Authenticate
                val authMsg = JSONObject().apply {
                    put("type", "auth")
                    put("token", token)
                }
                webSocket.send(authMsg.toString())
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                handleMessage(text)
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                webSocket.close(1000, null)
                _isConnected.value = false
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                _isConnected.value = false
                attemptReconnect()
            }
        })
    }

    fun disconnect() {
        webSocket?.close(1000, "User disconnect")
        webSocket = null
        _isConnected.value = false
    }

    // Send methods
    fun sendMessage(chatId: String, text: String, messageType: String = "text") {
        val msg = JSONObject().apply {
            put("type", "message")
            put("chat_id", chatId)
            put("text", text)
            put("message_type", messageType)
        }
        webSocket?.send(msg.toString())
    }

    fun sendTyping(chatId: String) {
        val msg = JSONObject().apply {
            put("type", "typing")
            put("chat_id", chatId)
        }
        webSocket?.send(msg.toString())
    }

    fun sendRead(chatId: String, messageId: String) {
        val msg = JSONObject().apply {
            put("type", "read")
            put("chat_id", chatId)
            put("message_id", messageId)
        }
        webSocket?.send(msg.toString())
    }

    fun sendWebRTCOffer(callId: String, sdp: String, to: String) {
        val msg = JSONObject().apply {
            put("type", "webrtc-offer")
            put("call_id", callId)
            put("sdp", sdp)
            put("to", to)
        }
        webSocket?.send(msg.toString())
    }

    fun sendWebRTCAnswer(callId: String, sdp: String, to: String) {
        val msg = JSONObject().apply {
            put("type", "webrtc-answer")
            put("call_id", callId)
            put("sdp", sdp)
            put("to", to)
        }
        webSocket?.send(msg.toString())
    }

    fun sendICECandidate(callId: String, candidate: String, to: String) {
        val msg = JSONObject().apply {
            put("type", "ice-candidate")
            put("call_id", callId)
            put("candidate", candidate)
            put("to", to)
        }
        webSocket?.send(msg.toString())
    }

    private fun handleMessage(text: String) {
        try {
            val jsonObj = JSONObject(text)
            val type = jsonObj.optString("type")
            scope.launch {
                when (type) {
                    "message" -> {
                        val msgJson = jsonObj.optJSONObject("message")?.toString() ?: jsonObj.toString()
                        val serverMsg = json.decodeFromString<ServerMessage>(msgJson)
                        _messageReceived.emit(serverMsg)
                    }
                    "typing" -> {
                        val chatId = jsonObj.optString("chat_id")
                        val userId = jsonObj.optString("user_id")
                        if (chatId.isNotEmpty() && userId.isNotEmpty()) {
                            _typingReceived.emit(chatId to userId)
                        }
                    }
                    "read" -> { /* handled via API */ }
                    "user-online" -> {
                        val userId = jsonObj.optString("user_id")
                        if (userId.isNotEmpty()) _userStatusChanged.emit(userId to true)
                    }
                    "user-offline" -> {
                        val userId = jsonObj.optString("user_id")
                        if (userId.isNotEmpty()) _userStatusChanged.emit(userId to false)
                    }
                    "webrtc-offer" -> {
                        _webrtcOffer.emit(WebRTCSignal(
                            callId = jsonObj.optString("call_id"),
                            sdp = jsonObj.optString("sdp"),
                            from = jsonObj.optString("from")
                        ))
                    }
                    "webrtc-answer" -> {
                        _webrtcAnswer.emit(WebRTCSignal(
                            callId = jsonObj.optString("call_id"),
                            sdp = jsonObj.optString("sdp"),
                            from = jsonObj.optString("from")
                        ))
                    }
                    "ice-candidate" -> {
                        _iceCandidate.emit(WebRTCSignal(
                            callId = jsonObj.optString("call_id"),
                            sdp = jsonObj.optString("candidate"),
                            from = jsonObj.optString("from")
                        ))
                    }
                    "call-incoming" -> {
                        _incomingCall.emit(IncomingCallData(
                            callId = jsonObj.optString("call_id"),
                            chatId = jsonObj.optString("chat_id"),
                            isVideo = jsonObj.optBoolean("is_video"),
                            from = jsonObj.optString("from")
                        ))
                    }
                    "call-ended" -> {
                        val callId = jsonObj.optString("call_id")
                        if (callId.isNotEmpty()) _callEnded.emit(callId)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun attemptReconnect() {
        if (reconnectAttempts >= 10) return
        reconnectAttempts++
        val delay = minOf(reconnectAttempts * 2000L, 30000L)
        scope.launch {
            kotlinx.coroutines.delay(delay)
            if (!_isConnected.value && token != null) {
                doConnect()
            }
        }
    }
}

data class IncomingCallData(
    val callId: String,
    val chatId: String,
    val isVideo: Boolean,
    val from: String
)

data class WebRTCSignal(
    val callId: String,
    val sdp: String,
    val from: String
)
