import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.maven
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
        maven {
            id = "MavenBuild"
            goals = "clean package"
            runnerArgs = "-Dmaven.test.skip=true"
        }
    }

    artifactRules = """
        target/*.jar => artifacts
    """.trimIndent()

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
    }
})