sudo apt update &&
sudo apt install -y --allow-unauthenticated \
  subversion \
  gfortran \
  cmake \
  unixodbc-dev \
  build-essential

svn checkout https://svn.code.sf.net/p/open-fvs/code/trunk/ ~/workspace/open-fvs
cd ~/workspace/open-fvs/bin
make

rm -r *buildDir

cat >>/etc/odbcinst.ini <<EOF
[SQLite3 ODBC Driver]
Description=SQLite3 ODBC Driver
Driver=libsqlite3odbc.so
Setup=libsqlite3odbc.so
UsageCount=1
EOF