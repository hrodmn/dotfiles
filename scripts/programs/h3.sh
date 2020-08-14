cd /tmp
git clone https://github.com/crazycapivara/h3-r.git
pushd h3-r
chmod +x install-h3c.sh
# Install H3 C Library
./install-h3c.sh
# Install H3 for R
R -q -e 'devtools::install(upgrade = F)'
popd
rm -rf h3-r
