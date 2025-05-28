plugins {
    id("com.gtnewhorizons.gtnhconvention")
}

minecraft {
    javaCompatibilityVersion = 25
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }

    sourceCompatibility = JavaVersion.VERSION_25
    targetCompatibility = JavaVersion.VERSION_25
}
/*
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("--enable-preview")
}//*/
