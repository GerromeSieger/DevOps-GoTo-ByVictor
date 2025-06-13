import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.ant
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
        ant {
            id = "AntBuild"
            mode = antFile {
                path = "antbuild.xml"
            }
            targets = "setup-ivy resolve clean build"
            jdkHome = "%env.JDK_HOME%"
        }
    }
    
    artifactRules = """
        build/lib/*.jar => artifacts
        dist/*.jar => artifacts
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