import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.buildFeatures.swabra

version = "2025.03"

project {
    buildType(GitGuardianScan)
}

object GitGuardianScan : BuildType({
    name = "Git-Guardian Scan"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Git Guardian Scan"
            id = "gg_scan"
            scriptContent = """
                #!/bin/bash
                echo "Running GitGuardian Scan"
                
                ggshield secret scan path -y --json --show-secrets --recursive . \
                    --output ./ggshield_report.json
            """.trimIndent()
            dockerImage = "gitguardian/ggshield:latest"
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
            dockerPull = true
            dockerRunParameters = """
                -v "%system.teamcity.build.checkoutDir%:/scan-target" 
                -w /scan-target
                -e GITGUARDIAN_API_KEY="%env.GITGUARDIAN_API_KEY%"
                -e GITGUARDIAN_DONT_USE_GIT=true
            """.trimIndent()
        }
    }

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
        swabra {
            forceCleanCheckout = true
            verbose = true
        }
    }
    
    artifactRules = """
        ggshield_report*.json
    """.trimIndent()
})