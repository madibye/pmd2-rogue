git sparse-checkout set
git sparse-checkout add resources
git sparse-checkout add game
git sparse-checkout add addons
git sparse-checkout add assets
cd DumpAsset || exit
git sparse-checkout set
cd ../RawAsset || exit
git sparse-checkout set
cd .. || exit
