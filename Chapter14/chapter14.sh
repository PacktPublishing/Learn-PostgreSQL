sudo ls -1 /postgres/12/log

sudo cat /postgres/12/logging.conf

sudo -u postgres pg_ctl -D /postgres/12 restart

date

psql -U luca forumdb

\timing

sudo tail /postgres/12/log/postgresql-2020-04-016.log

wget https://github.com/darold/pgbadger/archive/v11.2.tar.gz

tar xzvf v11.2.tar.gz

cd pgbadger-11.2

perl Makefile.PL

make

sudo make install

pgbadger --version

sudo mkdir /postgres/reports
sudo chown postgres:postgres /postgres/reports

sudo -u postgres pgbadger -o /postgres/reports/first_report.html /postgres/12/log/postgresql-2020-04-17.pgbadger.log

sudo -u postgres pgbadger -I --outdir /postgres/reports/ /postgres/12/log/postgresql-2020-04-17.pgbadger.log

wget https://github.com/pgaudit/pgaudit/archive/1.4.0.tar.gz

tar xzvf 1.4.0.tar.gz

cd pgaudit-1.4.0

make USE_PGXS=1

sudo make USE_PGXS=1 install

sudo pg_ctl -D /postgres/12 restart
