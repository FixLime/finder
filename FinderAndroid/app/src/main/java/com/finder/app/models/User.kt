package com.finder.app.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ServerUser(
    val id: String,
    val username: String,
    @SerialName("display_name") val displayName: String,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("status_text") val statusText: String? = null,
    @SerialName("is_online") val isOnline: Boolean? = null,
    @SerialName("is_verified") val isVerified: Boolean? = null,
    @SerialName("is_banned") val isBanned: Boolean? = null,
    @SerialName("is_deleted") val isDeleted: Boolean? = null,
    @SerialName("finder_id") val finderId: String? = null,
    @SerialName("created_at") val createdAt: String? = null
)

data class FinderUser(
    val id: String,
    val username: String,
    val displayName: String,
    val statusText: String = "",
    val isOnline: Boolean = false,
    val isVerified: Boolean = false,
    val isBanned: Boolean = false,
    val isDeleted: Boolean = false,
    val finderId: String = "",
    val avatarColor: Long = 0xFF2196F3 // Blue
) {
    val isCensored: Boolean get() = isBanned || isDeleted
}

fun ServerUser.toFinderUser() = FinderUser(
    id = id,
    username = username,
    displayName = displayName,
    statusText = statusText ?: "",
    isOnline = isOnline ?: false,
    isVerified = isVerified ?: false,
    isBanned = isBanned ?: false,
    isDeleted = isDeleted ?: false,
    finderId = finderId ?: "FID-${id.take(8).uppercase()}"
)
