// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Flutter 3.35.6 ve Java 17 ile uyumlu sürüm
        classpath("com.android.tools.build:gradle:8.3.0")
        classpath(kotlin("gradle-plugin", version = "1.9.22"))
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Flutter'ın build klasör yolunu ayarlama
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
