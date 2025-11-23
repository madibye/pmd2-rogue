cd "${0%/*}"/assets
git sparse-checkout add $1
git pull origin master
