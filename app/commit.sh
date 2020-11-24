#!/bin/sh
PRJ=project$1
git clone https://github.com/dbms-class/csc-2020-team-all
cd csc-2020-team-all
git checkout -b $PRJ
mkdir $PRJ
cd $PRJ
cp "$2" $PRJ.sql
git add $PRJ.sql
git commit 
git push origin
