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
    commandLine = listOf("zig", "build", "-Doptimize=ReleaseFast")
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
    jvmArgs = listOf(
        "-XX:+UnlockDiagnosticVMOptions",
        "-XX:+UnlockExperimentalVMOptions",
        "-XX:+PrintAssembly",
        "-XX:PrintAssemblyOptions=intel"
        //"-XX:CompileCommand=print,*NoiseGeneratorImproved.populateNoiseArray" //,PrintNativeNMethods,PrintSignatureHandlers,PrintAdapterHandlers"
    )
}

tasks.jmh {
    dependsOn += compileZig
}
