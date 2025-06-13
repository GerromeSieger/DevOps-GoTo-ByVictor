import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.DockerCommandStep
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

version = "2024.12"

project {
    buildType(Sonar)
}

object Sonar : BuildType({
    name = "Sonar"

    steps {
        dockerCommand {
            name = "Run SonarQube Analysis"
            commandType = other {
                subCommand = "run"
                commandArgs = """
                    --rm 
                    -v %system.teamcity.build.checkoutDir%:/usr/src
                    -e SONAR_HOST_URL=%env.SONAR_HOST_URL% 
                    -e SONAR_TOKEN=%env.SONAR_TOKEN% 
                    sonarsource/sonar-scanner-cli:latest 
                    sonar-scanner 
                    -Dsonar.projectKey=%env.SONAR_PROJECT_KEY% 
                    -Dsonar.projectName=%env.SONAR_PROJECT_NAME% 
                    -Dsonar.sources=/usr/src
                    -Dsonar.scm.disabled=true
                """.trimIndent()
            }
        }
    }

    vcs {
        root(DslContext.settingsRoot)
    }

    triggers {
        vcs { }
    }

    features {
        perfmon { }
    }
})