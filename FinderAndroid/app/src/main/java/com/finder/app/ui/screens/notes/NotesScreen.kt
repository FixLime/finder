package com.finder.app.ui.screens.notes

import android.content.Context
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.finder.app.services.HapticService
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.glassCard
import com.finder.app.ui.theme.glassTextField
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

// -- Note & NoteCategory models (local to this screen) --

enum class NoteCategory(
    val ruName: String,
    val color: Color,
    val iconRotation: Float = 0f
) {
    ALL("\u0412\u0441\u0435", Color(0xFF9E9E9E)),
    PERSONAL("\u041B\u0438\u0447\u043D\u043E\u0435", Color(0xFF2196F3)),
    WORK("\u0420\u0430\u0431\u043E\u0442\u0430", Color(0xFF4CAF50)),
    IDEAS("\u0418\u0434\u0435\u0438", Color(0xFFFF9800)),
    IMPORTANT("\u0412\u0430\u0436\u043D\u043E\u0435", Color(0xFFF44336)),
    OTHER("\u0414\u0440\u0443\u0433\u043E\u0435", Color(0xFF9C27B0));

    companion object {
        /** Categories suitable for note assignment (excludes ALL filter) */
        val assignable: List<NoteCategory>
            get() = entries.filter { it != ALL }
    }
}

data class Note(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val category: NoteCategory,
    val isPinned: Boolean,
    val timestamp: Long = System.currentTimeMillis()
)

// -- Persistence helpers --

private const val NOTES_PREFS = "finder_notes"
private const val NOTES_KEY = "notes_json"

private fun loadNotes(context: Context): List<Note> {
    val prefs = context.getSharedPreferences(NOTES_PREFS, Context.MODE_PRIVATE)
    val raw = prefs.getString(NOTES_KEY, null) ?: return emptyList()
    return try {
        val arr = JSONArray(raw)
        (0 until arr.length()).map { i ->
            val obj = arr.getJSONObject(i)
            Note(
                id = obj.getString("id"),
                text = obj.getString("text"),
                category = try { NoteCategory.valueOf(obj.getString("category")) } catch (_: Exception) { NoteCategory.OTHER },
                isPinned = obj.optBoolean("isPinned", false),
                timestamp = obj.optLong("timestamp", System.currentTimeMillis())
            )
        }
    } catch (_: Exception) {
        emptyList()
    }
}

private fun saveNotes(context: Context, notes: List<Note>) {
    val arr = JSONArray()
    notes.forEach { note ->
        val obj = JSONObject()
        obj.put("id", note.id)
        obj.put("text", note.text)
        obj.put("category", note.category.name)
        obj.put("isPinned", note.isPinned)
        obj.put("timestamp", note.timestamp)
        arr.put(obj)
    }
    context.getSharedPreferences(NOTES_PREFS, Context.MODE_PRIVATE)
        .edit()
        .putString(NOTES_KEY, arr.toString())
        .apply()
}

// -- Screen --

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class, ExperimentalLayoutApi::class)
@Composable
fun NotesScreen(
    onBack: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val notes = remember { mutableStateListOf<Note>() }
    var selectedFilter by remember { mutableStateOf(NoteCategory.ALL) }
    var showBottomSheet by remember { mutableStateOf(false) }
    var noteToDelete by remember { mutableStateOf<Note?>(null) }

    var appear by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        notes.addAll(loadNotes(context))
        appear = true
    }

    fun persist() = saveNotes(context, notes.toList())

    val filteredNotes = remember(notes.toList(), selectedFilter) {
        val list = if (selectedFilter == NoteCategory.ALL) {
            notes.toList()
        } else {
            notes.filter { it.category == selectedFilter }
        }
        list.sortedWith(compareByDescending<Note> { it.isPinned }.thenByDescending { it.timestamp })
    }

    val dateFormat = remember { SimpleDateFormat("dd.MM.yyyy HH:mm", Locale("ru")) }

    Box(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Top bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = {
                    HapticService.lightTap(haptic)
                    onBack()
                }) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "\u041D\u0430\u0437\u0430\u0434",
                        tint = colors.textPrimary
                    )
                }
                Text(
                    text = "\u0417\u0430\u043C\u0435\u0442\u043A\u0438",
                    style = MaterialTheme.typography.titleLarge,
                    color = colors.textPrimary,
                    fontWeight = FontWeight.Bold
                )
            }

            // Category filter chips
            AnimatedVisibility(
                visible = appear,
                enter = fadeIn() + slideInVertically(
                    initialOffsetY = { -it / 4 },
                    animationSpec = spring(stiffness = Spring.StiffnessLow)
                )
            ) {
                FlowRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    NoteCategory.entries.forEach { category ->
                        val isSelected = selectedFilter == category
                        val bg = if (isSelected) category.color.copy(alpha = 0.2f) else colors.glassCardBackground
                        val borderCol = if (isSelected) category.color.copy(alpha = 0.5f) else colors.glassBorder

                        Box(
                            modifier = Modifier
                                .background(bg, RoundedCornerShape(20.dp))
                                .border(0.5.dp, borderCol, RoundedCornerShape(20.dp))
                                .clickable(
                                    interactionSource = remember { MutableInteractionSource() },
                                    indication = null
                                ) {
                                    HapticService.lightTap(haptic)
                                    selectedFilter = category
                                }
                                .padding(horizontal = 14.dp, vertical = 8.dp)
                        ) {
                            Text(
                                text = category.ruName,
                                style = MaterialTheme.typography.labelLarge,
                                color = if (isSelected) category.color else colors.textSecondary,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Notes list
            if (filteredNotes.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "\u041D\u0435\u0442 \u0437\u0430\u043C\u0435\u0442\u043E\u043A",
                        style = MaterialTheme.typography.bodyLarge,
                        color = colors.textTertiary
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                        .padding(horizontal = 20.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    itemsIndexed(
                        items = filteredNotes,
                        key = { _, note -> note.id }
                    ) { index, note ->
                        AnimatedVisibility(
                            visible = appear,
                            enter = fadeIn() + slideInVertically(
                                initialOffsetY = { it / 3 },
                                animationSpec = spring(
                                    stiffness = Spring.StiffnessLow,
                                    dampingRatio = Spring.DampingRatioMediumBouncy
                                )
                            )
                        ) {
                            NoteCard(
                                note = note,
                                dateFormat = dateFormat,
                                onLongPress = {
                                    HapticService.warning()
                                    noteToDelete = note
                                }
                            )
                        }
                    }
                    item { Spacer(modifier = Modifier.height(80.dp)) }
                }
            }
        }

        // FAB
        FloatingActionButton(
            onClick = {
                HapticService.mediumTap(haptic)
                showBottomSheet = true
            },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(20.dp),
            containerColor = colors.accentBlue,
            contentColor = Color.White,
            shape = CircleShape
        ) {
            Icon(Icons.Filled.Add, contentDescription = "\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C")
        }
    }

    // Delete confirmation dialog
    noteToDelete?.let { note ->
        AlertDialog(
            onDismissRequest = { noteToDelete = null },
            title = {
                Text(
                    text = "\u0423\u0434\u0430\u043B\u0438\u0442\u044C \u0437\u0430\u043C\u0435\u0442\u043A\u0443?",
                    color = colors.textPrimary
                )
            },
            text = {
                Text(
                    text = note.text.take(100) + if (note.text.length > 100) "..." else "",
                    color = colors.textSecondary
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    HapticService.mediumTap(haptic)
                    notes.remove(note)
                    persist()
                    noteToDelete = null
                }) {
                    Text("\u0423\u0434\u0430\u043B\u0438\u0442\u044C", color = colors.errorRed)
                }
            },
            dismissButton = {
                TextButton(onClick = { noteToDelete = null }) {
                    Text("\u041E\u0442\u043C\u0435\u043D\u0430", color = colors.textSecondary)
                }
            },
            containerColor = colors.glassCardBackground
        )
    }

    // Bottom sheet for adding a new note
    if (showBottomSheet) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

        ModalBottomSheet(
            onDismissRequest = { showBottomSheet = false },
            sheetState = sheetState,
            containerColor = colors.glassCardBackground,
            dragHandle = null
        ) {
            AddNoteSheet(
                onSave = { text, category, isPinned ->
                    val note = Note(
                        text = text,
                        category = category,
                        isPinned = isPinned
                    )
                    notes.add(note)
                    persist()
                    scope.launch {
                        sheetState.hide()
                        showBottomSheet = false
                    }
                },
                onDismiss = {
                    scope.launch {
                        sheetState.hide()
                        showBottomSheet = false
                    }
                }
            )
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun NoteCard(
    note: Note,
    dateFormat: SimpleDateFormat,
    onLongPress: () -> Unit
) {
    val colors = FinderTheme.colors

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .glassCard()
            .combinedClickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = {},
                onLongClick = onLongPress
            )
            .padding(14.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Category tag
            Box(
                modifier = Modifier
                    .background(note.category.color.copy(alpha = 0.15f), RoundedCornerShape(8.dp))
                    .padding(horizontal = 8.dp, vertical = 3.dp)
            ) {
                Text(
                    text = note.category.ruName,
                    style = MaterialTheme.typography.labelSmall,
                    color = note.category.color,
                    fontWeight = FontWeight.SemiBold
                )
            }

            if (note.isPinned) {
                Icon(
                    imageVector = Icons.Filled.PushPin,
                    contentDescription = "\u0417\u0430\u043A\u0440\u0435\u043F\u043B\u0435\u043D\u043E",
                    tint = colors.warningOrange,
                    modifier = Modifier
                        .size(16.dp)
                        .rotate(45f)
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = note.text,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textPrimary,
            maxLines = 4,
            overflow = TextOverflow.Ellipsis
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = dateFormat.format(Date(note.timestamp)),
            style = MaterialTheme.typography.labelSmall,
            color = colors.textTertiary
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AddNoteSheet(
    onSave: (text: String, category: NoteCategory, isPinned: Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    var text by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf(NoteCategory.PERSONAL) }
    var isPinned by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "\u041D\u043E\u0432\u0430\u044F \u0437\u0430\u043C\u0435\u0442\u043A\u0430",
                style = MaterialTheme.typography.titleLarge,
                color = colors.textPrimary,
                fontWeight = FontWeight.Bold
            )
            IconButton(onClick = {
                HapticService.lightTap(haptic)
                onDismiss()
            }) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = "\u0417\u0430\u043A\u0440\u044B\u0442\u044C",
                    tint = colors.textSecondary
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Text field
        TextField(
            value = text,
            onValueChange = { text = it },
            modifier = Modifier
                .fillMaxWidth()
                .height(140.dp)
                .glassTextField(),
            placeholder = {
                Text(
                    text = "\u0422\u0435\u043A\u0441\u0442 \u0437\u0430\u043C\u0435\u0442\u043A\u0438...",
                    color = colors.textTertiary
                )
            },
            colors = TextFieldDefaults.colors(
                focusedTextColor = colors.textPrimary,
                unfocusedTextColor = colors.textPrimary,
                cursorColor = colors.accentBlue,
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent
            ),
            maxLines = 8
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Category picker
        Text(
            text = "\u041A\u0430\u0442\u0435\u0433\u043E\u0440\u0438\u044F",
            style = MaterialTheme.typography.titleMedium,
            color = colors.textPrimary,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(8.dp))

        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            NoteCategory.assignable.forEach { category ->
                val isSelected = selectedCategory == category
                val bg = if (isSelected) category.color.copy(alpha = 0.2f) else colors.glassCardBackground
                val borderCol = if (isSelected) category.color.copy(alpha = 0.5f) else colors.glassBorder

                Box(
                    modifier = Modifier
                        .background(bg, RoundedCornerShape(20.dp))
                        .border(0.5.dp, borderCol, RoundedCornerShape(20.dp))
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null
                        ) {
                            HapticService.lightTap(haptic)
                            selectedCategory = category
                        }
                        .padding(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = category.ruName,
                        style = MaterialTheme.typography.labelLarge,
                        color = if (isSelected) category.color else colors.textSecondary,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Pin toggle
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .glassCard()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.PushPin,
                    contentDescription = null,
                    tint = colors.textSecondary,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(10.dp))
                Text(
                    text = "\u0417\u0430\u043A\u0440\u0435\u043F\u0438\u0442\u044C",
                    style = MaterialTheme.typography.bodyLarge,
                    color = colors.textPrimary
                )
            }
            Switch(
                checked = isPinned,
                onCheckedChange = {
                    HapticService.lightTap(haptic)
                    isPinned = it
                },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.White,
                    checkedTrackColor = colors.accentBlue,
                    uncheckedThumbColor = colors.textTertiary,
                    uncheckedTrackColor = colors.glassButtonBackground
                )
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Save button
        val canSave = text.isNotBlank()
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(
                    if (canSave) colors.accentBlue else colors.accentBlue.copy(alpha = 0.3f),
                    RoundedCornerShape(16.dp)
                )
                .clickable(
                    enabled = canSave,
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ) {
                    HapticService.success(haptic)
                    onSave(text, selectedCategory, isPinned)
                }
                .padding(vertical = 16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "\u0421\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u044C",
                style = MaterialTheme.typography.titleMedium,
                color = Color.White,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(16.dp))
    }
}
