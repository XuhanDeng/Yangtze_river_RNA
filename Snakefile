#!/usr/bin/env python3
"""
Yangtze River RNA Virus Pipeline - Snakemake Workflow
RNA virus bioinformatics pipeline for processing RNA NGS sequencing data
"""

import pandas as pd
from pathlib import Path

# Configuration
configfile: "config/config.yaml"

# Load sample information
samples_df = pd.read_csv(config["samples_file"], header=None, names=["sample"])
SAMPLES = samples_df["sample"].tolist()

# Define output directories
FASTP_DIR = "results/1_fastp"
RIBODETECTOR_DIR = "results/2_ribodetector" 
SPADES_DIR = "results/3_spades_result"
ESVIRITU_DIR = "results/4_esviritu"
VIRBOT_DIR = "results/5_virbot"
LOGS_DIR = "logs"

# Final output rule
rule all:
    input:
        # Quality control outputs
        expand(f"{FASTP_DIR}/{{sample}}/{{sample}}_1P.fq.gz", sample=SAMPLES),
        expand(f"{FASTP_DIR}/{{sample}}/{{sample}}_2P.fq.gz", sample=SAMPLES),
        # rRNA removal outputs
        expand(f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.1.fq.gz", sample=SAMPLES),
        expand(f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.2.fq.gz", sample=SAMPLES),
        # Assembly outputs
        expand(f"{SPADES_DIR}/{{sample}}/scaffolds.fasta", sample=SAMPLES),
        expand(f"{SPADES_DIR}/reformat/{{sample}}_reformat.fasta", sample=SAMPLES),
        # Viral identification outputs
        expand(f"{ESVIRITU_DIR}/{{sample}}/{{sample}}.detected_virus.info.tsv", sample=SAMPLES),
        expand(f"{VIRBOT_DIR}/{{sample}}", sample=SAMPLES),
        # Final merged results
        "results/esviritu_VIR_table.xlsx"

# Rule 1: Quality control and adapter removal with fastp
rule fastp_qc:
    input:
        r1 = lambda wildcards: f"{config['raw_data_dir']}/{wildcards.sample}/{wildcards.sample}.R1.fq.gz",
        r2 = lambda wildcards: f"{config['raw_data_dir']}/{wildcards.sample}/{wildcards.sample}.R2.fq.gz"
    output:
        r1_paired = f"{FASTP_DIR}/{{sample}}/{{sample}}_1P.fq.gz",
        r2_paired = f"{FASTP_DIR}/{{sample}}/{{sample}}_2P.fq.gz",
        r1_unpaired = f"{FASTP_DIR}/{{sample}}/{{sample}}_U1.fq.gz",
        r2_unpaired = f"{FASTP_DIR}/{{sample}}/{{sample}}_U2.fq.gz",
        html = f"{FASTP_DIR}/{{sample}}/{{sample}}.fastp.html",
        json = f"{FASTP_DIR}/{{sample}}/{{sample}}.fastp.json"
    conda:
        "envs/fastp.yaml"
    threads: config["fastp"]["threads"]
    resources:
        mem_mb = config["fastp"]["memory"] * 1024,
        runtime = config["fastp"]["runtime"]
    log:
        f"{LOGS_DIR}/fastp/{{sample}}.log"
    shell:
        """
        mkdir -p {FASTP_DIR}/{wildcards.sample}
        fastp --thread {threads} \
              --in1 {input.r1} --in2 {input.r2} \
              --out1 {output.r1_paired} --out2 {output.r2_paired} \
              --unpaired1 {output.r1_unpaired} --unpaired2 {output.r2_unpaired} \
              -h {output.html} -j {output.json} \
              --trim_poly_g --trim_poly_x \
              --qualified_quality_phred 20 \
              --length_required 20 \
              --dont_overwrite 2> {log}
        """

# Rule 2: Remove rRNA sequences with ribodetector
rule ribodetector_rrna_removal:
    input:
        r1 = f"{FASTP_DIR}/{{sample}}/{{sample}}_1P.fq.gz",
        r2 = f"{FASTP_DIR}/{{sample}}/{{sample}}_2P.fq.gz"
    output:
        r1_nonrrna = f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.1.fq.gz",
        r2_nonrrna = f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.2.fq.gz"
    conda:
        "envs/ribodetector.yaml"
    threads: config["ribodetector"]["threads"]
    resources:
        mem_mb = config["ribodetector"]["memory"] * 1024,
        runtime = config["ribodetector"]["runtime"]
    log:
        f"{LOGS_DIR}/ribodetector/{{sample}}.log"
    shell:
        """
        mkdir -p {RIBODETECTOR_DIR}/{wildcards.sample}
        ribodetector_cpu -t {threads} \
                         -l 50 \
                         -i {input.r1} {input.r2} \
                         -e rrna \
                         --chunk_size 2500 \
                         -o {output.r1_nonrrna} {output.r2_nonrrna} 2> {log}
        """

# Rule 3: Viral sequence assembly with metaspades
rule spades_assembly:
    input:
        r1 = f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.1.fq.gz",
        r2 = f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.2.fq.gz"
    output:
        scaffolds = f"{SPADES_DIR}/{{sample}}/scaffolds.fasta",
        contigs = f"{SPADES_DIR}/{{sample}}/contigs.fasta"
    conda:
        "envs/spades.yaml"
    threads: config["spades"]["threads"]
    resources:
        mem_mb = config["spades"]["memory"] * 1024,
        runtime = config["spades"]["runtime"]
    log:
        f"{LOGS_DIR}/spades/{{sample}}.log"
    shell:
        """
        mkdir -p {SPADES_DIR}/{wildcards.sample}
        spades.py --meta \
                  -o {SPADES_DIR}/{wildcards.sample} \
                  -1 {input.r1} -2 {input.r2} \
                  -t {threads} -m {resources.mem_mb} \
                  -k 21,33,55,77,101,121 \
                  --only-assembler 2> {log}
        """

# Rule 4: Reformat assembly sequences
rule reformat_assemblies:
    input:
        scaffolds = f"{SPADES_DIR}/{{sample}}/scaffolds.fasta"
    output:
        reformatted = f"{SPADES_DIR}/reformat/{{sample}}_reformat.fasta"
    conda:
        "envs/seqkit.yaml"
    log:
        f"{LOGS_DIR}/reformat/{{sample}}.log"
    shell:
        """
        mkdir -p {SPADES_DIR}/reformat
        seqkit replace -p "^(.+)$" -r "{wildcards.sample}_scaffold_{{nr}}" \
               --nr-width 10 \
               -o {output.reformatted} \
               {input.scaffolds} 2> {log}
        """

# Rule 5: Read-based viral identification with EsViritu
rule esviritu_identification:
    input:
        r1 = f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.1.fq.gz",
        r2 = f"{RIBODETECTOR_DIR}/{{sample}}/{{sample}}_nonrrna.2.fq.gz"
    output:
        results = f"{ESVIRITU_DIR}/{{sample}}/{{sample}}.detected_virus.info.tsv"
    conda:
        "envs/esviritu.yaml"
    threads: config["esviritu"]["threads"]
    resources:
        mem_mb = config["esviritu"]["memory"] * 1024,
        runtime = config["esviritu"]["runtime"]
    log:
        f"{LOGS_DIR}/esviritu/{{sample}}.log"
    shell:
        """
        mkdir -p {ESVIRITU_DIR}/{wildcards.sample}
        EsViritu -r {input.r1} {input.r2} \
                 -s {wildcards.sample} \
                 -t {threads} \
                 -o {ESVIRITU_DIR}/{wildcards.sample} \
                 -p paired 2> {log}
        """

# Rule 6: Assembly-based viral identification with virbot
rule virbot_identification:
    input:
        assembly = f"{SPADES_DIR}/reformat/{{sample}}_reformat.fasta"
    output:
        results = directory(f"{VIRBOT_DIR}/{{sample}}")
    conda:
        "envs/virbot.yaml"
    threads: config["virbot"]["threads"]
    resources:
        mem_mb = config["virbot"]["memory"] * 1024,
        runtime = config["virbot"]["runtime"]
    log:
        f"{LOGS_DIR}/virbot/{{sample}}.log"
    shell:
        """
        mkdir -p {VIRBOT_DIR}
        virbot --input {input.assembly} \
               --output {output.results} \
               --thread {threads} 2> {log}
        """

# Rule 7: Merge EsViritu results
rule merge_esviritu_results:
    input:
        results = expand(f"{ESVIRITU_DIR}/{{sample}}/{{sample}}.detected_virus.info.tsv", sample=SAMPLES)
    output:
        merged = "results/esviritu_VIR_table.xlsx"
    conda:
        "envs/python.yaml"
    log:
        f"{LOGS_DIR}/merge_results.log"
    script:
        "scripts/merge_esviritu_results.py"