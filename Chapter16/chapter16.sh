pg_test_fsync

sudo cat /postgres/12/postgresql.auto.conf

#on postgresql.conf add
shared_preload_libraries = 'pg_stat_statements'

#and then execute
psql -U postgres -c "CREATE EXTENSION pg_stat_statements;" forumdb
