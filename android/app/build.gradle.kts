plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.test_project"
    compileSdk = 36  // 직접 지정

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // 17로 변경
        targetCompatibility = JavaVersion.VERSION_17  // 17로 변경
    }

    kotlinOptions {
        jvmTarget = "17"  // 17로 변경
    }

    defaultConfig {
        applicationId = "com.example.test_project"
        minSdk = flutter.minSdkVersion  // 직접 지정
        targetSdk = 36  // 직접 지정
        versionCode = 1
        versionName = "1.0"
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
