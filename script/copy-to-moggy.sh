#!/bin/sh -x

cd ..
tar -czvf berkmo-goc2.tar.gz berkmo-goc2/
scp berkmo-goc2.tar.gz berkeley-morris.org:./temp/
ssh berkeley-morris.org 'cd temp && tar -zxvf berkmo-goc2.tar.gz'
