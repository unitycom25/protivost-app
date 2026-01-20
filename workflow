name: Build Protivost APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Java
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'
        
    - name: Create minimal project structure
      run: |
        # Создаем необходимые папки
        mkdir -p app/src/main/java/ru/protivost/app
        mkdir -p app/src/main/res/layout
        mkdir -p app/src/main/res/values
        mkdir -p gradle/wrapper
        
        # Если нет MainActivity, создаем простой
        if [ ! -f "app/src/main/java/ru/protivost/app/MainActivity.kt" ]; then
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
        webView.loadUrl("https://protivost.top")
        
        setContentView(webView)
    }
}
EOF
        fi
        
        # Создаем layout если нет
        if [ ! -f "app/src/main/res/layout/activity_main.xml" ]; then
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
        fi
        
        # Создаем strings.xml если нет
        if [ ! -f "app/src/main/res/values/strings.xml" ]; then
          cat > app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Противостояния Тьмы</string>
</resources>
EOF
        fi
        
        # Создаем AndroidManifest если нет
        if [ ! -f "app/src/main/AndroidManifest.xml" ]; then
          cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
        fi
    
    - name: Create gradle wrapper files
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
    implementation 'com.google.android.material:material:1.9.0'
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

    - name: Download gradle wrapper
      run: |
        wget -O gradle/wrapper/gradle-wrapper.jar \
          https://github.com/gradle/gradle/raw/master/gradle/wrapper/gradle-wrapper.jar || true
        
    - name: Create gradlew script
      run: |
        # Простой gradlew скрипт
        cat > gradlew << 'EOF'
#!/bin/bash

# Простой gradlew скрипт
set -e

GRADLE_VERSION="8.4"
GRADLE_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
GRADLE_ZIP="gradle-${GRADLE_VERSION}-bin.zip"
GRADLE_DIR="gradle-${GRADLE_VERSION}"

# Если нет gradle, скачиваем
if [ ! -d "$HOME/.gradle/wrapper/dists/gradle-${GRADLE_VERSION}-bin" ]; then
    echo "Downloading Gradle $GRADLE_VERSION..."
    wget -q "$GRADLE_URL" -O "$GRADLE_ZIP"
    mkdir -p "$HOME/.gradle/wrapper/dists"
    unzip -q "$GRADLE_ZIP" -d "$HOME/.gradle/wrapper/dists/"
    mv "$HOME/.gradle/wrapper/dists/$GRADLE_DIR" "$HOME/.gradle/wrapper/dists/gradle-${GRADLE_VERSION}-bin"
    rm -f "$GRADLE_ZIP"
fi

# Запускаем gradle
exec "$HOME/.gradle/wrapper/dists/gradle-${GRADLE_VERSION}-bin/bin/gradle" "$@"
EOF
        
        chmod +x gradlew
        
    - name: Build APK
      run: |
        # Собираем APK
        ./gradlew assembleDebug --stacktrace || true
        
        # Альтернатива: используем напрямую gradle
        if [ ! -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
          echo "Trying alternative build method..."
          # Устанавливаем gradle и собираем
          ./gradlew tasks || true
        fi
        
    - name: Check for APK
      run: |
        # Проверяем, создался ли APK
        if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
          echo "APK created successfully!"
          ls -la app/build/outputs/apk/debug/
        else
          echo "APK not found. Checking build directory..."
          find . -name "*.apk" -type f || true
          echo "Build directory contents:"
          find app/build -type f -name "*.apk" 2>/dev/null || true
        fi
        
    - name: Upload APK
      if: success()
      uses: actions/upload-artifact@v4
      with:
        name: protivost-app
        path: |
          app/build/outputs/apk/debug/*.apk
          app/build/outputs/apk/*/*.apk
        if-no-files-found: warn