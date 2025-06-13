import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.buildFeatures.swabra

version = "2025.03"

project {
    buildType(TrivyScan)
}

object TrivyScan : BuildType({
    name = "Trivy Scan"
    
    params {
        param("DOCKER_TAG", "%build.number%-%build.vcs.number.1%")  
    }

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Build and Trivy Scan"
            id = "build_and_trivy_scan"
            scriptContent = """
                #!/bin/sh
                set -e
                
                echo "Building Docker image..."
                docker build \
                    --pull \
                    --no-cache=false \
                    -t scan-image:%DOCKER_TAG% \
                    -f Dockerfile .
                
                echo "Running Trivy scan..."
                docker run --rm \
                    -v "%system.teamcity.build.checkoutDir%:/workspace" \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest \
                    image \
                    scan-image:%DOCKER_TAG% \
                    --format json \
                    --output /workspace/trivy-results.json \
                    --severity HIGH,CRITICAL
                
                echo "Trivy scan completed. Results saved to trivy-results.json"
            """.trimIndent()
            dockerImage = "docker:latest"
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
            dockerPull = true
            dockerRunParameters = """
                -v "%system.teamcity.build.checkoutDir%:/workspace"
                -v /var/run/docker.sock:/var/run/docker.sock
                -w /workspace
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
    
    // Artifact Rules to save Trivy scan results
    artifactRules = """
        trivy-results.json
    """.trimIndent()
})