Этот репозиторий предназначен для рецензирования кода проектов, сделанных во время прохождения курса "Базы Данных" в Computer Science Center

## Как залить код проекта в репозиторий

* Этот скрипт предполагает, что у вас Linux в котором есть git CLI и вы умеете авторизовываться в GitHub (что не очень тривиально). Если у вас иная OS, сделайте аналогичные действия её средствами
* Первым аргументом скрипта является номер вашего проекта, вторым -- путь к файлу с вашим кодом

```
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
```
