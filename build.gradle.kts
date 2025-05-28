plugins {
    id("com.gtnewhorizons.gtnhconvention")
}

minecraft {
    javaCompatibilityVersion = 24
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(24)
    }

    sourceCompatibility = JavaVersion.VERSION_24
    targetCompatibility = JavaVersion.VERSION_24
}
