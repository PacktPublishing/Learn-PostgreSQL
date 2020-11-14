psql -U luca forumdb

psql -h miguel -U luca forumdb

sudo -u postgres grep password_encryption $PGDATA/postgresql.conf

psql "postgresql://luca@localhost:5432/forumdb?sslmode=require"

psql "postgresql://luca@localhost:5432/forumdb"

psql "postgresql://luca@localhost:5432/forumdb?sslmode=require"

psql "postgresql://luca@localhost:5432/forumdb?sslmode=disable"
