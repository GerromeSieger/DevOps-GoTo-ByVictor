# GitHub Actions CI/CD Pipeline Examples

## 1. Secret Scanning with GitGuardian

```yaml
name: GitGuardian Secret Scanning

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  scanning:
    name: GitGuardian Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0 # Fetch all history for all branches and tags
      
      - name: GitGuardian scan
        uses: GitGuardian/ggshield-action@master
        env:
          GITHUB_PUSH_BEFORE_SHA: ${{ github.event.before }}
          GITHUB_PUSH_BASE_SHA: ${{ github.event.base }}
          GITHUB_PULL_BASE_SHA: ${{ github.event.pull_request.base.sha }}
          GITHUB_DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}
          GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
          
      - name: Report findings
        if: failure()
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'GitGuardian: Potential secrets detected',
              body: 'The GitGuardian scan has detected potential secrets in the code. Please review the workflow logs.'
            })
```

## 2. Infrastructure Security Scanning with Checkov

```yaml
name: Infrastructure Security Scan

on:
  push:
    paths:
      - '**/*.tf'
      - '**/*.yaml'
      - '**/*.yml'
      - '**/*.json'
      - '.github/workflows/infra-security-scan.yml'
  pull_request:
    paths:
      - '**/*.tf'
      - '**/*.yaml'
      - '**/*.yml'
      - '**/*.json'

jobs:
  checkov-scan:
    name: Checkov
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Run Checkov
        id: checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform,cloudformation,kubernetes,dockerfile,helm
          soft_fail: true
          output_format: sarif
          output_file: checkov-results.sarif
          
      - name: Upload SARIF file
        uses: github/codeql-action/upload-sarif@v2
        if: success() || failure()
        with:
          sarif_file: checkov-results.sarif
          
      - name: Post Results as PR Comment
        if: github.event_name == 'pull_request' && (success() || failure())
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const fs = require('fs');
            
            try {
              const results = fs.readFileSync('checkov-results.sarif', 'utf8');
              const parsedResults = JSON.parse(results);
              
              const failedRules = parsedResults.runs[0].results || [];
              
              if (failedRules.length > 0) {
                const summary = `### Checkov Security Scan Results\n\n${failedRules.length} security issues found`;
                
                const details = failedRules.slice(0, 10).map(rule => {
                  return `- **${rule.ruleId}**: ${rule.message.text} (${rule.locations[0].physicalLocation.artifactLocation.uri})`;
                }).join('\n');
                
                const moreInfo = failedRules.length > 10 ? `\n\n... and ${failedRules.length - 10} more issues. See workflow run for full details.` : '';
                
                github.rest.issues.createComment({
                  issue_number: context.issue.number,
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  body: `${summary}\n\n${details}${moreInfo}`
                });
              } else {
                github.rest.issues.createComment({
                  issue_number: context.issue.number,
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  body: '### Checkov Security Scan Results\n\nNo security issues found! ✅'
                });
              }
            } catch (error) {
              console.error('Error processing results:', error);
            }
```

## 3. Automatic Dashboard Deployment for New Services

```yaml
name: Deploy Service Dashboard

on:
  push:
    branches: [main]
    paths:
      - 'services/*/metadata.yaml'
      - '.github/workflows/deploy-dashboard.yml'

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed_services: ${{ steps.changed-services.outputs.all_changed_services }}
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 2
      
      - name: Detect Changed Services
        id: changed-services
        run: |
          CHANGED_FILES=$(git diff --name-only HEAD^ HEAD)
          
          SERVICES=""
          for file in $CHANGED_FILES; do
            if [[ $file =~ services/([^/]+)/metadata.yaml ]]; then
              SERVICE_NAME="${BASH_REMATCH[1]}"
              SERVICES="$SERVICES $SERVICE_NAME"
            fi
          done
          
          SERVICES=$(echo $SERVICES | xargs)
          echo "all_changed_services=$SERVICES" >> $GITHUB_OUTPUT
          
          if [ -z "$SERVICES" ]; then
            echo "No services with changed metadata detected."
            exit 0
          else
            echo "Detected changes in services: $SERVICES"
          fi

  deploy-dashboards:
    needs: detect-changes
    if: needs.detect-changes.outputs.changed_services != ''
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJson('["' + join(needs.detect-changes.outputs.changed_services, '","') + '"]') }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
          
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install grafanalib requests pyyaml

      - name: Parse Service Metadata
        id: metadata
        run: |
          python -c "
          import yaml
          import json
          import os
          
          # Load service metadata
          with open('services/${{ matrix.service }}/metadata.yaml', 'r') as f:
              metadata = yaml.safe_load(f)
              
          # Extract dashboard relevant info
          dashboard_info = {
              'service_name': metadata.get('name', '${{ matrix.service }}'),
              'team': metadata.get('team', 'unknown'),
              'metrics_prefix': metadata.get('metrics', {}).get('prefix', '${{ matrix.service }}'),
              'slo': metadata.get('slo', {}),
              'alert_channels': metadata.get('alerts', {}).get('channels', []),
          }
          
          # Output as step outputs
          for key, value in dashboard_info.items():
              if isinstance(value, (dict, list)):
                  print(f'::set-output name={key}::{json.dumps(value)}')
              else:
                  print(f'::set-output name={key}::{value}')
          "
          
      - name: Generate Grafana Dashboard
        run: |
          cat > generate_dashboard.py << 'EOF'
          from grafanalib.core import *
          import json
          import os
          import sys
          
          service_name = os.environ['SERVICE_NAME']
          metrics_prefix = os.environ['METRICS_PREFIX']
          team = os.environ['TEAM']
          
          dashboard = Dashboard(
              title=f"{service_name} Service Dashboard",
              tags=[team, "auto-generated", "service"],
              timezone="browser",
              panels=[
                  Row(panels=[
                      Graph(
                          title="Request Rate",
                          dataSource="Prometheus",
                          targets=[
                              Target(
                                  expr=f'sum(rate({metrics_prefix}_http_requests_total[5m])) by (status_code)',
                                  legendFormat="{{status_code}}",
                              ),
                          ],
                      ),
                      Graph(
                          title="Error Rate",
                          dataSource="Prometheus",
                          targets=[
                              Target(
                                  expr=f'sum(rate({metrics_prefix}_http_requests_total{{status_code=~"5.."|status_code=~"4.."}}[5m])) by (status_code) / sum(rate({metrics_prefix}_http_requests_total[5m]))',
                                  legendFormat="{{status_code}}",
                              ),
                          ],
                      ),
                  ]),
                  Row(panels=[
                      Graph(
                          title="Latency",
                          dataSource="Prometheus",
                          targets=[
                              Target(
                                  expr=f'histogram_quantile(0.95, sum(rate({metrics_prefix}_http_request_duration_seconds_bucket[5m])) by (le))',
                                  legendFormat="95th Percentile",
                              ),
                              Target(
                                  expr=f'histogram_quantile(0.50, sum(rate({metrics_prefix}_http_request_duration_seconds_bucket[5m])) by (le))',
                                  legendFormat="50th Percentile",
                              ),
                          ],
                      ),
                      SingleStat(
                          title="Uptime",
                          dataSource="Prometheus",
                          targets=[
                              Target(
                                  expr=f'avg_over_time(up{{service="{service_name}"}}[24h])',
                              ),
                          ],
                          valueMaps=[
                              ValueMap(
                                  op="=",
                                  value="null",
                                  text="N/A"
                              ),
                          ],
                          sparkline=SparkLine(show=True, full=True),
                          gauge=Gauge(show=True),
                      ),
                  ]),
              ],
          )
          
          dashboard_json = dashboard.to_json_data()
          with open('dashboard.json', 'w') as f:
              json.dump(dashboard_json, f, indent=2)
          EOF
          
          export SERVICE_NAME="${{ steps.metadata.outputs.service_name }}"
          export METRICS_PREFIX="${{ steps.metadata.outputs.metrics_prefix }}"
          export TEAM="${{ steps.metadata.outputs.team }}"
          
          python generate_dashboard.py
          
      - name: Deploy to Grafana
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.GRAFANA_API_KEY }}" \
            -H "Content-Type: application/json" \
            -d @dashboard.json \
            ${{ secrets.GRAFANA_URL }}/api/dashboards/db
          
      - name: Notify Service Team
        uses: peter-evans/create-or-update-comment@v2
        with:
          issue-number: ${{ github.event.pull_request.number }}
          body: |
            :chart_with_upwards_trend: A new dashboard for `${{ steps.metadata.outputs.service_name }}` has been deployed.
            
            [View Dashboard](${{ secrets.GRAFANA_URL }}/d/${{ steps.metadata.outputs.service_name }})
```

## 4. Synthetic Monitoring Setup for New Deployments

```yaml
name: Setup Synthetic Monitoring

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy monitors to'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
      api_endpoint:
        description: 'API endpoint to monitor'
        required: true
        type: string
      frontend_url:
        description: 'Frontend URL to monitor'
        required: true
        type: string
  
  # Automatically run when a new release is published
  release:
    types: [published]

jobs:
  deploy-synthetic-monitors:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Determine endpoints
        id: endpoints
        run: |
          # For workflow_dispatch, use the provided inputs
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            API_ENDPOINT="${{ github.event.inputs.api_endpoint }}"
            FRONTEND_URL="${{ github.event.inputs.frontend_url }}"
            ENVIRONMENT="${{ github.event.inputs.environment }}"
          # For release events, determine based on release tag
          else
            RELEASE_TAG="${{ github.event.release.tag_name }}"
            if [[ "$RELEASE_TAG" == *"-prod" ]]; then
              ENVIRONMENT="production"
            else
              ENVIRONMENT="staging"
            fi
            
            # These would typically come from configuration files or be built dynamically
            if [[ "$ENVIRONMENT" == "production" ]]; then
              API_ENDPOINT="https://api.example.com/health"
              FRONTEND_URL="https://example.com"
            else
              API_ENDPOINT="https://staging-api.example.com/health"
              FRONTEND_URL="https://staging.example.com"
            fi
          fi
          
          echo "api_endpoint=$API_ENDPOINT" >> $GITHUB_OUTPUT
          echo "frontend_url=$FRONTEND_URL" >> $GITHUB_OUTPUT
          echo "environment=$ENVIRONMENT" >> $GITHUB_OUTPUT
      
      # Using Checkly for synthetic monitoring (popular synthetic monitoring tool)
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install Checkly CLI
        run: npm install -g @checkly/cli
        
      - name: Configure Checkly
        run: |
          echo "API_KEY=${{ secrets.CHECKLY_API_KEY }}" > .env
          echo "ENVIRONMENT=${{ steps.endpoints.outputs.environment }}" >> .env
          
      - name: Create API Check
        run: |
          cat > api-check.js << 'EOF'
          const { ApiCheck, AssertionBuilder } = require('@checkly/cli/constructs')
          
          new ApiCheck('api-health-check', {
            name: 'API Health Check - ${{ steps.endpoints.outputs.environment }}',
            activated: true,
            muted: false,
            shouldFail: false,
            request: {
              method: 'GET',
              url: '${{ steps.endpoints.outputs.api_endpoint }}',
              followRedirects: true,
              assertions: [
                {
                  source: 'STATUS_CODE',
                  comparison: 'EQUALS',
                  target: '200'
                },
                {
                  source: 'JSON_BODY',
                  property: '$.status',
                  comparison: 'EQUALS',
                  target: 'ok'
                }
              ],
            },
            alertSettings: {
              escalationType: 'RUN_BASED',
              runBasedEscalation: {
                failedRunThreshold: 1
              },
              reminders: {
                amount: 0,
                interval: 5
              },
              ssl: {
                alertThreshold: 30
              }
            },
            frequency: 5,
            locations: ['eu-west-1', 'us-west-1'],
            tags: ['api', '${{ steps.endpoints.outputs.environment }}', 'health']
          })
          EOF
          
      - name: Create Browser Check
        run: |
          cat > browser-check.js << 'EOF'
          const { BrowserCheck } = require('@checkly/cli/constructs')
          
          new BrowserCheck('homepage-check', {
            name: 'Homepage Availability - ${{ steps.endpoints.outputs.environment }}',
            activated: true,
            muted: false,
            shouldFail: false,
            frequency: 10,
            locations: ['eu-west-1', 'us-west-1'],
            tags: ['frontend', '${{ steps.endpoints.outputs.environment }}', 'critical-path'],
            code: `
              const { chromium } = require('playwright')
              const expect = require('expect')
              
              async function run() {
                const browser = await chromium.launch()
                const page = await browser.newPage()
                
                console.log('Navigating to homepage')
                const response = await page.goto('${{ steps.endpoints.outputs.frontend_url }}')
                expect(response.status()).toBe(200)
                
                console.log('Checking for main elements')
                await page.waitForSelector('header', { timeout: 5000 })
                await page.waitForSelector('footer', { timeout: 5000 })
                
                // Check page title
                const title = await page.title()
                console.log('Page title is: ' + title)
                expect(title).not.toBe('')
                
                // Check for login button
                const loginButton = await page.$('a[href*="login"]')
                expect(loginButton).not.toBeNull()
                
                await browser.close()
              }
              
              run()
            `,
            alertSettings: {
              escalationType: 'RUN_BASED',
              runBasedEscalation: {
                failedRunThreshold: 2
              },
              reminders: {
                amount: 1,
                interval: 10
              }
            }
          })
          EOF
          
      - name: Deploy Checks
        run: |
          npx checkly deploy
          
      - name: Notify Team
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const issueData = {
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Synthetic Monitors Deployed for ${{ steps.endpoints.outputs.environment }}`,
              body: `
              # Synthetic Monitoring Setup Complete
              
              Synthetic monitors have been deployed for the following endpoints:
              
              - API Health: \`${{ steps.endpoints.outputs.api_endpoint }}\`
              - Frontend: \`${{ steps.endpoints.outputs.frontend_url }}\`
              
              Environment: **${{ steps.endpoints.outputs.environment }}**
              
              These monitors will check:
              - API health endpoint returns 200 and status "ok"
              - Frontend homepage loads correctly with critical elements
              
              [View monitors in Checkly dashboard](https://app.checklyhq.com/checks)
              `
            };
            
            github.rest.issues.create(issueData);
```

## 5. SLO/SLI Validation Pipeline

```yaml
name: SLO Validation

on:
  schedule:
    - cron: '0 0 * * *'  # Run daily at midnight
  workflow_dispatch:  # Allow manual trigger
  
jobs:
  validate-slos:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
          
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install requests pandas matplotlib pyyaml prometheus-api-client google-cloud-monitoring

      - name: Authenticate with Google Cloud
        id: auth
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
          
      - name: Get all services with SLOs
        id: get-services
        run: |
          # Get services from service registry or config directory
          python -c "
          import os
          import yaml
          import json
          
          services_with_slos = []
          
          # Scan the services directory for metadata files with SLOs defined
          for root, dirs, files in os.walk('services'):
              for file in files:
                  if file == 'metadata.yaml' or file == 'slo.yaml':
                      file_path = os.path.join(root, file)
                      with open(file_path, 'r') as f:
                          try:
                              data = yaml.safe_load(f)
                              # Check if this service has SLOs defined
                              if 'slo' in data or 'slos' in data:
                                  service_name = os.path.basename(os.path.dirname(file_path))
                                  services_with_slos.append(service_name)
                          except Exception as e:
                              print(f'Error parsing {file_path}: {e}')
          
          # Output as JSON list for matrix strategy
          services_json = json.dumps(services_with_slos)
          print(f'::set-output name=services::{services_json}')
          print(f'Found {len(services_with_slos)} services with SLOs: {services_with_slos}')
          "
          
      - name: Validate SLOs for each service
        run: |
          cat > validate_slos.py << 'EOF'
          import json
          import os
          import sys
          import yaml
          import requests
          import datetime
          import pandas as pd
          import matplotlib.pyplot as plt
          from google.cloud import monitoring_v3
          
          # Parse services list from env var
          services = json.loads(os.environ['SERVICES_LIST'])
          results = []
          
          # Configure clients
          prom_url = os.environ.get('PROMETHEUS_URL', 'http://prometheus:9090')
          
          def get_prometheus_data(query, start_time, end_time):
              """Query Prometheus for SLI data"""
              params = {
                  'query': query,
                  'start': start_time.timestamp(),
                  'end': end_time.timestamp(),
                  'step': '1h',  # 1 hour resolution
              }
              
              response = requests.get(f'{prom_url}/api/v1/query_range', params=params)
              if response.status_code != 200:
                  print(f"Error querying Prometheus: {response.text}")
                  return None
                  
              return response.json()
              
          def calculate_sli(metric_data, slo_spec):
              """Calculate SLI value from metric data"""
              # This would implement the calculation logic based on SLO type
              # Simplified version shown here
              if 'values' not in metric_data['data']['result'][0]:
                  return 0
                  
              values = [float(v[1]) for v in metric_data['data']['result'][0]['values'] if v[1] != 'NaN']
              
              if not values:
                  return 0
                  
              # For availability SLOs, typically mean or percentage
              return sum(values) / len(values)
              
          def generate_report(service, slo_name, target, current, status, window):
              """Generate SLO report"""
              now = datetime.datetime.now()
              report_dir = f"reports/{service}"
              os.makedirs(report_dir, exist_ok=True)
              
              # Create a simple plot
              dates = [now - datetime.timedelta(days=i) for i in range(window, 0, -1)]
              
              # Mock historical data for demonstration
              import random
              historical_values = [current + (random.random() - 0.5) * 0.05 for _ in range(window)]
              
              # Ensure values are clamped between 0 and 1
              historical_values = [max(0, min(v, 1)) for v in historical_values]
              
              plt.figure(figsize=(10, 6))
              plt.plot(dates, historical_values, marker='o')
              plt.axhline(y=target, color='r', linestyle='--', label=f'Target: {target:.2%}')
              plt.title(f'SLO: {slo_name} for {service}')
              plt.ylim(min(min(historical_values) * 0.95, target * 0.95), 1.05)
              plt.ylabel('SLI Value')
              plt.grid(True)
              plt.xticks(rotation=45)
              plt.tight_layout()
              plt.legend()
              
              # Save the plot
              plt.savefig(f"{report_dir}/{slo_name.replace(' ', '_').lower()}.png")
              
              # Generate markdown report
              with open(f"{report_dir}/{slo_name.replace(' ', '_').lower()}.md", 'w') as f:
                  f.write(f"# SLO Report: {slo_name}\n\n")
                  f.write(f"**Service:** {service}\n\n")
                  f.write(f"**Time Period:** Last {window} days\n\n")
                  f.write(f"**Target:** {target:.2%}\n\n")
                  f.write(f"**Current:** {current:.2%}\n\n")
                  f.write(f"**Status:** {'✅ Meeting SLO' if status else '❌ Not Meeting SLO'}\n\n")
                  f.write(f"![SLO Chart]({slo_name.replace(' ', '_').lower()}.png)\n\n")
                  
                  # Include error budget calculation
                  error_budget = target
                  error_budget_used = max(0, target - current)
                  error_budget_remaining = max(0, error_budget - error_budget_used)
                  
                  f.write("## Error Budget\n\n")
                  f.write(f"**Total Error Budget:** {error_budget:.2%}\n\n")
                  f.write(f"**Error Budget Used:** {error_budget_used:.2%} ({error_budget_used/error_budget*100:.1f}% of total)\n\n")
                  f.write(f"**Error Budget Remaining:** {error_budget_remaining:.2%}\n\n")
                  
              return f"{report_dir}/{slo_name.replace(' ', '_').lower()}.md"
              
          # Process each service
          for service in services:
              print(f"Processing SLOs for {service}...")
              
              # Load service SLO definition
              slo_file = f"services/{service}/slo.yaml"
              if not os.path.exists(slo_file):
                  slo_file = f"services/{service}/metadata.yaml"
                  
              with open(slo_file, 'r') as f:
                  service_data = yaml.safe_load(f)
                  
              # Extract SLOs
              slos = service_data.get('slos', service_data.get('slo', {}))
              if not slos:
                  print(f"No SLOs found for {service}")
                  continue
                  
              # Default time window - last 30 days
              end_time = datetime.datetime.now()
              start_time = end_time - datetime.timedelta(days=30)
              
              for slo_name, slo_spec in slos.items():
                  print(f"Validating SLO: {slo_name}")
                  
                  # Get target value
                  target = float(slo_spec.get('target', 0.99))
                  
                  # Get data source and query
                  data_source = slo_spec.get('data_source', 'prometheus')
                  query = slo_spec.get('query', '')
                  
                  if not query:
                      print(f"No query defined for SLO {slo_name}")
                      continue
                      
                  # Get metric data
                  if data_source == 'prometheus':
                      metric_data = get_prometheus_data(query, start_time, end_time)
                  elif data_source == 'stackdriver':
                      # This would use the Google Cloud Monitoring client
                      # Simplified for brevity
                      metric_data = {'data': {'result': [{'values': [(0, 0.98)]}]}}
                  else:
                      print(f"Unsupported data source: {data_source}")
                      continue
                      
                  if not metric_data:
                      print(f"No metric data retrieved for SLO {slo_name}")
                      continue
                      
                  # Calculate current SLI value
                  current_value = calculate_sli(metric_data, slo_spec)
                  
                  # Compare with target
                  status = current_value >= target
                  
                  # Generate report
                  report_path = generate_report(service, slo_name, target, current_value, status, 30)
                  
                  # Store result for summary
                  results.append({
                      'service': service,
                      'slo_name': slo_name,
                      'target': target,
                      'current': current_value,
                      'status': status,
                      'report': report_path
                  })
                  
          # Generate summary report
          summary_file = "reports/summary.md"
          os.makedirs("reports", exist_ok=True)
          
          with open(summary_file, 'w') as f:
              f.write("# SLO Validation Summary\n\n")
              f.write(f"Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
              
              # Count metrics
              total_slos = len(results)
              passing_slos = sum(1 for r in results if r['status'])
              
              f.write(f"**SLOs Meeting Target:** {passing_slos}/{total_slos} ({passing_slos/total_slos*100:.1f}%)\n\n")
              
              # Table of results
              f.write("| Service | SLO | Target | Current | Status |\n")
              f.write("|---------|-----|--------|---------|--------|\n")
              
              for result in sorted(results, key=lambda x: (x['service'], x['slo_name'])):
                  status_icon = "✅" if result['status'] else "❌"
                  f.write(f"| {result['service']} | {result['slo_name']} | {result['target']:.2%} | {result['current']:.2%} | {status_icon} |\n")
                  
          print(f"Generated summary report: {summary_file}")
          
          # Output results for GitHub actions
          with open("slo_results.json", "w") as f:
              json.dump({
                  "total": total_slos,
                  "passing": passing_slos,
                  "failing": total_slos - passing_slos,
                  "results": results
              }, f)
          EOF
          
          export SERVICES_