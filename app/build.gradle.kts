plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

// Номер сборки берётся из GitHub Actions (GITHUB_RUN_NUMBER); локально — 0.
val runNumber: Int = (System.getenv("GITHUB_RUN_NUMBER") ?: "0").toIntOrNull() ?: 0

android {
    namespace = "ru.hotelkms.tv"
    compileSdk = 34

    defaultConfig {
        applicationId = "ru.hotelkms.tv"
        minSdk = 24
        targetSdk = 34
        versionCode = maxOf(1, runNumber)
        versionName = "1.0.$runNumber"
    }

    signingConfigs {
        getByName("debug") {
            // В CI подставляется постоянный debug-ключ из кэша (см. build.yml),
            // чтобы новые сборки ставились поверх старых. Пароли стандартные debug ("android").
            val ks = System.getenv("DEBUG_KEYSTORE")
            if (!ks.isNullOrBlank() && file(ks).exists()) {
                storeFile = file(ks)
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
        }
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }
}

dependencies {
    // Намеренно без внешних библиотек — APK должен быть маленьким.
}
