package com.fluttercavalry.open_file_handler

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

/** OpenFileHandlerPlugin */
class OpenFileHandlerPlugin :
    FlutterPlugin,
    EventChannel.StreamHandler,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private var instance: OpenFileHandlerPlugin? = null

        private var coldOpenURIs: List<Uri> = emptyList()

        fun handleOpenURIs(uris: List<Uri>, copyToLocal: Boolean) {
            val eventSink = instance?.eventSink
            val context = instance?.context
            if (eventSink != null && context != null) {
                val mapped = mapURIs(context, uris, copyToLocal)
                eventSink.success(mapped)
            } else {
                coldOpenURIs = uris
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "open_file_handler")
        channel.setMethodCallHandler(this)

        val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "open_file_handler/hot_uris")
        eventChannel.setStreamHandler(this)

        instance = this
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        result.notImplemented()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (OpenFileHandlerPlugin.coldOpenURIs.isNotEmpty()) {
            // Launch on main dispatcher to ensure eventSink is ready
            CoroutineScope(Dispatchers.Main).launch {
                val context = context
                if (context != null) {
                    val mapped = mapURIs(context, coldOpenURIs, true)
                    eventSink?.success(mapped)
                    coldOpenURIs = emptyList()
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}

fun getFileNameAndExtension(context: Context, uri: Uri): Pair<String?, String?> {
    var fileName: String? = null

    // Case 1: Content URI (most common with SAF and external apps)
    if (uri.scheme == "content") {
        val projection = arrayOf(OpenableColumns.DISPLAY_NAME)
        context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index != -1) {
                    fileName = cursor.getString(index)
                }
            }
        }
    }

    // Case 2: File URI
    if (fileName == null && uri.scheme == "file") {
        fileName = File(uri.path ?: "").name
    }

    // Extract extension
    val extension = fileName?.substringAfterLast('.', missingDelimiterValue = "")

    return Pair(fileName, extension)
}

@Throws(Exception::class)
fun copyUriToTmp(context: Context, uri: Uri, ext: String?): String {
    val tmpFile =
        File(context.cacheDir, UUID.randomUUID().toString() + if (ext != null) ".$ext" else "")

    context.contentResolver.openInputStream(uri)?.use { input ->
        FileOutputStream(tmpFile).use { output ->
            input.copyTo(output)
        }
    }

    return tmpFile.absolutePath
}

fun mapURIs(context: Context, uris: List<Uri>, copyToLocal: Boolean): List<Map<String, String?>> {
    return uris.map { uri ->
        val (fileName, extension) = getFileNameAndExtension(context, uri)
        val path = if (copyToLocal) {
            try {
                copyUriToTmp(context, uri, extension)
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }

        mapOf(
            "uri" to uri.toString(),
            "name" to fileName,
            "path" to path
        )
    }
}