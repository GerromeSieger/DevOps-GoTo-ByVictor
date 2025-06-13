import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.buildFeatures.swabra

version = "2024.03"

project {
    buildType(TruffleHogScan)
}

object TruffleHogScan : BuildType({
    name = "TruffleHog Security Scan"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "TruffleHog Scan"
            scriptContent = """
                #!/bin/bash
                echo "Running TruffleHog Scan"
                
                # Create results directory
                mkdir -p "%system.teamcity.build.checkoutDir%/results"
                
                # Create report header
                cat > "%system.teamcity.build.checkoutDir%/results/trufflehog-report.md" << EOF
                # TruffleHog Security Scan Results
                **Repository:** GerromeApp 
                **Build:** %build.number%  
                **Date:** $(date)
                
                ## Findings
                
                EOF
                
                # Run TruffleHog scan using Docker
                docker run --rm \
                  -v "%system.teamcity.build.checkoutDir%:/scan-target" \
                  python:3.9-slim \
                  sh -c "apt-get update && apt-get install -y git && \
                         pip install trufflehog==2.2.1 && \
                         cd /scan-target && \
                         trufflehog . > /scan-target/results/scan_output.txt || true"
                
                # Check results and update report
                if [ -s "%system.teamcity.build.checkoutDir%/results/scan_output.txt" ]; then
                    echo "### Security issues detected:" >> "%system.teamcity.build.checkoutDir%/results/trufflehog-report.md"
                    echo '```' >> "%system.teamcity.build.checkoutDir%/results/trufflehog-report.md"
                    cat "%system.teamcity.build.checkoutDir%/results/scan_output.txt" >> "%system.teamcity.build.checkoutDir%/results/trufflehog-report.md"
                    echo '```' >> "%system.teamcity.build.checkoutDir%/results/trufflehog-report.md"
                else
                    echo "No security issues found." >> "%system.teamcity.build.checkoutDir%/results/trufflehog-report.md"
                fi
                
                echo "Scan completed. Results saved to results/trufflehog-report.md"
            """.trimIndent()
        }
        
        script {
            name = "Cleanup Docker Images"
            executionMode = BuildStep.ExecutionMode.ALWAYS
            scriptContent = """
                #!/bin/bash
                echo "Cleaning up Docker images"
                
                docker image prune -f || true
                docker rmi python:3.9-slim --force || true
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
        results/trufflehog-report.md
        results/scan_output.txt
    """.trimIndent()
})