#!/bin/bash
# Repository setup commands

# Create repository structure
mkdir -p pi5/{cloud-init,docker,ansible,scripts,configs/{cobbler,dhcp,dns,monitoring},docs,.github/workflows}

# Initialize git and set up remote
cd pi5
git init
git remote add origin git@github.com:paddione/pi5.git

# Create initial README
cat > README.md << 'EOF'
[Previous README content]
EOF

# Create initial cloud-init
mkdir -p cloud-init/base
cat > cloud-init/base/cloud-init.yaml << 'EOF'
[Previous cloud-init content with updated passwords]
EOF

# Create docker-compose files
mkdir -p docker/monitoring
cat > docker/monitoring/docker-compose.yml << 'EOF'
[Previous docker-compose content with updated passwords]
EOF

# Create basic test script
mkdir -p scripts/tests
cat > scripts/tests/quick-test.sh << 'EOF'
[Previous test script content]
EOF

# Create GitHub workflow
mkdir -p .github/workflows
cat > .github/workflows/backup-and-test.yml << 'EOF'
[Previous workflow content]
EOF

# Make scripts executable
chmod +x scripts/tests/quick-test.sh

# Initial commit
git add .
git commit -m "Initial commit: Basic infrastructure setup"
git push -u origin main
