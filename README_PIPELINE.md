# Yangtze River RNA Virus Pipeline - Snakemake Implementation

## Overview

This Snakemake workflow implements a comprehensive RNA virus bioinformatics pipeline converted from the original SLURM-based scripts. The pipeline processes RNA NGS sequencing data to identify and analyze viral sequences.

## Pipeline Steps

1. **Quality Control** - FastP for adapter removal and quality filtering
2. **rRNA Removal** - RiboDetector to remove ribosomal RNA sequences  
3. **Assembly** - MetaSPAdes for viral genome assembly
4. **Sequence Reformatting** - SeqKit for sequence header standardization
5. **Viral Identification** - Dual approach:
   - **Read-based**: EsViritu for direct read classification
   - **Assembly-based**: Virbot for assembled sequence analysis
6. **Results Merging** - Python script to combine and format results

## Quick Start

### 1. Setup Environment

```bash
# Install Snakemake (if not already installed)
conda install -c bioconda snakemake

# Clone/navigate to pipeline directory
cd /path/to/yangtze_river_rna
```

### 2. Configure Pipeline

Edit the configuration files:

- `config/config.yaml` - Main pipeline parameters
- `config/sample_list.txt` - Add your sample names (one per line)
- `src/cluster_config.yaml` - SLURM cluster settings

### 3. Prepare Data Structure

Organize your raw data as:
```
data/0_rawdata/
├── SAMPLE1/
│   ├── SAMPLE1.R1.fq.gz
│   └── SAMPLE1.R2.fq.gz
├── SAMPLE2/
│   ├── SAMPLE2.R1.fq.gz
│   └── SAMPLE2.R2.fq.gz
└── ...
```

### 4. Run Pipeline

#### Local execution:
```bash
snakemake --snakefile src/Snakefile --configfile config/config.yaml --cores 8 --use-conda
```

#### SLURM cluster execution:
```bash
./src/run_snakemake.sh
```

#### Dry run (recommended first):
```bash
snakemake --snakefile src/Snakefile --configfile config/config.yaml --dry-run
```

## Output Structure

```
results/
├── 1_fastp/                    # Quality control outputs
├── 2_ribodetector/             # rRNA-depleted reads
├── 3_spades_result/            # Assembly results
│   ├── SAMPLE/scaffolds.fasta
│   └── reformat/               # Reformatted sequences
├── 4_esviritu/                 # Read-based viral identification
├── 5_virbot/                   # Assembly-based viral identification
└── esviritu_VIR_table.xlsx     # Merged results table
```

## Key Features

### Converted from SLURM to Snakemake
- **Parallelization**: Automatic job parallelization and dependency management
- **Resource Management**: Configurable memory, CPU, and time requirements
- **Environment Management**: Conda environments for each tool
- **Error Handling**: Built-in retry and error reporting
- **Scalability**: Easy scaling from local to HPC execution

### Tool Integration
- **FastP**: Quality control with adapter trimming
- **RiboDetector**: Efficient rRNA removal
- **MetaSPAdes**: Viral genome assembly
- **SeqKit**: Sequence manipulation and formatting  
- **EsViritu**: Read-based viral classification
- **Virbot**: Assembly-based viral identification

### Data Management
- **Automatic directory creation**
- **Consistent file naming**
- **Comprehensive logging**
- **Result aggregation**

## Configuration Details

### Main Configuration (`config/config.yaml`)

Key parameters you may need to adjust:
- `samples_file`: Path to sample list
- `raw_data_dir`: Path to raw sequencing data
- Tool-specific parameters (threads, memory, runtime)

### Sample List (`config/sample_list.txt`)

Add your sample names, one per line:
```
VIR_G_SX_i_01
VIR_G_SX_i_02
VIR_G_SX_i_03
```

### Cluster Configuration (`src/cluster_config.yaml`)

SLURM-specific settings for each rule:
- Account and partition settings
- Memory and CPU requirements
- Time limits

## Monitoring and Troubleshooting

### Check workflow status:
```bash
snakemake --snakefile src/Snakemake --summary
```

### Generate workflow report:
```bash
snakemake --snakefile src/Snakemake --report report.html
```

### View logs:
- Individual rule logs: `logs/RULE_NAME/SAMPLE.log`
- SLURM logs: `logs/slurm/`
- Pipeline statistics: `snakemake_stats.json`

## Differences from Original SLURM Implementation

1. **Job Management**: Snakemake handles job dependencies automatically
2. **Environment Management**: Conda environments replace manual activation
3. **Resource Allocation**: Dynamic resource assignment based on configuration
4. **Error Handling**: Built-in retry mechanisms and better error reporting
5. **Scalability**: Easy transition between local and cluster execution
6. **Reproducibility**: Version-controlled environments and parameters

## Requirements

### Software Dependencies
- Snakemake ≥ 7.0
- Conda/Mamba
- Tools (installed automatically via conda environments):
  - FastP
  - RiboDetector  
  - SPAdes
  - SeqKit
  - EsViritu
  - Virbot

### System Requirements
- Minimum 8GB RAM (recommended: 256GB+ for large datasets)
- Multiple CPU cores (16+ recommended)
- Sufficient storage space for intermediate files

## Citation

If you use this pipeline, please cite the original tools:
- **FastP**: Chen et al., 2018
- **RiboDetector**: Deng et al., 2022
- **SPAdes**: Bankevich et al., 2012
- **EsViritu**: Viral classification tool
- **Virbot**: Viral identification tool
- **Snakemake**: Köster & Rahmann, 2012