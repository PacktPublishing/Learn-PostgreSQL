CREATE DATABASE forumdb_test WITH OWNER luca;

\i backup_forumdb.sql

SELECT * FROM tags;

SELECT * FROM public.tags;

SELECT pg_catalog.set_config('search_path', 'public,"$user"', false);

SELECT * FROM tags;

DROP DATABASE forumdb;

\i backup_forumdb.sql

SELECT count(*) FROM tags;
