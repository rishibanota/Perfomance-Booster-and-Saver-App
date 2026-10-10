plugins {
    id("com.android.application")
}

android {
    namespace = "com.example.perfomance_booster.micro"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.perfomance_booster.micro"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0-micro"

        // Strip all non-English localized strings to ensure minimal APK size
        resConfigs("en")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Maximum size optimizations: R8 code shrinking and resource stripping
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
