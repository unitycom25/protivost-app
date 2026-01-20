name: Build APK without Gradlew

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Java
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'
        
    - name: Setup Android SDK
      uses: android-actions/setup-android@v2
      
    - name: Create project structure
      run: |
        # Удаляем битый gradlew если есть
        rm -f gradlew
        
        # Создаем структуру проекта
        mkdir -p app/src/main/java/ru/protivost/app
        mkdir -p app/src/main/res/layout
        mkdir -p app/src/main/res/values
        mkdir -p gradle/wrapper
        
    - name: Create minimal files
      run: |
        # Корневой build.gradle
        cat > build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

        # settings.gradle
        cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "ProtivostApp"
include ':app'
EOF

        # app/build.gradle
        cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'ru.protivost.app'
    compileSdk 33

    defaultConfig {
        applicationId "ru.protivost.app"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.10.1'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.webkit:webkit:1.6.1'
}
EOF

        # gradle/wrapper/gradle-wrapper.properties
        cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

        # MainActivity.kt
        cat > app/src/main/java/ru/protivost/app/MainActivity.kt << 'EOF'
package ru.protivost.app

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    @SuppressLint("SetJavaScriptEnabled")
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

        # AndroidManifest.xml
        cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="Противостояния Тьмы"
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

        # activity_main.xml
        cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">
    <WebView
        android:id="@+id/webView"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</LinearLayout>
EOF

        # strings.xml
        cat > app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Противостояния Тьмы</string>
</resources>
EOF

    - name: Generate gradlew
      run: |
        # Создаем чистый gradlew
        cat > gradlew << 'EOF'
#!/bin/bash

# Устанавливаем gradle если нет
if ! command -v gradle &> /dev/null; then
    echo "Installing Gradle..."
    wget -q https://services.gradle.org/distributions/gradle-8.4-bin.zip
    unzip -q gradle-8.4-bin.zip
    export PATH="$PWD/gradle-8.4/bin:$PATH"
    rm gradle-8.4-bin.zip
fi

# Запускаем gradle напрямую
gradle "$@"
EOF
        
        chmod +x gradlew
        
    - name: Build APK
      run: |
        # Используем системный gradle
        gradle wrapper
        ./gradlew assembleDebug --stacktrace
        
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: protivost-app
        path: app/build/outputs/apk/debug/*.apk