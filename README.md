#UG4 dissertation project

source activate lda
//
cd ~/miniconda3/envs/mlp
\\
mkdir -p ./etc/conda/activate.d
mkdir -p ./etc/conda/deactivate.d
echo -e '#!/bin/sh\n' >> ./etc/conda/activate.d/env_vars.sh
echo "export AAN_DIR=$HOME/lda/aan/" >> ./etc/conda/activate.d/env_vars.sh
echo -e '#!/bin/sh\n' >> ./etc/conda/deactivate.d/env_vars.sh
echo 'unset AAN_DIR' >> ./etc/conda/deactivate.d/env_vars.sh
export AAN_DIR=$HOME/lda/aan
