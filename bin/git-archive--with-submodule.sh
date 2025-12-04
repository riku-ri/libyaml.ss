set -exuo pipefail
git submodule update --init --recursive
git submodule foreach sh -c 'git archive HEAD --prefix=egg/$(realpath --relative-to=$(git rev-parse --show-superproject-working-tree) .)/ | tar x -C $(git rev-parse --show-superproject-working-tree)/.local'
git archive HEAD --prefix=egg/ | tar x -C .local
