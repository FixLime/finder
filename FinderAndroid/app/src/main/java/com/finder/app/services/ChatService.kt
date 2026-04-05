package com.finder.app.services

import android.app.Application
import android.content.Context
import com.finder.app.models.AvatarColor
import com.finder.app.models.Chat
import com.finder.app.models.FinderUser
import com.finder.app.models.Message
import com.finder.app.models.MessageType
import com.finder.app.models.PrivacySettings
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

object ChatService {

    private const val CHATS_FILENAME = "finder_chats.json"
    private const val DEBOUNCE_MS = 500L

    private lateinit var appContext: Context
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var saveJob: Job? = null

    private val _chats = MutableStateFlow<List<Chat>>(emptyList())
    val chats: StateFlow<List<Chat>> = _chats.asStateFlow()

    private val currentUserId: UUID
        get() = FinderUser.current.id

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    fun init(application: Application) {
        appContext = application.applicationContext
        loadChats()
    }

    // region Persistence

    private fun loadChats() {
        try {
            val file = File(appContext.filesDir, CHATS_FILENAME)
            if (file.exists()) {
                val json = file.readText()
                val chats = parseChatListFromJson(json)
                _chats.value = chats
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun scheduleSave() {
        saveJob?.cancel()
        saveJob = scope.launch {
            delay(DEBOUNCE_MS)
            saveChats()
        }
    }

    private fun saveChats() {
        try {
            val json = chatListToJson(_chats.value)
            val file = File(appContext.filesDir, CHATS_FILENAME)
            file.writeText(json)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun chatListToJson(chats: List<Chat>): String {
        val arr = JSONArray()
        for (chat in chats) {
            val obj = JSONObject()
            obj.put("id", chat.id.toString())
            obj.put("isGroup", chat.isGroup)
            obj.put("isChannel", chat.isChannel)
            obj.put("groupName", chat.groupName ?: JSONObject.NULL)
            obj.put("isPinned", chat.isPinned)
            obj.put("isMuted", chat.isMuted)
            obj.put("isArchived", chat.isArchived)
            obj.put("isNotes", chat.isNotes)
            obj.put("isSupport", chat.isSupport)
            obj.put("unreadCount", chat.unreadCount)

            val participantsArr = JSONArray()
            for (user in chat.participants) {
                val uObj = JSONObject()
                uObj.put("id", user.id.toString())
                uObj.put("username", user.username)
                uObj.put("displayName", user.displayName)
                uObj.put("avatarIcon", user.avatarIcon)
                uObj.put("avatarColor", user.avatarColor.name)
                uObj.put("statusText", user.statusText)
                uObj.put("isOnline", user.isOnline)
                uObj.put("isVerified", user.isVerified)
                uObj.put("isUntrusted", user.isUntrusted)
                uObj.put("isBanned", user.isBanned)
                uObj.put("isDeleted", user.isDeleted)
                uObj.put("finderID", user.finderID)
                uObj.put("joinDate", dateFormat.format(user.joinDate))
                participantsArr.put(uObj)
            }
            obj.put("participants", participantsArr)

            val messagesArr = JSONArray()
            for (msg in chat.messages) {
                val mObj = JSONObject()
                mObj.put("id", msg.id.toString())
                mObj.put("senderId", msg.senderId.toString())
                mObj.put("chatId", msg.chatId.toString())
                mObj.put("text", msg.text)
                mObj.put("timestamp", dateFormat.format(msg.timestamp))
                mObj.put("isRead", msg.isRead)
                mObj.put("isDelivered", msg.isDelivered)
                mObj.put("isEdited", msg.isEdited)
                mObj.put("messageType", msg.messageType.rawValue)
                mObj.put("isPhantom", msg.isPhantom)
                mObj.put("isForwardable", msg.isForwardable)
                if (msg.replyToId != null) mObj.put("replyToId", msg.replyToId.toString())
                if (msg.selfDestructTime != null) mObj.put("selfDestructTime", msg.selfDestructTime)
                messagesArr.put(mObj)
            }
            obj.put("messages", messagesArr)

            arr.put(obj)
        }
        return arr.toString(2)
    }

    private fun parseChatListFromJson(json: String): List<Chat> {
        val result = mutableListOf<Chat>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val participants = mutableListOf<FinderUser>()
                val pArr = obj.getJSONArray("participants")
                for (j in 0 until pArr.length()) {
                    val uObj = pArr.getJSONObject(j)
                    participants.add(
                        FinderUser(
                            id = UUID.fromString(uObj.getString("id")),
                            username = uObj.getString("username"),
                            displayName = uObj.getString("displayName"),
                            avatarIcon = uObj.optString("avatarIcon", "person"),
                            avatarColor = AvatarColor.fromString(uObj.optString("avatarColor", "BLUE")),
                            statusText = uObj.optString("statusText", ""),
                            isOnline = uObj.optBoolean("isOnline", false),
                            lastSeen = null,
                            isVerified = uObj.optBoolean("isVerified", false),
                            isUntrusted = uObj.optBoolean("isUntrusted", false),
                            isBanned = uObj.optBoolean("isBanned", false),
                            isDeleted = uObj.optBoolean("isDeleted", false),
                            finderID = uObj.optString("finderID", ""),
                            joinDate = try {
                                dateFormat.parse(uObj.getString("joinDate")) ?: Date()
                            } catch (e: Exception) { Date() },
                            privacySettings = PrivacySettings.default
                        )
                    )
                }

                val messages = mutableListOf<Message>()
                val mArr = obj.getJSONArray("messages")
                val chatId = UUID.fromString(obj.getString("id"))
                for (k in 0 until mArr.length()) {
                    val mObj = mArr.getJSONObject(k)
                    messages.add(
                        Message(
                            id = UUID.fromString(mObj.getString("id")),
                            senderId = UUID.fromString(mObj.getString("senderId")),
                            chatId = try {
                                UUID.fromString(mObj.getString("chatId"))
                            } catch (e: Exception) { chatId },
                            text = mObj.getString("text"),
                            timestamp = try {
                                dateFormat.parse(mObj.getString("timestamp")) ?: Date()
                            } catch (e: Exception) { Date() },
                            isRead = mObj.optBoolean("isRead", false),
                            isDelivered = mObj.optBoolean("isDelivered", false),
                            isEdited = mObj.optBoolean("isEdited", false),
                            replyToId = if (mObj.has("replyToId") && !mObj.isNull("replyToId"))
                                UUID.fromString(mObj.getString("replyToId")) else null,
                            messageType = MessageType.fromString(mObj.optString("messageType", "text")),
                            isPhantom = mObj.optBoolean("isPhantom", false),
                            selfDestructTime = if (mObj.has("selfDestructTime") && !mObj.isNull("selfDestructTime"))
                                mObj.getDouble("selfDestructTime") else null,
                            isForwardable = mObj.optBoolean("isForwardable", true),
                            encryptedPayload = null
                        )
                    )
                }

                result.add(
                    Chat(
                        id = chatId,
                        participants = participants,
                        messages = messages,
                        isGroup = obj.optBoolean("isGroup", false),
                        isChannel = obj.optBoolean("isChannel", false),
                        groupName = if (obj.has("groupName") && !obj.isNull("groupName"))
                            obj.getString("groupName") else null,
                        isPinned = obj.optBoolean("isPinned", false),
                        isMuted = obj.optBoolean("isMuted", false),
                        isArchived = obj.optBoolean("isArchived", false),
                        isNotes = obj.optBoolean("isNotes", false),
                        isSupport = obj.optBoolean("isSupport", false),
                        unreadCount = obj.optInt("unreadCount", 0)
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return result
    }

    // endregion

    // region Demo Data

    fun loadDemoData() {
        val supportUser = FinderUser(
            id = UUID.randomUUID(),
            username = "finder_support",
            displayName = "Finder Support",
            avatarIcon = "headset_mic",
            avatarColor = AvatarColor.BLUE,
            statusText = "\u041E\u0444\u0438\u0446\u0438\u0430\u043B\u044C\u043D\u0430\u044F \u043F\u043E\u0434\u0434\u0435\u0440\u0436\u043A\u0430",
            isOnline = true,
            lastSeen = null,
            isVerified = true,
            isUntrusted = false,
            isBanned = false,
            isDeleted = false,
            finderID = "FID-SUPPORT0",
            joinDate = Date(),
            privacySettings = PrivacySettings.default
        )

        val supportChatId = UUID.randomUUID()
        val supportMessage = Message(
            id = UUID.randomUUID(),
            senderId = supportUser.id,
            chatId = supportChatId,
            text = "\u0414\u043E\u0431\u0440\u043E \u043F\u043E\u0436\u0430\u043B\u043E\u0432\u0430\u0442\u044C \u0432 Finder! \u041C\u044B \u0440\u0430\u0434\u044B \u0432\u0430\u0441 \u0432\u0438\u0434\u0435\u0442\u044C. \u0415\u0441\u043B\u0438 \u0443 \u0432\u0430\u0441 \u0435\u0441\u0442\u044C \u0432\u043E\u043F\u0440\u043E\u0441\u044B, \u043E\u0431\u0440\u0430\u0449\u0430\u0439\u0442\u0435\u0441\u044C!",
            timestamp = Date(),
            isRead = false,
            isDelivered = true,
            isEdited = false,
            messageType = MessageType.TEXT,
            isPhantom = false,
            isForwardable = true
        )

        val supportChat = Chat(
            id = supportChatId,
            participants = listOf(FinderUser.current, supportUser),
            messages = listOf(supportMessage),
            isGroup = false,
            isSupport = true,
            isPinned = true,
            unreadCount = 1
        )

        _chats.value = listOf(supportChat)
        scheduleSave()
    }

    // endregion

    // region Chat Operations

    fun sendMessage(chatId: UUID, text: String) {
        val chatIndex = _chats.value.indexOfFirst { it.id == chatId }
        if (chatIndex == -1) return

        val chat = _chats.value[chatIndex]
        val newMessage = Message(
            id = UUID.randomUUID(),
            senderId = currentUserId,
            chatId = chatId,
            text = text,
            timestamp = Date(),
            isRead = false,
            isDelivered = true,
            isEdited = false,
            messageType = MessageType.TEXT,
            isPhantom = false,
            isForwardable = true
        )

        val updatedMessages = chat.messages + newMessage
        val updatedChat = chat.copy(messages = updatedMessages)
        val updatedChats = _chats.value.toMutableList()
        updatedChats[chatIndex] = updatedChat
        _chats.value = updatedChats
        scheduleSave()

        // Auto-reply in offline mode (support chat)
        if (chat.isSupport) {
            scheduleAutoReply(chatId, chat)
        }
    }

    private fun scheduleAutoReply(chatId: UUID, chat: Chat) {
        scope.launch {
            delay(1500L)
            val replies = listOf(
                "\u0421\u043F\u0430\u0441\u0438\u0431\u043E \u0437\u0430 \u0441\u043E\u043E\u0431\u0449\u0435\u043D\u0438\u0435! \u041C\u044B \u043E\u0431\u044F\u0437\u0430\u0442\u0435\u043B\u044C\u043D\u043E \u0440\u0430\u0441\u0441\u043C\u043E\u0442\u0440\u0438\u043C \u0432\u0430\u0448 \u0432\u043E\u043F\u0440\u043E\u0441.",
                "\u041C\u044B \u0440\u0430\u0431\u043E\u0442\u0430\u0435\u043C \u043D\u0430\u0434 \u044D\u0442\u0438\u043C. \u041E\u0436\u0438\u0434\u0430\u0439\u0442\u0435 \u043E\u0431\u043D\u043E\u0432\u043B\u0435\u043D\u0438\u044F!",
                "\u0412\u0430\u0448 \u0437\u0430\u043F\u0440\u043E\u0441 \u043F\u0440\u0438\u043D\u044F\u0442. \u041D\u043E\u043C\u0435\u0440 \u043E\u0431\u0440\u0430\u0449\u0435\u043D\u0438\u044F: #${(1000..9999).random()}",
                "\u041F\u043E\u0436\u0430\u043B\u0443\u0439\u0441\u0442\u0430, \u043F\u043E\u0434\u043E\u0436\u0434\u0438\u0442\u0435. \u041C\u044B \u043F\u0435\u0440\u0435\u043D\u0430\u043F\u0440\u0430\u0432\u0438\u043C \u0432\u0430\u0441 \u043A \u0441\u043F\u0435\u0446\u0438\u0430\u043B\u0438\u0441\u0442\u0443."
            )
            val replyText = replies.random()
            val otherUser = chat.participants.firstOrNull { it.id != currentUserId }

            val replyMessage = Message(
                id = UUID.randomUUID(),
                senderId = otherUser?.id ?: UUID.randomUUID(),
                chatId = chatId,
                text = replyText,
                timestamp = Date(),
                isRead = false,
                isDelivered = true,
                isEdited = false,
                messageType = MessageType.TEXT,
                isPhantom = false,
                isForwardable = true
            )

            val currentChatIndex = _chats.value.indexOfFirst { it.id == chatId }
            if (currentChatIndex != -1) {
                val currentChat = _chats.value[currentChatIndex]
                val updatedMessages = currentChat.messages + replyMessage
                val updatedChat = currentChat.copy(
                    messages = updatedMessages,
                    unreadCount = currentChat.unreadCount + 1
                )
                val updatedChats = _chats.value.toMutableList()
                updatedChats[currentChatIndex] = updatedChat
                _chats.value = updatedChats
                scheduleSave()
            }
        }
    }

    fun startChat(user: FinderUser): Chat {
        // Check if chat with this user already exists
        val existingChat = _chats.value.firstOrNull { chat ->
            !chat.isGroup && !chat.isChannel && !chat.isNotes && !chat.isSupport &&
                chat.participants.any { it.username == user.username }
        }
        if (existingChat != null) return existingChat

        val newChat = Chat(
            id = UUID.randomUUID(),
            participants = listOf(FinderUser.current, user),
            messages = emptyList(),
            isGroup = false
        )

        _chats.value = _chats.value + newChat
        scheduleSave()
        return newChat
    }

    fun createGroup(name: String, members: List<FinderUser>): Chat {
        val allParticipants = listOf(FinderUser.current) + members
        val groupChat = Chat(
            id = UUID.randomUUID(),
            participants = allParticipants,
            messages = emptyList(),
            isGroup = true,
            groupName = name
        )

        _chats.value = _chats.value + groupChat
        scheduleSave()
        return groupChat
    }

    fun deleteChat(chatId: UUID) {
        _chats.value = _chats.value.filter { it.id != chatId }
        scheduleSave()
    }

    fun searchChats(query: String): List<Chat> {
        if (query.isBlank()) return _chats.value
        val lowerQuery = query.lowercase()
        return _chats.value.filter { chat ->
            val nameMatch = chat.groupName?.lowercase()?.contains(lowerQuery) == true
            val userMatch = chat.participants.any {
                it.username.lowercase().contains(lowerQuery) ||
                    it.displayName.lowercase().contains(lowerQuery)
            }
            val messageMatch = chat.messages.any {
                it.text.lowercase().contains(lowerQuery)
            }
            nameMatch || userMatch || messageMatch
        }
    }

    fun markChatAsRead(chatId: UUID) {
        val chatIndex = _chats.value.indexOfFirst { it.id == chatId }
        if (chatIndex == -1) return

        val chat = _chats.value[chatIndex]
        val updatedMessages = chat.messages.map { it.copy(isRead = true) }
        val updatedChat = chat.copy(messages = updatedMessages, unreadCount = 0)
        val updatedChats = _chats.value.toMutableList()
        updatedChats[chatIndex] = updatedChat
        _chats.value = updatedChats
        scheduleSave()
    }

    fun togglePinChat(chatId: UUID) {
        val chatIndex = _chats.value.indexOfFirst { it.id == chatId }
        if (chatIndex == -1) return

        val chat = _chats.value[chatIndex]
        val updatedChat = chat.copy(isPinned = !chat.isPinned)
        val updatedChats = _chats.value.toMutableList()
        updatedChats[chatIndex] = updatedChat
        _chats.value = updatedChats
        scheduleSave()
    }

    fun toggleMuteChat(chatId: UUID) {
        val chatIndex = _chats.value.indexOfFirst { it.id == chatId }
        if (chatIndex == -1) return

        val chat = _chats.value[chatIndex]
        val updatedChat = chat.copy(isMuted = !chat.isMuted)
        val updatedChats = _chats.value.toMutableList()
        updatedChats[chatIndex] = updatedChat
        _chats.value = updatedChats
        scheduleSave()
    }

    fun clearAllChats() {
        _chats.value = emptyList()
        scheduleSave()
    }

    // endregion
}
