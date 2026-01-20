name: Simple Android Build

on: [push, workflow_dispatch]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Android SDK
      uses: android-actions/setup-android@v3
      
    - name: Setup Java
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
        
    - name: Create project files
      run: |
        # Создаем все необходимые файлики
        mkdir -p app/src/main/java/ru/protivost/app
        mkdir -p app/src/main/res/layout
        mkdir -p app/src/main/res/values
        
        # MainActivity.kt
        cat > app/src/main/java/ru/protivost/app/MainActivity.kt << 'EOF'
package ru.protivost.app

import android.os.Bundle
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val webView = WebView(this)
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.loadUrl("https://protivost.top")
        setContentView(webView)
    }
}
EOF

        # activity_main.xml
        cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout 
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">
    <WebView
        android:id="@+id/webView"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</androidx.constraintlayout.widget.ConstraintLayout>
EOF

        # strings.xml
        cat > app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Противостояния Тьмы</string>
</resources>
EOF

        # AndroidManifest.xml
        cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

    - name: Build with direct commands
      run: |
        # Создаем build.gradle на лету и собираем
        cat > build.gradle << 'EOF'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0"
    }
}
allprojects {
    repositories { google(); mavenCentral() }
}
EOF

        cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}
android {
    compileSdk 33
    defaultConfig {
        applicationId "ru.protivost.app"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release { minifyEnabled false }
    }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
EOF

        # Используем локально установленный gradle
        gradle wrapper --gradle-version 8.4
        chmod +x gradlew
        ./gradlew assembleDebug --no-daemon --stacktrace
        
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: protivost-app
        path: app/build/outputs/apk/debug/*.apk