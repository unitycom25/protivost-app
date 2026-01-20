package ru.protivost.app

import android.content.Context
import android.webkit.JavascriptInterface

class WebAppInterface(private val context: Context) {
    
    @JavascriptInterface
    fun showNotification(messageCount: String, journalCount: String) {
        // Пока пустая реализация
        // Можно добавить позже
    }
}