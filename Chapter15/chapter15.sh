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
