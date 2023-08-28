#!/bin/bash
#SBATCH --job-name=rae_filter_author_works_complete                   # Job name
#SBATCH --mail-type=ALL                                 # Mail events (NONE, BEGIN, END, FAIL, ALL) - update on ALL
#SBATCH --mail-user=milan.makany@warwick.ac.uk          # Notifications to email
#SBATCH --nodes=1                                       # Use one node
#SBATCH --ntasks-per-node=1                             # Run the single python script
#SBATCH --cpus-per-task=4                               # Allocate cores
#SBATCH --mem-per-cpu=4000                              # Allocate memory for the job
#SBATCH --time=16:00:00                                 # Time limit, estimated based on previous single core runs

# The time limit on this script may be a large overestimate
# Never executed this script with the new data structure

# Execute code
python3 /storage/economics/ecudpb/wia/scripts/openalex_scripts/filter.py --filter_econ_authors_works --remote True

