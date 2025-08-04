#!/bin/bash
#SBATCH --job-name=RNA_fastp         # 作业名称
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/1_fastp/output_%A_%a.log  # 标准输出和错误日志
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/1_fastp/error_%A_%a.log    # 错误日志
#SBATCH --mem=128G  # 指定作业需要 64GB 内存
#SBATCH --ntasks=1                # 每个作业的任务数
#SBATCH --cpus-per-task=24         # 每个任务使用的CPU核心数
#SBATCH --time=6:10:00           # 作业运行时间上限
#SBATCH --partition=compute      # 分区名称
#SBATCH --account=research-ceg-wm    # 指定账户
#SBATCH --array=0-16              # 任务数组，共17组（50/3向上取整）
source /home/xddeng/miniconda3/bin/activate
conda activate fastp
workplace=/scratch/xddeng/yangtze/RNA

mkdir -p $workplace/log/1_fastp


# 读取文件列表
mapfile -t files < $workplace/sample_list.txt

# 每3个文件为一组
group_size=3

# 计算当前组的起始索引
start_index=$((SLURM_ARRAY_TASK_ID * group_size))

# 获取当前组的文件
group_files=("${files[@]:start_index:group_size}")

# 处理当前组的文件
for file in "${group_files[@]}"; do
    echo "Processing $file on node $(hostname)"
    # 在这里添加处理文件的命令
    pwd
    cd $workplace/RNA
    pwd
    bsnm=$file
    mkdir -p 1_fastp/$bsnm
    echo $bsnm "is processing"
    time fastp --thread 48 --in1 0_rawdata/${bsnm}/${bsnm}.R1.fq.gz --in2 0_rawdata/${bsnm}/${bsnm}.R2.fq.gz --out1 1_fastp/$bsnm/${bsnm}_1P.fq.gz --out2 1_fastp/$bsnm/${bsnm}_2P.fq.gz --unpaired1 1_fastp/$bsnm/${bsnm}_U1.fq.gz --unpaired2 1_fastp/$bsnm/${bsnm}_U2.fq.gz -h 1_fastp/$bsnm/${bsnm}.fastp.html -j 1_fastp/$bsnm/${bsnm}.fastp.json --trim_poly_g --trim_poly_x --qualified_quality_phred 20 --length_required 20 --dont_overwrite
done
conda deactivate
