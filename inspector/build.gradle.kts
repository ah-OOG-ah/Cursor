plugins {
    id("application")
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.openjdk.jol:jol-core:0.10")
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

application {
    applicationName = "inspector"
    mainClass = "klaxon.klaxon.inspector.Inspector"
}

val runTask = tasks.register<JavaExec>("runInspector") {
    group = "application"

    javaLauncher = javaToolchains.launcherFor {
        languageVersion.set(JavaLanguageVersion.of(24))
    }

    classpath = sourceSets["main"].runtimeClasspath
    mainClass = application.mainClass

    jvmArgs = listOf("-Djdk.attach.allowAttachSelf", "-XX:+EnableDynamicAgentLoading", "-Djol.tryWithSudo=true")
}

//tasks.replace("run", JavaExec::class).dependsOn(runTask)
