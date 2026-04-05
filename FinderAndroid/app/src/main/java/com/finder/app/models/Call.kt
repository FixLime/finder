package com.finder.app.models

import java.io.Serializable
import java.util.Date
import java.util.UUID

data class CallRecord(
    val id: UUID = UUID.randomUUID(),
    val user: FinderUser,
    val timestamp: Date,
    val isVideo: Boolean,
    val isOutgoing: Boolean,
    val isMissed: Boolean,
    val duration: Int? = null // seconds
) : Serializable

data class ActiveCall(
    val callId: String,
    val chatId: String,
    val user: FinderUser,
    val isVideo: Boolean,
    val isOutgoing: Boolean
) : Serializable

enum class CallState {
    IDLE,
    CALLING,
    RINGING,
    CONNECTED,
    ENDED
}
