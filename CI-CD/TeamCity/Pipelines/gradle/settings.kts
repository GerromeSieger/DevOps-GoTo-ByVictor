import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.gradle
import jetbrains.buildServer.configs.kotlin.buildSteps.GradleBuildStep666
import jetbrains.buildServer.configs.kotlin.triggers.vcs

version = "2025.03"

project {
    buildType(Build)
}

object Build : BuildType({
    name = "Build"
    vcs {
        root(DslContext.settingsRoot)
    }
    steps {
        gradle {
            id = "gradle_runner"
            tasks = "build"
            gradleWrapperPath = "./"
            dockerImage = "gradle:7.4-jdk17"
            dockerImagePlatform = GradleBuildStep.ImagePlatform.Any
        }        
    }
    triggers {
        vcs {
        }
    }
    features {
        perfmon {
        }
    }
    artifactRules = """
        build/libs/*.jar
    """.trimIndent()    
})