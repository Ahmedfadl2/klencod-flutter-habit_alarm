plugins {
    id("com.android.application")
    id("kotlin-android")
    // يجب أن يأتي بعد إضافات أندرويد وكوتلن
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ahmed.habitalarm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // مطلوب لمكتبة الإشعارات
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ahmed.habitalarm"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // مطلوب لمكتبة الإشعارات
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}