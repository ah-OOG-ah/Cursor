plugins {
    id("com.gtnewhorizons.gtnhconvention")
}

var inspector = sourceSets.create("inspector") {
    java.srcDir("src/inspector/java")
}

tasks {
    val inspectorJar = register<Jar>("buildInspector") {
        group = "build"
        description = "Build JAR for Inspector"
        archiveBaseName = "inspector"

        manifest {
            attributes("Main-Class" to "klaxon.klaxon.inspector.Inspector")
        }

        from(inspector.output)
    }

    register<JavaExec>("runInspector") {
        group = "build"
        description = "Run Inspector"

        classpath = files(inspectorJar)
    }
}
