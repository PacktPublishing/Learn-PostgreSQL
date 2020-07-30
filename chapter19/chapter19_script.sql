set enable_seqscan to 'off';

select * from t1;

create index db_source_name_btree on t1 using btree(name varchar_pattern_ops);

  explain analyze select * from t1 where name like 'Li%';

  explain analyze select * from t1 where name like '%Li';

explain analyze select * from t1 where name ilike '%Li';

create index db_source_name_gin on t1 using gin (name gin_trgm_ops);

  explain analyze select * from t1 where name ilike '%Li';

select * from t1;

select * from t2;

create extension postgres_fdw ;

CREATE SERVER remote_pg2 FOREIGN DATA WRAPPER postgres_fdw  OPTIONS (host '192.168.12.36', dbname 'db2');

CREATE USER MAPPING FOR CURRENT_USER SERVER remote_pg2  OPTIONS (user 'postgres', password '');


create foreign table f_t2 (id integer, name varchar(64)) SERVER remote_pg2 OPTIONS (schema_name 'public', table_name 't2');

select * from f_t2;

 create extension btree_gin;

   create table users (id serial not null primary key,name varchar(64) ,surname varchar(64),
    sex char(1));

select count(*) from users;

select * from users limit 4;

select count(*) from users where sex='M';

create index sex_btree on users using btree (sex);

create index sex_gin on users using gin (sex);

  select pg_size_pretty(pg_relation_size('sex_btree'));

select pg_size_pretty(pg_relation_size('sex_gin'));

ssh-keygen -t rsa -b 4096

ls -l

cd $HOME/.ssh

cat id_rsa.pub

ssh postgres@192.168.12.35

cat id_rsa.pub

apt-get update

apt-get install -y pgbackrest


[global]
start-fast=y
archive-async=y
process-max=2
repo-path=/var/lib/pgbackrest
repo1-retention-full=2
repo1-retention-archive=5
repo1-retention-diff=3
log-level-console=info
log-level-file=info
compress = y
compress-level = 9
compress-level-network = 9
repo1-cipher-type = aes-256-cbc
repo1-cipher-pass = SuperSecret
[pg1]
pg1-host = 192.168.12.35
pg1-host-user = postgres
pg1-path = /var/lib/postgresql/12/main
pg1-port = 5432


#PGBACKREST
archive_mode = on
wal_level = logical
archive_command = 'pgbackrest --stanza=pg1 archive-push %p'

systemctl restart postgresql

[global]
backup-host=192.168.12.37
backup-user=postgres
backup-ssh-port=22
log-level-console=info
log-level-file=info

[pg1]
pg1-path = /var/lib/postgresql/12/main
pg1-port = 5432

sudo -iu postgres pgbackrest --stanza=pg1 stanza-create

sudo -iu postgres pgbackrest --stanza=pg1 check

sudo -iu postgres pgbackrest --stanza=pg1 --type=full backup

sudo -iu postgres pgbackrest --stanza=pg1 info

sudo -iu postgres pgbackrest --stanza=pg1 --type=diff backup

sudo -iu postgres pgbackrest --stanza=pg1 --type=incr backup

sudo -iu postgres pgbackrest --stanza=pg1 info

sudo -iu postgres pgbackrest --stanza=pg1 --type=full backup

sudo -iu postgres pgbackrest --stanza=pg1 info

select now();

select count(*) from users;

drop table users;

systemctl stop postgresql

sudo -u postgres pgbackrest --stanza=pg1 --delta --log-level-console=info --type=time "--target=2020-05-30 16:23:38" restore

systemctl start postgresql

select pg_wal_replay_resume();

select count(*) from users;
