package com.fluttercavalry.open_file_handler_example

import android.content.Intent
import android.os.Bundle
import com.fluttercavalry.open_file_handler.OpenFileHandlerPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_VIEW
            || intent.action == Intent.ACTION_EDIT
            // If `Intent.ACTION_SEND` is present in `AndroidManifest.xml`, it should be handled here as well.
            || intent.action == Intent.ACTION_SEND
        ) {
            val uri = intent.data ?: intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
            if (uri != null) {
                val copyToLocal = true;
                OpenFileHandlerPlugin.handleOpenURIs(
                    listOf(uri),
                    copyToLocal,
                    intent.action != Intent.ACTION_SEND
                )
            }
        }
    }
}
