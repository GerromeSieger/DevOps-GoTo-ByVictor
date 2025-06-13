import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.buildFeatures.swabra

version = "2025.03"

project {
    buildType(CheckovScan)
}

object CheckovScan : BuildType({
    name = "Checkov Security Scan"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Checkov Scan"
            id = "checkov_scan"
            scriptContent = """
                #!/bin/bash
                echo "Running Checkov Scan"
                
                # Create results directory
                mkdir -p "%system.teamcity.build.checkoutDir%/results"
                
                # Install and run Checkov
                pip install checkov && \
                echo 'Running Checkov scan...' && \
                checkov -d . \
                    --framework terraform,cloudformation,kubernetes,dockerfile,helm \
                    --soft-fail \
                    --quiet \
                    --output sarif > "%system.teamcity.build.checkoutDir%/results/checkov-output.sarif" 2>&1 || echo 'Checkov completed with findings'
                
                echo "Scan completed. Results saved to results/checkov-output.sarif"
            """.trimIndent()
            dockerImage = "python:3.11-slim"
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
            dockerPull = true
            dockerRunParameters = "-v \"%system.teamcity.build.checkoutDir%:/scan-target\" -w /scan-target"
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
    
    // Artifact Rules to save Checkov scan results
    artifactRules = """
        results/checkov-output.sarif
    """.trimIndent()
})