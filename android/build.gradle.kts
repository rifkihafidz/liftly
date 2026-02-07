import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.projectDirectory
        .dir("../build")
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (project.name == "isar_flutter_libs") {
            try {
                val android = project.extensions.findByName("android")
                if (android != null) {
                    val namespaceProp = android::class.members.find { it.name == "namespace" }
                    if (namespaceProp != null) {
                        try {
                           // Try to set it dynamically if possible, or cast
                           // In Kotlin DSL, dynamic is tricky.
                           // Let's assume we can cast if we imported LibraryExtension.
                           if (android is LibraryExtension) {
                               if (android.namespace == null) {
                                   android.namespace = "dev.isar.isar_flutter_libs"
                               }
                           }
                        } catch (e: Exception) {
                            println("Could not set namespace for isar_flutter_libs: $e")
                        }
                    }
                }
            } catch (e: Exception) {
                println("Error configuring isar_flutter_libs: $e")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
