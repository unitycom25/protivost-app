package ru.protivost.app

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    
    private lateinit var webView: WebView
    
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        webView = findViewById(R.id.webView)
        
        // Включаем JavaScript
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        
        // Устанавливаем клиент
        webView.webViewClient = MyWebViewClient()
        
        // Загружаем сайт игры
        webView.loadUrl("https://protivost.top")
    }
    
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
    
    private inner class MyWebViewClient : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
            // Всегда открываем в WebView
            view.loadUrl(url)
            return true
        }
    }
}