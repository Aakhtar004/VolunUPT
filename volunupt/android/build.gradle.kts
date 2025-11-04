allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround for AGP 8+ requiring namespace in library modules.
// Some third-party plugins (e.g., qr_code_scanner 1.0.1) don't declare it.
// We set the namespace here to unblock builds until the plugin is updated.
subprojects {
    plugins.withId("com.android.library") {
        // 1) Namespace workaround for older plugins
        if (project.name.contains("qr_code_scanner")) {
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                try {
                    // Use reflection to call setNamespace to avoid compile-time dependency on AGP classes
                    val method = androidExt.javaClass.methods.firstOrNull {
                        it.name == "setNamespace" && it.parameterTypes.size == 1
                    }
                    method?.invoke(androidExt, "com.thirdparty.qr_code_scanner")
                } catch (_: Exception) {
                    // Ignore if not available; build will fail only if the plugin truly lacks namespace
                }
            }
        }

        // 2) Force Java 17 compile options for all Android library subprojects
        //    Align with AGP 8+ which requires JDK 17, avoiding JVM target mismatch
        try {
            val androidExt = extensions.findByName("android")
            val compileOptionsProp = androidExt?.javaClass?.methods?.firstOrNull { it.name == "getCompileOptions" }
            val compileOptions = compileOptionsProp?.invoke(androidExt)
            val setSource = compileOptions?.javaClass?.methods?.firstOrNull { it.name == "setSourceCompatibility" }
            val setTarget = compileOptions?.javaClass?.methods?.firstOrNull { it.name == "setTargetCompatibility" }
            setSource?.invoke(compileOptions, JavaVersion.VERSION_17)
            setTarget?.invoke(compileOptions, JavaVersion.VERSION_17)
        } catch (_: Exception) {
            // Best-effort; ignore if the plugin/AGP version doesn't expose these APIs
        }
    }
}

// Also enforce Java 11 on all JavaCompile/KotlinCompile tasks across subprojects to avoid 'source/target 8 is obsolete' warnings.
subprojects {
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        // Do not use options.release with Android Gradle Plugin (AGP) per Google guidance
        options.compilerArgs.add("-Xlint:-options")
        options.encoding = "UTF-8"
    }
    // Apply Kotlin JVM target 17 uniformly across subprojects
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

// Remove special-case for mobile_scanner; align all modules to JVM 17 to avoid inconsistency
// Special-case: some third-party plugins (e.g., mobile_scanner) still compile Java at 1.8.
// To avoid JVM target inconsistency errors within that plugin, align Kotlin to 1.8 as well.
subprojects {
    if (project.name.contains("mobile_scanner")) {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = "1.8"
        }
        tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_1_8.toString()
            targetCompatibility = JavaVersion.VERSION_1_8.toString()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
