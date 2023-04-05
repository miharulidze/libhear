#!/bin/bash -l

#SBATCH --job-name="osu_allreduce"
#SBATCH --account="g34"
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mikhail.khalilov@inf.ethz.ch
#SBATCH --time=360
#SBATCH --nodes=32
#SBATCH --partition=normal
#SBATCH --constraint=mc
#SBATCH --hint=nomultithread
#SBATCH --exclusive

SMALL_NITERATIONS=100000
LARGE_NITERATIONS=1000
LOG_PATH="/users/mkhalilo/hear/logs4/"
OSU_PATH="/users/mkhalilo/hear/osu-micro-benchmarks-7.0.1/c/mpi/collective/osu_allreduce"
HEAR_OPTIMIZED_MPOOL_PATH="/users/mkhalilo/hear/homomorphic-mpi/lib/libhear_release_mpool.so"
HEAR_OPTIMIZED_PATH="/users/mkhalilo/hear/homomorphic-mpi/lib/libhear_release.so"

srun_experiment()
{
    NRANKS="${1}"
    SRUN_CMD="${2}"

    # Cray MPI
    for msg_size in {8,16}
    do
	for trial in {1,2}
	do
	    BASELINE_CMD="${SRUN_CMD} ${OSU_PATH} -m ${msg_size}:${msg_size} -f -i ${SMALL_NITERATIONS} &> ${LOG_PATH}/osu_allreduce.baseline.${NRANKS}.${msg_size}.${trial}.log"
	    echo "$BASELINE_CMD"
	    echo "$BASELINE_CMD" &> ${LOG_PATH}/osu_allreduce.baseline.${NRANKS}.${msg_size}.${trial}.cmd
	    eval $BASELINE_CMD
	done
    done

    # Cray MPI
    for msg_size in {8388608,16777216}
    do
	for trial in {1,2}
	do
	    BASELINE_CMD="${SRUN_CMD} ${OSU_PATH} -m ${msg_size}:${msg_size} -f -i ${LARGE_NITERATIONS} &> ${LOG_PATH}/osu_allreduce.baseline.${NRANKS}.${msg_size}.${trial}.log"
	    echo "$BASELINE_CMD"
	    echo "$BASELINE_CMD" &> ${LOG_PATH}/osu_allreduce.baseline.${NRANKS}.${msg_size}.${trial}.cmd
	    eval $BASELINE_CMD
	done
    done

    # Hear + mpool
    for msg_size in {8,16}
    do
	for trial in {1,2}
	do
	    OPTIMIZED_CMD="HEAR_ENABLE_AESNI=1 LD_PRELOAD=${HEAR_OPTIMIZED_MPOOL_PATH} ${SRUN_CMD} ${OSU_PATH} -m ${msg_size}:${msg_size} -f -i ${SMALL_NITERATIONS} &> ${LOG_PATH}/osu_allreduce.optimized.${NRANKS}.${msg_size}.${trial}.log"
	    echo "$OPTIMIZED_CMD"
	    echo "$OPTIMIZED_CMD" &> ${LOG_PATH}/osu_allreduce.optimized.${NRANKS}.${msg_size}.${trial}.cmd
	    eval $OPTIMIZED_CMD
	done
    done

    # Hear + pipelining
    for block_size in {32768,65536,131072} # empirically tuned with scripts/osu_block_size.sh
    do
	for msg_size in {8388608,16777216}
	do
	    for trial in {1,2}
	    do
		OPTIMIZED_CMD="HEAR_PIPELINING_BLOCK_SIZE=${block_size} HEAR_MPOOL_SBUF_LEN=2097152 HEAR_ENABLE_AESNI=1 LD_PRELOAD=${HEAR_OPTIMIZED_PATH} ${SRUN_CMD} ${OSU_PATH} -m ${msg_size}:${msg_size} -f -i ${LARGE_NITERATIONS} &> ${LOG_PATH}/osu_allreduce.optimized.${NRANKS}.${msg_size}.${block_size}.${trial}.log"
		echo "$OPTIMIZED_CMD"
		echo "$OPTIMIZED_CMD" &> ${LOG_PATH}/osu_allreduce.optimized.${NRANKS}.${msg_size}.${block_size}.${trial}.cmd
		eval $OPTIMIZED_CMD
	    done
	done
    done
}

for nranks_per_node in {1,2,4,8,18}
do
    nranks=$(( $nranks_per_node * 2 ))
    srun_cmd="srun --cpu-bind=core --nodes=2 --ntasks=${nranks} --ntasks-per-core=1 --ntasks-per-node=${nranks_per_node} --ntasks-per-socket=$nranks_per_node"
    srun_experiment "$nranks" "$srun_cmd"
done

for nnodes in {2,4,8,16,32}
do
    nranks=$(( $nnodes * 36 ))
    srun_cmd="srun --cpu-bind=core --nodes=${nnodes} --ntasks=${nranks} --ntasks-per-core=1 --ntasks-per-node=36 --ntasks-per-socket=18"
    srun_experiment "$nranks" "$srun_cmd"
done
