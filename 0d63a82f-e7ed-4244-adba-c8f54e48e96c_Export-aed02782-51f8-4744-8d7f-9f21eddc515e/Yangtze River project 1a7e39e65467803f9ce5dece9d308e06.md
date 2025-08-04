# Yangtze River project

SLURM

```bash
# view setting of HPC
scontrol show config | grep Priority
```

check_node info

```bash

#mem
for i in {1..10}; do   node="mem$(printf "%03d" $i)";   echo $node;   scontrol show node $node | awk '/NodeName|RealMemory|CPUAlloc/';    done

#compute 
for i in {1..308}; do   node="cmp$(printf "%03d" $i)";      scontrol show node $node | awk '/NodeName|RealMemory|CPUAlloc/';    done

for i in {1..308}; do   node="cmp$(printf "%03d" $i)";      scontrol show node $node | awk '/NodeName|RealMemory|CPUAlloc/' | grep "CPUAlloc";    done

```

# RNA process

## Slurm

### Head file

```bash
#!/bin/bash
#SBATCH --job-name=ribodetector         # Job name
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/2_ribodetector/log_%A_%a.log  # Standard output log
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/2_ribodetector/error_index_%A_%a.log    # Error log
#SBATCH --mem=64G                   # Request 64GB memory
#SBATCH --ntasks=1                   # Number of tasks per job
#SBATCH --cpus-per-task=16           # Number of CPU cores per task
#SBATCH --time=120:00:00             # Maximum job runtime
#SBATCH --partition=compute,memory   # Partition name
#SBATCH --account=research-ceg-wm    # Specify account
#SBATCH --array=0-49                 # Job array, 50 tasks in total (0 to 49)
#SBATCH --threads-per-core=1

# Define log directory
LOG_DIR="/scratch/xddeng/yangtze/RNA/log/2_ribodetector"
mkdir -p $LOG_DIR

# Record job start time
echo "Job started at: $(date)" > ${LOG_DIR}/index_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log

# Activate conda environment
source /home/xddeng/miniconda3/bin/activate
conda activate ribodetector

# Define working directory
workplace=/scratch/xddeng/yangtze/RNA

# Read file list
mapfile -t files < $workplace/sample_list.txt

# Select the file for the current task
file=${files[$SLURM_ARRAY_TASK_ID]}

echo "Processing $file on node $(hostname)"
```

### monitor script

```bash
#!/bin/bash
#SBATCH --job-name=memory_monitor         # Job name
#SBATCH --mem=4G                   # Request 4GB memory
#SBATCH --ntasks=1                   # Number of tasks per job
#SBATCH --cpus-per-task=1          # Number of CPU cores per task
#SBATCH --time=48:00:00             # Maximum job runtime
#SBATCH --partition=compute,memory          # Partition name
#SBATCH --account=research-ceg-wm    # Specify account

# Define log directory
echo start > /scratch/xddeng/yangtze/RNA/log/memory_monitor.txt
while true;
    do clear
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >>/scratch/xddeng/yangtze/RNA/log/memory_monitor.txt
        for file in {0..49}
        do
        echo $file >> /scratch/xddeng/yangtze/RNA/log/memory_monitor.txt
        seff 5697279_$file | grep Memory >> /scratch/xddeng/yangtze/RNA/log/memory_monitor.txt
        

    done
    sleep 600
done
```

## RNA adaptor remove

RNA_fastp.sh

[RNA_fastp.sh](Yangtze%20River%20project%201a7e39e65467803f9ce5dece9d308e06/RNA_fastp.sh)

```bash
#!/bin/bash
#SBATCH --job-name=RNA_fastp         # Job name
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/1_fastp/output_%A_%a.log  # Standard output and error log
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/1_fastp/error_%A_%a.log    # Error log
#SBATCH --mem=128G  # Request 128GB memory
#SBATCH --ntasks=1                # Number of tasks per job
#SBATCH --cpus-per-task=24         # Number of CPU cores per task
#SBATCH --time=6:10:00           # Maximum job runtime
#SBATCH --partition=compute      # Partition name
#SBATCH --account=research-ceg-wm    # Specify account
#SBATCH --array=0-16              # Job array, 17 tasks in total (ceil(50/3))

source /home/xddeng/miniconda3/bin/activate
conda activate fastp
workplace=/scratch/xddeng/yangtze/RNA

mkdir -p $workplace/log/1_fastp

# Read file list
mapfile -t files < $workplace/sample_list.txt

# Group every 3 files together
group_size=3

# Calculate the start index for the current group
start_index=$((SLURM_ARRAY_TASK_ID * group_size))

# Get the files in the current group
group_files=("${files[@]:start_index:group_size}")

# Process the files in the current group
for file in "${group_files[@]}"; do
    echo "Processing $file on node $(hostname)"
    # Add file processing commands here
    pwd
    cd $workplace/RNA
    pwd
    bsnm=$file
    mkdir -p 1_fastp/$bsnm
    echo $bsnm "is processing"
    time fastp --thread 48 --in1 0_rawdata/${bsnm}/${bsnm}.R1.fq.gz --in2 0_rawdata/${bsnm}/${bsnm}.R2.fq.gz --out1 1_fastp/$bsnm/${bsnm}_1P.fq.gz --out2 1_fastp/$bsnm/${bsnm}_2P.fq.gz --unpaired1 1_fastp/$bsnm/${bsnm}_U1.fq.gz --unpaired2 1_fastp/$bsnm/${bsnm}_U2.fq.gz -h 1_fastp/$bsnm/${bsnm}.fastp.html -j 1_fastp/$bsnm/${bsnm}.fastp.json --trim_poly_g --trim_poly_x --qualified_quality_phred 20 --length_required 20 --dont_overwrite
done

conda deactivate
```

## Remove rrna sequence

[ribodetecter.sh](http://ribodetecter.sh/)

[ribodetecter.sh](Yangtze%20River%20project%201a7e39e65467803f9ce5dece9d308e06/ribodetecter.sh)

```bash
#!/bin/bash
#SBATCH --job-name=ribodetector         # Job name
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/2_ribodetector/log_%A_%a.log  # Standard output log
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/2_ribodetector/error_index_%A_%a.log    # Error log
#SBATCH --mem=64G                   # Request 64GB memory
#SBATCH --ntasks=1                   # Number of tasks per job
#SBATCH --cpus-per-task=16           # Number of CPU cores per task
#SBATCH --time=120:00:00             # Maximum job runtime
#SBATCH --partition=compute,memory   # Partition name
#SBATCH --account=research-ceg-wm    # Specify account
#SBATCH --array=0-49                 # Job array, 50 tasks (0 to 49)
#SBATCH --threads-per-core=1

# Define log directory
LOG_DIR="/scratch/xddeng/yangtze/RNA/log/2_ribodetector"
mkdir -p $LOG_DIR

# Record job start time
echo "Job started at: $(date)" > ${LOG_DIR}/index_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log

# Activate conda environment
source /home/xddeng/miniconda3/bin/activate
conda activate ribodetector

# Define working directory
workplace=/scratch/xddeng/yangtze/RNA

# Read file list
mapfile -t files < $workplace/sample_list.txt

# Select the file for the current task
file=${files[$SLURM_ARRAY_TASK_ID]}

echo "Processing $file on node $(hostname)"

# Create output directory
mkdir -p $workplace/2_ribodetector/${file}

# Run ribodetector
ribodetector_cpu -t 16 \
  -l 50 \
  -i $workplace/1_fastp/${file}/${file}_1P.fq.gz $workplace/1_fastp/${file}/${file}_2P.fq.gz \
  -e rrna \
  --chunk_size 2500 \
  -o $workplace/2_ribodetector/${file}/${file}_nonrrna.1.fq.gz $workplace/2_ribodetector/${file}/${file}_nonrrna.2.fq.gz

# Deactivate conda environment
conda deactivate

# Record job end time
echo "Job finished at: $(date)" >> ${LOG_DIR}/index_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log
```

## Route1_Assembly based analyze

### viral sequence assembly

metaspades

```bash
#!/bin/bash
#SBATCH --job-name=spades         # Job name
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/3_spades/log_%A_%a.log  # Standard output log
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/3_spades/error_index_%A_%a.log    # Error log
#SBATCH --mem=256G                   # Request 256GB memory
#SBATCH --ntasks=1                   # Number of tasks per job
#SBATCH --cpus-per-task=16           # Number of CPU cores per task
#SBATCH --time=120:00:00             # Maximum job runtime
#SBATCH --partition=compute,memory   # Partition name
#SBATCH --account=research-ceg-wm    # Specify account
#SBATCH --array=0-49                 # Job array, 50 tasks (0 to 49)
#SBATCH --threads-per-core=1

# Define log directory
LOG_DIR="/scratch/xddeng/yangtze/RNA/log/2_ribodetector"
mkdir -p $LOG_DIR

# Record job start time
echo "Job started at: $(date)" > ${LOG_DIR}/index_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log

# Activate conda environment
source /home/xddeng/miniconda3/bin/activate
conda activate spades

# Define working directory
workplace=/scratch/xddeng/yangtze/RNA

# Read file list
mapfile -t files < $workplace/sample_list.txt

# Select the file for the current task
file=${files[$SLURM_ARRAY_TASK_ID]}

echo "Processing $file on node $(hostname)"

mkdir -p 3_spades_result/${file}
cd $workplace
spades.py --meta -o 3_spades_result/${file} -1 $workplace/2_ribodetector/${file}/${file}_nonrrna.1.fq.gz -2 $workplace/2_ribodetector/${file}/${file}_nonrrna.2.fq.gz -t 16 -m 256 -k 21,33,55,77,101,121 --only-assembler >> $workplace/log/3_spades/${file}_spades.txt 2>&1
```

### extract and rename

```bash

workplace=/scratch/xddeng/yangtze/RNA
mapfile -t files < $workplace/sample_list.txt
mkdir -p 3_spades_result/all_merge
cd $workplace
for file in "${files[@]}"; do
    echo "$file"
    cp $workplace/3_spades_result/$file/scaffolds.fasta 3_spades_result/all_merge/${file}.scaffolds.fasta
    
done

# 确保输出目录存在
mkdir -p 3_spades_result/reformat

# 遍历 files 数组
for file in "${files[@]}"; do
    if [[ ! -f "3_spades_result/all_merge/${file}.scaffolds.fasta" ]]; then
        echo "File not found: 3_spades_result/all_merge/${file}.scaffolds.fasta"
        continue
    fi

    seqkit replace -p "^(.+)$" -r "${file}_scaffold_{nr}" --nr-width 10 \
    -o "3_spades_result/reformat/${file}_reformat.fasta" \
    "3_spades_result/all_merge/${file}.scaffolds.fasta"

    # 检查 seqkit 是否成功
    if [[ $? -eq 0 ]]; then
        echo "Processed: ${file}.scaffolds.fasta -> ${file}_reformat.fasta"
    else
        echo "Failed to process: ${file}.scaffolds.fasta"
    fi
done

```

```bash
seqkit seq VIR_G_SX_i_12.scaffolds.fasta -i --id-regexp "^(.+)$" --id-ncbi |  seqkit replace -p "^(.+)$" -r "${file}_scaffold_{nr}" --nr-width 10 -o test.fasta

cat VIR_G_SX_i_12.scaffolds.fasta | seqkit replace -p "^(.+)$" -r "${file}_scaffold_{nr}" --nr-width 10 -o test2.fasta

```

### Identification - easy VIRbot

```bash
#!/bin/bash
#SBATCH --job-name=esviritu         # Job name
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/5_virbot/log_%A_%a.log  # Standard output log
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/5_virbot/error_index_%A_%a.log    # Error log
#SBATCH --mem=32G                   # Request 32GB memory
#SBATCH --ntasks=1                   # Number of tasks per job
#SBATCH --cpus-per-task=16           # Number of CPU cores per task
#SBATCH --time=120:00:00             # Maximum job runtime
#SBATCH --partition=compute,memory   # Partition name
#SBATCH --account=research-ceg-wm    # Specify account
#SBATCH --array=0-49                 # Job array, 50 tasks in total (0 to 49)
#SBATCH --threads-per-core=1
# Define log directory

DELAY=$((SLURM_ARRAY_TASK_ID * 30))
sleep ${DELAY}
date

# Activate conda environment
date
source /home/xddeng/miniconda3/bin/activate
conda activate virbot

# Define working directory
workplace=/scratch/xddeng/yangtze/RNA

# Read file list
mapfile -t files < $workplace/sample_list.txt

# Select the file for the current task
file=${files[$SLURM_ARRAY_TASK_ID]}
mkdir -p $workplace/5_virbot

echo "Processing $file on node $(hostname)"

virbot --input $workplace/3_spades_result/reformat/${file}_reformat.fasta --output $workplace/5_virbot/$file --thread 16

conda deactivate
date

```

### Multiple methods for RNA virus identification

## read based human/animal virus identification

[esrviritu.sh](http://esrviritu.sh/)

```bash
#!/bin/bash
#SBATCH --job-name=esviritu         # Job name
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/4_esviritu/log_%A_%a.log  # Standard output log
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/4_esviritu/error_index_%A_%a.log    # Error log
#SBATCH --mem=32G                   # Request 32GB memory
#SBATCH --ntasks=1                   # Number of tasks per job
#SBATCH --cpus-per-task=8           # Number of CPU cores per task
#SBATCH --time=120:00:00             # Maximum job runtime
#SBATCH --partition=compute,memory   # Partition name
#SBATCH --account=research-ceg-wm    # Specify account
#SBATCH --array=0-49                 # Job array, 50 tasks in total (0 to 49)
#SBATCH --threads-per-core=1
# Define log directory

DELAY=$((SLURM_ARRAY_TASK_ID * 30))
sleep ${DELAY}
date

# Activate conda environment
date
source /home/xddeng/miniconda3/bin/activate
conda activate EsViritu

# Define working directory
workplace=/scratch/xddeng/yangtze/RNA

# Read file list
mapfile -t files < $workplace/sample_list.txt

# Select the file for the current task
file=${files[$SLURM_ARRAY_TASK_ID]}

echo "Processing $file on node $(hostname)"

mkdir -p $workplace/4_esviritu
EsViritu -r $workplace/2_ribodetector/${file}/${file}_nonrrna.1.fq.gz $workplace/2_ribodetector/${file}/${file}_nonrrna.2.fq.gz -s ${file} -t 8 -o $workplace/4_esviritu/${file} -p paired

conda deactivate
date
```

### Python merge

[esviritu.py](http://esviritu.py/)

```bash
import os  # Module for interacting with the operating system
import pandas as pd  # Module for data manipulation and analysis

# Get the current working directory
os.getcwd()
# List all files in the "4_esviritu" directory
file_list = os.listdir("4_esviritu")

# Filter the list to include only files that start with "VIR"
file_list = [f for f in file_list if f.startswith("VIR")]

# Initialize an empty DataFrame to store concatenated data
stack_table = None

# Loop through each file in the filtered list
for i in range(len(file_list)):
    file = file_list[i]
    # Construct the file path
    file_name = os.getcwd() + "/4_esviritu/" + file + "/" + file + ".detected_virus.info.tsv"

    # Read the TSV file into a DataFrame
    df = pd.read_csv(file_name, sep="\t")

    # If it's the first file, initialize stack_table with the DataFrame
    if i == 0:
        stack_table = df
    else:
        # Otherwise, concatenate the DataFrame with stack_table
        stack_table = pd.concat([stack_table, df])

    # Print the current iteration index
    print(i)

# Extract the sample number from the "sample_ID" column and convert it to an integer
stack_table["sample_num"] = stack_table["sample_ID"].apply(lambda x: int(x.split("_")[-1]))

# Sort the DataFrame by the "sample_num" column
stack_table_sort = stack_table.sort_values(by=["sample_num"])

# Create a deduplicated table containing unique accessions and their taxonomic information
dereplicate_table = stack_table.drop_duplicates(subset=["accession"])[['accession',
                                                                       'sequence_name', 'taxid', 'kingdom', 'phylum',
                                                                       'class', 'order', 'family', 'genus', 'species',
                                                                       'subspecies', 'strain',
                                                                       ]]

# Sort the unique sample IDs based on the sample number
sample_order = sorted(stack_table["sample_ID"].unique(), key=lambda x: int(x.split("_")[-1]))

# Reshape the sorted table into a wide format, using "accession" as rows, "sample_ID" as columns, and "RPKMF" as values
wide_table = stack_table_sort.pivot_table(index="accession", columns="sample_ID", values="RPKMF", fill_value=0)

# Reorder the columns in wide_table based on the sorted sample IDs
wide_table = wide_table[sample_order]

# Merge the deduplicated table with the wide table on the "accession" column
merge_table = pd.merge(dereplicate_table, wide_table, left_on="accession", right_on="accession")

# Save the merged table to an Excel file
with pd.ExcelWriter("esviritu_VIR_table.xlsx", engine="openpyxl") as writer:
    merge_table.to_excel(writer, sheet_name="merge_table", index=False)
    stack_table_sort.to_excel(writer, sheet_name="Stack_table", index=False)
```

### Bowtie2 for virbot

```bash

```

/Volumes/LaCie/污泥病毒