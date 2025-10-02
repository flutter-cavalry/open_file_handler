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
        if (intent.action == Intent.ACTION_VIEW || intent.action == Intent.ACTION_EDIT) {
            val uri = intent.data
            if (uri != null) {
                OpenFileHandlerPlugin.handleOpenURIs(listOf(uri))
            }
        }
    }
}
