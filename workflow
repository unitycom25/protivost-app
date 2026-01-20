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
        
    - name: Create gradlew if missing
      run: |
        # Если нет gradlew, создаем его
        if [ ! -f "gradlew" ]; then
          echo "Creating gradlew script..."
          
          # Создаем директорию для wrapper
          mkdir -p gradle/wrapper
          
          # Создаем gradle-wrapper.properties
          cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
          
          # Простой gradlew скрипт
          cat > gradlew << 'EOF'
#!/bin/bash
# Простой gradlew скрипт
set -e

# Если JAVA_HOME не установлен, пробуем найти java
if [ -z "$JAVA_HOME" ]; then
    JAVA_CMD=$(which java)
    if [ -z "$JAVA_CMD" ]; then
        echo "Error: Java not found"
        exit 1
    fi
else
    JAVA_CMD="$JAVA_HOME/bin/java"
fi

# Запускаем gradle через wrapper
exec "$JAVA_CMD" \
    -Dgradle.user.home="$PWD/.gradle-cache" \
    -cp "$PWD/gradle/wrapper/gradle-wrapper.jar" \
    org.gradle.wrapper.GradleWrapperMain \
    "$@"
EOF
          
          chmod +x gradlew
          echo "gradlew created successfully"
        else
          echo "gradlew already exists"
        fi
        
    - name: Make gradlew executable
      run: chmod +x gradlew
      
    - name: Verify project structure
      run: |
        # Проверяем базовую структуру проекта
        echo "Checking project structure..."
        ls -la
        
        # Если нет build.gradle, создаем минимальный
        if [ ! -f "build.gradle" ]; then
          echo "Creating build.gradle..."
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
EOF
        fi
        
        # Если нет settings.gradle
        if [ ! -f "settings.gradle" ]; then
          echo "Creating settings.gradle..."
          cat > settings.gradle << 'EOF'
rootProject.name = "ProtivostApp"
include ':app'
EOF
        fi
        
    - name: Build with Gradle
      run: |
        # Проверяем команды gradle
        ./gradlew tasks --daemon || true
        
        # Пробуем собрать
        ./gradlew assembleDebug --stacktrace || ./gradlew build --stacktrace
        
    - name: Find and upload APK
      uses: actions/upload-artifact@v4
      with:
        name: protivost-app
        path: |
          app/build/outputs/apk/**/*.apk
          **/*.apk
        if-no-files-found: warn