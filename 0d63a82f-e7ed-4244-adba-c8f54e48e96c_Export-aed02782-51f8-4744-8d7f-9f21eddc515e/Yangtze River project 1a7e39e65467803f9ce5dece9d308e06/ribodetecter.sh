#!/bin/bash
#SBATCH --job-name=ribodetector         # 作业名称
#SBATCH --output=/scratch/xddeng/yangtze/RNA/log/2_ribodetector/log_%A_%a.log  # 标准输出日志
#SBATCH --error=/scratch/xddeng/yangtze/RNA/log/2_ribodetector/error_index_%A_%a.log    # 错误日志
#SBATCH --mem=64G                   # 指定作业需要 64GB 内存
#SBATCH --ntasks=1                   # 每个作业的任务数
#SBATCH --cpus-per-task=16           # 每个任务使用的CPU核心数
#SBATCH --time=120:00:00             # 作业运行时间上限
#SBATCH --partition=compute,memory   # 分区名称
#SBATCH --account=research-ceg-wm    # 指定账户
#SBATCH --array=0-49                 # 任务数组，共 50 组（0 到 49）
#SBATCH --threads-per-core=1

# 定义日志目录
LOG_DIR="/scratch/xddeng/yangtze/RNA/log/2_ribodetector"
mkdir -p $LOG_DIR

# 记录作业开始时间
echo "Job started at: $(date)" > ${LOG_DIR}/index_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log

# 激活 conda 环境
source /home/xddeng/miniconda3/bin/activate
conda activate ribodetector

# 定义工作目录
workplace=/scratch/xddeng/yangtze/RNA

# 读取文件列表
mapfile -t files < $workplace/sample_list.txt

# 选取当前任务的文件
file=${files[$SLURM_ARRAY_TASK_ID]}

echo "Processing $file on node $(hostname)"

# 创建输出目录
mkdir -p $workplace/2_ribodetector/${file}

# 运行 ribodetector
ribodetector_cpu -t 16 \
  -l 50 \
  -i $workplace/1_fastp/${file}/${file}_1P.fq.gz $workplace/1_fastp/${file}/${file}_2P.fq.gz \
  -e rrna \
  --chunk_size 2500 \
  -o $workplace/2_ribodetector/${file}/${file}_nonrrna.1.fq.gz $workplace/2_ribodetector/${file}/${file}_nonrrna.2.fq.gz

# 停用 conda 环境
conda deactivate

# 记录作业结束时间
echo "Job finished at: $(date)" >> ${LOG_DIR}/index_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log
