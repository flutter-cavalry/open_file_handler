package com.fluttercavalry.open_file_handler

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException

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
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        private var instance: OpenFileHandlerPlugin? = null

        private var coldOpenURI: Uri? = null
        private var coldAlwaysCopy = false

        fun handleOpenURI(
            uri: Uri,
            alwaysCopy: Boolean,
        ) {
            if (uri.scheme != "file" && uri.scheme != "content") return
            val plugin = instance
            if (plugin?.eventSink != null && plugin.context != null) {
                plugin.processURI(uri, alwaysCopy, plugin.eventSink!!)
            } else {
                coldOpenURI = uri
                coldAlwaysCopy = alwaysCopy
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
        result: Result,
    ) {
        result.notImplemented()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventSink = null
        context = null
        if (instance === this) {
            instance = null
        }
        scope.cancel()
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        eventSink = events
        val uri = coldOpenURI
        val context = context
        if (events != null && context != null && uri != null) {
            coldOpenURI = null
            processURI(uri, coldAlwaysCopy, events)
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun processURI(
        uri: Uri,
        alwaysCopy: Boolean,
        sink: EventChannel.EventSink,
    ) {
        val context = context ?: return
        scope.launch {
            val mapped = mapURI(context, uri, alwaysCopy)
            withContext(Dispatchers.Main.immediate) {
                if (eventSink === sink) {
                    sink.success(mapped)
                }
            }
        }
    }
}

fun getFileNameAndExtension(
    context: Context,
    uri: Uri,
): Pair<String?, String?> {
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
    val extension =
        fileName?.substringAfterLast('.', missingDelimiterValue = "")?.takeIf {
            it.isNotEmpty()
        }

    return Pair(fileName, extension)
}

@Throws(Exception::class)
fun copyUriToTmp(
    context: Context,
    uri: Uri,
    fileName: String?,
): String {
    val directory = File(context.cacheDir, "_app/open_file_handler")
    if (!directory.isDirectory && !directory.mkdirs()) {
        throw IOException("Unable to create cache directory: $directory")
    }
    val name = File(fileName ?: "file").name.takeUnless { it.isEmpty() || it == "." || it == ".." } ?: "file"
    val tmpFile = File(directory, name)

    val input =
        context.contentResolver.openInputStream(uri)
            ?: throw IOException("Unable to open URI: $uri")

    input.use {
        tmpFile.outputStream().use { output ->
            it.copyTo(output)
        }
    }

    return tmpFile.absolutePath
}

fun mapURI(
    context: Context,
    uri: Uri,
    alwaysCopy: Boolean,
): Map<String, Any?> {
    val (fileName) = getFileNameAndExtension(context, uri)
    val shouldCopy = alwaysCopy || !DocumentsContract.isDocumentUri(context, uri)
    val path =
        if (shouldCopy) {
            try {
                copyUriToTmp(context, uri, fileName)
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }

    return mapOf(
        "uri" to uri.toString(),
        "name" to fileName,
        "path" to path,
        "localCopy" to (path != null),
    )
}
