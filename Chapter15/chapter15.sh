pg_dump -U postgres forumdb

pg_dump -U postgres --column-inserts forumdb

pg_dump -U postgres --column-inserts forumdb > backup_forumdb.sql

pg_dump -U postgres --column-inserts -f backup_forumdb.sql forumdb

pg_dump -U postgres -f backup_forumdb.sql -v forumdb

pg_dump -U postgres --column-inserts -f backup_forumdb.sql forumdb

psql -U postgres template1

psql -U luca forumdb_test

pg_dump -U postgres --column-inserts --create -f backup_forumdb.sql forumdb

less backup_forumdb.sql

psql -U postgres template1

pg_dump -U postgres -s -f database_structure.sql forumdb

pg_dump -U postgres -a -f database_content.sql forumdb

pg_dump -U postgres -f users.sql -t users -t user_pk_seq forumdb

pg_dump -U postgres -f users.sql -T users -T user_pk_seq forumdb

pg_dump -U postgres -f posts.sql -t posts -a forumdb

pg_dump -U postgres -Fc --create -f backup_forumdb.backup forumdb

ls -lh backup_forumdb*

file backup_forumdb.backup

pg_dump -U postgres -Fc --create --inserts -f backup_forumdb.backup forumdb

pg_dump -U postgres -Fc --create --column-inserts -f backup_forumdb.backup forumdb

pg_restore backup_forumdb.backup -f restore.sql

pg_dump -U postgres -Fd -f backup forumdb

ls -lh backup

psql -U postgres -c "DROP DATABASE forumdb;" template1

pg_restore -C -d template1 -U postgres backup/

psql -U luca forumdb

pg_dump -U postgres -Ft -f backup_forumdb.tar forumdb

tar tvf backup_forumdb.tar

pg_restore --list backup/

pg_restore --list backup/ > my_toc.txt

pg_restore -C -d template1 -U postgres -L my_toc.txt

psql -U luca forumdb

pg_dumpall -U postgres -f cluster.sql

less cluster.sql

pg_dump -U postgres -Fd -f backup_forumdb -v -j 3 forumdb

psql -U postgres -c "DROP DATABASE forumdb;" template1

pg_restore -C -d template1 -U postgres -j 2 -v backup_forumdb/

crontab -e

#Inside the crontab
30 23 * * * pg_dump -Fc -f /backup/forumdb,backup -U postgres forumdb


#bash script at page 19 my_backup_script.sh
#!/bin/sh
BACKUP_ROOT=/backup
for database in $( psql -U postgres -A -t -c "SELECT datname FROM
pg_database WHERE datname <> 'template0'" template1 )
do
  backup_dir=$BACKUP_ROOT/$database/$(date +'%Y-%m-%d')
  if [ -d $backup_dir ]; then
      echo "Skipping backup $database, already done today!"
      continue
  fi
  mkdir -p $backup_dir
  pg_dump -U postgres -Fd -f $backup_dir $database
  echo "Backup $database into $backup_dir done!"
done

#Inside the crontab
30 23 * * * my_backup_script.sh

sudo -u postgres pg_basebackup -D /backup/pg_backup -l 'My Physical Backup' -v -h localhost -p 5432 -U postgres

sudo -u postgres pg_basebackup -D /backup/pg_backup -l 'My Physical Backup' -v -h localhost -p 5432 -U postgres

sudo -u postgres pg_verifybackup /backup/pg_backup

sudo -u postgres pg_ctl -D /backup/pg_backup -o '-p 5433' start

sudo cat /backup/pg_backup/log/postgresql-2020-05-10.log
