#!/bin/bash
"""
Run Yangtze River RNA Virus Pipeline locally with Snakemake
"""

# Configuration
CORES=8  # Adjust based on your system
CONFIG="config/config.yaml"

# Create necessary directories
mkdir -p logs results

echo "Starting Yangtze River RNA Virus Pipeline (Local Execution)..."
echo "Config: $CONFIG"
echo "Cores: $CORES"

# Dry run first to check workflow
echo "Performing dry run..."
snakemake --configfile $CONFIG \
          --cores $CORES \
          --dry-run \
          --printshellcmds

if [ $? -ne 0 ]; then
    echo "Dry run failed! Please check your configuration."
    exit 1
fi

echo "Dry run successful. Starting actual run..."

# Run locally with conda environments
snakemake --configfile $CONFIG \
          --cores $CORES \
          --use-conda \
          --conda-frontend conda \
          --printshellcmds \
          --reason \
          --stats snakemake_stats.json

echo "Pipeline completed. Check logs for details."