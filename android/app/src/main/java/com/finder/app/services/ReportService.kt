package com.finder.app.services

import android.content.Context
import com.finder.app.models.UserReport
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

object ReportService {
    private const val REPORTS_FILENAME = "finder_reports.json"

    private lateinit var appContext: Context

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    private val _reports = MutableStateFlow<List<UserReport>>(emptyList())
    val reports: StateFlow<List<UserReport>> = _reports.asStateFlow()

    val reportCount: Int get() = _reports.value.size

    fun init(context: Context) {
        appContext = context.applicationContext
        loadReports()
    }

    fun submitReport(
        reporterUsername: String,
        reportedUsername: String,
        category: String,
        description: String,
        includeConversation: Boolean
    ) {
        val report = UserReport(
            id = UUID.randomUUID(),
            reporterUsername = reporterUsername,
            reportedUsername = reportedUsername,
            category = category,
            description = description,
            includeConversation = includeConversation,
            timestamp = Date()
        )
        _reports.value = _reports.value + report
        saveReports()
    }

    fun dismissReport(id: UUID) {
        _reports.value = _reports.value.filter { it.id != id }
        saveReports()
    }

    private fun loadReports() {
        try {
            val file = File(appContext.filesDir, REPORTS_FILENAME)
            if (file.exists()) {
                val arr = JSONArray(file.readText())
                val list = mutableListOf<UserReport>()
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    list.add(
                        UserReport(
                            id = UUID.fromString(obj.getString("id")),
                            reporterUsername = obj.getString("reporterUsername"),
                            reportedUsername = obj.getString("reportedUsername"),
                            category = obj.getString("category"),
                            description = obj.optString("description", ""),
                            includeConversation = obj.optBoolean("includeConversation", false),
                            timestamp = try { dateFormat.parse(obj.getString("timestamp")) ?: Date() } catch (e: Exception) { Date() }
                        )
                    )
                }
                _reports.value = list
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    private fun saveReports() {
        try {
            val arr = JSONArray()
            for (r in _reports.value) {
                val obj = JSONObject()
                obj.put("id", r.id.toString())
                obj.put("reporterUsername", r.reporterUsername)
                obj.put("reportedUsername", r.reportedUsername)
                obj.put("category", r.category)
                obj.put("description", r.description)
                obj.put("includeConversation", r.includeConversation)
                obj.put("timestamp", dateFormat.format(r.timestamp))
                arr.put(obj)
            }
            File(appContext.filesDir, REPORTS_FILENAME).writeText(arr.toString(2))
        } catch (e: Exception) { e.printStackTrace() }
    }
}
