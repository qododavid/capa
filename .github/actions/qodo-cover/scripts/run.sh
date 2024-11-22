#!/bin/bash
set -e

BINARY_PATH="/tmp/bin/cover-agent-pro"
REPORT_DIR="/tmp"
REPORT_PATH="$REPORT_DIR/report.txt"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --pr-number) PR_NUMBER="$2"; shift ;;
        --pr-ref) PR_REF="$2"; shift ;;
        --greeting) GREETING="$2"; shift ;;
        --project-language) PROJECT_LANGUAGE="$2"; shift ;;
        --project-root) PROJECT_ROOT="$2"; shift ;;
        --code-coverage-path) CODE_COVERAGE_PATH="$2"; shift ;;
        --test-command) TEST_COMMAND="$2"; shift ;;
        --model) MODEL="$2"; shift ;;
        --action-path) ACTION_PATH="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Install dependencies
if ! command -v wget >/dev/null; then
    echo "Installing dependencies..."
    sudo apt-get update >/dev/null
    sudo apt-get install -y wget >/dev/null
fi

if ! pip show jedi-language-server >/dev/null; then
    pip install jedi-language-server jinja2-cli >/dev/null
fi

# Set up git
git config --global user.email "cover-bot@qodo.ai"
git config --global user.name "Qodo Cover"

# Download cover-agent if not cached
if [ ! -f "$BINARY_PATH" ]; then
    echo "Downloading cover-agent..."
    mkdir -p /tmp/bin
    wget -P /tmp/bin https://github.com/qododavid/capa/releases/download/v1/cover-agent-pro >/dev/null
    chmod +x "$BINARY_PATH"
fi

# Checkout PR and get diff
git fetch origin
git checkout "$PR_REF"
gh pr diff "$PR_NUMBER" > /tmp/pr_diff.txt

# Run cover-agent
"$BINARY_PATH" \
  --project-language "$PROJECT_LANGUAGE" \
  --project-root "$GITHUB_WORKSPACE/$PROJECT_ROOT" \
  --code-coverage-report-path "$GITHUB_WORKSPACE/$CODE_COVERAGE_PATH" \
  --test-command "$TEST_COMMAND" \
  --model "$MODEL" \
  --report-dir "$REPORT_DIR"

# Handle changes if any
if [ -n "$(git status --porcelain)" ]; then
    TIMESTAMP=$(date +%s)
    BRANCH_NAME="qodo-cover-${PR_NUMBER}-${TIMESTAMP}"

    if [ ! -f "$REPORT_PATH" ]; then
        echo "Error: Report file not found at $REPORT_PATH"
        exit 1
    fi

    REPORT_TEXT=$(cat "$REPORT_PATH")
    PR_BODY=$(jinja2 "$ACTION_PATH/templates/pr_body_template.j2" -D pr_number="$PR_NUMBER" -D report="$REPORT_TEXT")
    
    git add .
    git commit -m "add tests"
    git checkout -b "$BRANCH_NAME"
    git push origin "$BRANCH_NAME"
    
    gh pr create \
        --base "$PR_REF" \
        --head "$BRANCH_NAME" \
        --title "Qodo Cover Update: ${TIMESTAMP}" \
        --body "$PR_BODY"
fi