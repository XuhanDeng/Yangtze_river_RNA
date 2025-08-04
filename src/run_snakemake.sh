#!/bin/bash
"""
Run Yangtze River RNA Virus Pipeline with Snakemake
"""

# Configuration
SNAKEFILE="Snakefile"
CONFIG="config/config.yaml"
CLUSTER_CONFIG="cluster_config.yaml"
CORES=50  # Maximum number of cores to use
JOBS=50   # Maximum number of jobs to submit

# Create necessary directories
mkdir -p logs/slurm results

# Activate snakemake environment (adjust path as needed)
# source /home/xddeng/miniconda3/bin/activate
# conda activate snakemake

echo "Starting Yangtze River RNA Virus Pipeline..."
echo "Snakefile: $SNAKEFILE"
echo "Config: $CONFIG"
echo "Max cores: $CORES"
echo "Max jobs: $JOBS"

# Dry run first to check workflow
echo "Performing dry run..."
snakemake --snakefile $SNAKEFILE \
          --configfile $CONFIG \
          --cores $CORES \
          --dry-run \
          --printshellcmds

if [ $? -ne 0 ]; then
    echo "Dry run failed! Please check your configuration."
    exit 1
fi

echo "Dry run successful. Starting actual run..."

# Run with SLURM cluster execution
snakemake --snakefile $SNAKEFILE \
          --configfile $CONFIG \
          --cluster-config $CLUSTER_CONFIG \
          --cluster "sbatch --account={cluster.account} \
                           --partition={cluster.partition} \
                           --time={cluster.time} \
                           --mem={cluster.mem} \
                           --cpus-per-task={cluster.cpus} \
                           --output={cluster.output} \
                           --error={cluster.error} \
                           --job-name={rule}" \
          --jobs $JOBS \
          --use-conda \
          --conda-frontend conda \
          --printshellcmds \
          --reason \
          --stats snakemake_stats.json

echo "Pipeline completed. Check logs for details."