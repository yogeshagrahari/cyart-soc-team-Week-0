
# Step 1: Initialize git (if not already done)
git init
git branch -M main

# Step 2: Set your GitHub details (EDIT THESE)
GIT_USERNAME="YOUR_GITHUB_USERNAME"
GIT_EMAIL="YOUR_EMAIL@example.com"
REPO_NAME="cyart-soc-team"

git config user.name "$GIT_USERNAME"
git config user.email "$GIT_EMAIL"

# Step 3: Create .gitignore
cat > .gitignore << 'EOF'
# Ignore sensitive files
*.key
*.pem
*.pfx
secrets.txt
api_keys.txt
.env

# OS files
.DS_Store
Thumbs.db

# Editor temp files
*.swp
*~
EOF

# Step 4: Stage all files
git add .

# Step 5: Initial commit
git commit -m "feat: Add Week 2 — Alert Prioritization, Incident Classification & Basic IR

Contents:
- 01 Alert Priority Levels (CVSS, scoring framework)
- 02 Incident Classification (MITRE ATT&CK, VERIS)
- 03 Basic Incident Response (NIST 800-61 lifecycle)
- 04 Alert Management Practice (Wazuh, TheHive, Google Sheets)
- 05 Response Documentation (IR templates, checklists)
- 06 Alert Triage Practice (VirusTotal, AlienVault OTX)
- 07 Evidence Preservation (Velociraptor, FTK Imager)
- 08 Capstone Project (Metasploit + Wazuh + CrowdSec)"

echo ""
echo "✅ Local git repository initialized and committed!"
echo ""
echo "Next steps:"
echo "  1. Create repo on GitHub: https://github.com/new"
echo "     Name: cyart-soc-team"
echo "     Visibility: Private (recommended for SOC docs)"
echo ""
echo "  2. Add remote and push:"
echo "     git remote add origin https://github.com/$GIT_USERNAME/$REPO_NAME.git"
echo "     git push -u origin main"

