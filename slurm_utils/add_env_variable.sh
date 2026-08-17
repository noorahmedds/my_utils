# Add a custom environment variable to the singularity container

cat > /.singularity.d/env/99-custom.sh <<'EOF'
#!/bin/sh
export TORCH_EXTENSIONS_DIR=/opt/torch_extensions
# export ANY_OTHER_VAR=value
EOF