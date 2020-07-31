ping pg2

ping pg1

CREATE USER replicarole WITH REPLICATION ENCRYPTED PASSWORD 'SuperSecret';

# Add settings for extensions here
listen_addresses = '*'
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10

netstat -an | grep 5432

# Add settings for extensions here
listen_addresses = '*'
wal_level = logical
max_logical_replication_workers = 4
max_worker_processes = 10

netstat -an | grep 5432

# IPv4 local connections:
host all all 127.0.0.1/32 md5
host all replicarole 192.168.122.36/32 md5

systemctl reload postgresql

create database db_source;

create table t1 (id integer not null primary key, name varchar(64));

SELECT ON ALL TABLES IN SCHEMA public TO replicarole;

CREATE PUBLICATION all_tables_pub FOR ALL TABLES;

create database db_destination;

create table t1 (id integer not null primary key, name varchar(64));

CREATE SUBSCRIPTION sub_all_tables CONNECTION 'user=replicarole password=SuperSecret host=pg1 port=5432 dbname=db_source' PUBLICATION all_tables_pub;

insert into t1 values(1,'Linux'),(2,'FreeBSD');

select * from t1;

select * from pg_stat_replication ;

select * from pg_publication;

select * from pg_subscription;

insert into t1 values (3,'OpenBSD');

insert into t1 values(4,'Minix');

insert into t1 values(3,'Windows');

insert into t1 values(5,'Unix');

drop subscription sub_all_tables ;

truncate t1;

CREATE SUBSCRIPTION sub_all_tables CONNECTION 'user=replicarole password=SuperSecret host=pg1 port=5432 dbname=db_source' PUBLICATION all_tables_pub;

alter table t1 add description varchar(64);

delete from t1 where id=5;

alter table t1 add description varchar(64);

drop subscription sub_all_tables ;

sub_all_tables SET (slot_name = NONE);

db_destination=#  sub_all_tables disable;

db_destination=#  sub_all_tables SET (slot_name = NONE);

db_destination=# drop subscription sub_all_tables ;
