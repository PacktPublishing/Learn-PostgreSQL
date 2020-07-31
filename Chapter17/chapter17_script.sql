mkdir walbackup
chown postgres.postgres walbackup/
chown postgres.postgres walbackup/
mkdir /databackup
chown postgres.postgres databackup
chmod 0700 databackup/


Add settings for extensions here
archive_mode = on
archive_command = 'test ! -f /walbackup/%f && cp %p /walbackup/%f'
wal_level = replica
archive_timeout = 10 optional

service PostgreSQL stop
service PostgreSQL start

SELECT pg_start_backup( 'MY_FIRST_PITR', true, false );

sudo -u postgres rsync -a /var/lib/PostgreSQL/12/main /databackup/
sudo -u postgres rm /databackup/main/postmaster.pid
sudo -u postgres rm /databackup/main/postmaster.opts

SELECT pg_stop_backup( false );

\i /tmp/setup_00-forum-database.sql

select * from categories;

SELECT txid_current(), current_timestamp;

insert into categories (title,description) values ('BSD','Unix BSD discussions');

SELECT txid_current(), current_timestamp;

------------------------------------------------------------------------------
CUSTOMIZED OPTIONS
------------------------------------------------------------------------------
Add settings for extensions here
----- PATH AND PORT OPTIONS
data_directory = '/databackup/main'  use data in another directory
(change requires restart)
hba_file = '/databackup/main//pg_hba.conf'  host-based authentication file
(change requires restart)
ident_file = '/databackup/main/pg_ident.conf'  ident configuration file
(change requires restart)
port = 5433  (change requires restart)
--- PITR OPTIONS -----
restore_command = 'cp /walbackup/%f "%p"'
recovery_target_xid = 498

sudo -u postgres /usr/lib/PostgreSQL/12/bin/pg_ctl -D /databackup/main/ start

select * from categories;

create table my_table(id integer);

select pg_wal_replay_resume();

create table my_table(id integer);

CREATE USER replicarole WITH REPLICATION ENCRYPTED PASSWORD 'SuperSecret';

host replication replicarole 192.168.12.35/32 md5

select pg_reload_conf();

systemctl stop PostgreSQL
cd /var/lib/PostgreSQL/12/
rm -rf main
mkdir main
chown postgres.postgres main
chmod 0700 main

SELECT * FROM pg_create_physical_replication_slot('master');

select pg_drop_replication_slot('master');

cd /var/lib/PostgreSQL/12/main

pg_basebackup -h pg1 -U replicarole -p 5432 -D

cat PostgreSQL.auto.conf

systemctl start PostgreSQL

create table test_table (id integer);

select * from pg_stat_replication ;

systemctl reload PostgreSQL

SELECT * FROM pg_create_physical_replication_slot('standby1');

systemctl stop PostgreSQL

rm -rf /var/lib/PostgreSQL/12/main/*

pg_basebackup -h pg2 -U replicarole -p 5432 -D /var/lib/PostgreSQL/12/main -Fp -Xs -P -R -S standby1

systemctl start PostgreSQL

select * from pg_stat_replication ;

select * from pg_stat_replication;

synchronous_standby_names = 'pg2'
synchronous_commit = on

systemctl restart PostgreSQL

select * from pg_stat_replication ;
