#!/bin/bash

pg_ctl status

pg_ctl start

pg_ctl stop -m smart

psql template1

sudo pg_ctl stop

sudo -E -u postgres pg_ctl stop

sudo service postgresql start

export PGDATA=/postgres/12
pg_ctl status

pstree

psql -l

id

psql

psql -U postgres -d postgres

psql -d template1

id

psql -d template1 -U luca

cat test.sql

psql -d template1 -U luca -h localhost

psql postgresql://luca@localhost/template1

psql postgresql://luca@localhost:5432/template1

psql -h miguel -U luca template1

psql -h localhost -U luca template1

sudo ls -1 /postgres/12

sudo ls -1 /postgres/12/base

sudo ls -1 /postgres/12/base/13777 | head

oid2name

cd /postgres/12/base/1

oid2name -d template1 -f 3395

sudo ls -l /postgres/12/pg_tblspc/

oid2name -s

cat postgresql.conf
