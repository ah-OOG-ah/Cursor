plugins {
    id("application")
    id("com.gradleup.shadow")
    id("me.champeau.jmh") version "0.7.3"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.openjdk.jol:jol-core:0.10")
    implementation(rootProject.sourceSets["patchedMc"].output)
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(25))
    }
}

application {
    applicationName = "inspector"
    mainClass = "klaxon.klaxon.inspector.Inspector"
}

tasks.jar {
    manifest {
        attributes(
            "Main-Class" to application.mainClass,
            "Premain-Class" to "org.openjdk.jol.vm.InstrumentationSupport",
            "Launcher-Agent-Class" to "org.openjdk.jol.vm.InstrumentationSupport\$Installer"
        )
    }
}

val compileZig = tasks.register<Exec>("compileZig") {
    group = "build"

    workingDir = File("../")
    commandLine = listOf("zig", "build")
}

val copyZigNatives = tasks.register<Copy>("copyZigNatives") {
    from(File(rootProject.rootDir, "zig-out/lib/libCursor.so"))
    into(project.layout.buildDirectory)
    dependsOn += compileZig
}

tasks.register<JavaExec>("runInspector") {
    group = "application"

    javaLauncher = javaToolchains.launcherFor {
        languageVersion.set(JavaLanguageVersion.of(25))
    }

    classpath = sourceSets["main"].runtimeClasspath
    mainClass = application.mainClass

    jvmArgs = listOf("-Djdk.attach.allowAttachSelf", "-XX:+EnableDynamicAgentLoading", "-Djol.tryWithSudo=true")
}

jmh {
    // These arguments cause the JVM to print assembly output for compiled functions
    /*jvmArgs = listOf(
        "-XX:+UnlockDiagnosticVMOptions",
        "-XX:+UnlockExperimentalVMOptions",
        "-XX:+PrintAssembly",
        "-XX:PrintAssemblyOptions=intel"
    )*/

    jvmArgs = listOf("--enable-native-access=ALL-UNNAMED", "-Dcursor.libLoc=build/libCursor.so")
}

tasks["compileJmhJava"].dependsOn(copyZigNatives)

tasks.jmh {
    dependsOn += copyZigNatives
}
