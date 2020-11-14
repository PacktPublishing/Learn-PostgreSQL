SELECT * FROM categories ORDER BY description;

SELECT name, setting
FROM pg_settings
WHERE name LIKE 'cpu%\_cost'
OR name LIKE '%page\_cost'
ORDER BY setting DESC;

CREATE INDEX idx_post_category ON posts( category );

CREATE INDEX idx_author_created_on ON posts( author, created_on );

CREATE INDEX idx_post_created_on ON posts USING hash ( created_on );

\d posts

SELECT relname, relpages, reltuples,
i.indisunique, i.indisclustered, i.indisvalid,
pg_catalog.pg_get_indexdef(i.indexrelid, 0, true)
FROM pg_class c JOIN pg_index i on c.oid = i.indrelid
WHERE c.relname = 'posts';

UPDATE pg_index SET indisvalid = false
WHERE indexrelid = ( SELECT oid FROM pg_class
WHERE relkind = 'i'
AND relname = 'idx_author_created_on' );

EXPLAIN SELECT * FROM categories;

EXPLAIN SELECT title FROM categories ORDER BY description DESC;

EXPLAIN ( FORMAT JSON ) SELECT * FROM categories;

EXPLAIN SELECT * FROM categories;

EXPLAIN ANALYZE SELECT * FROM categories;

EXPLAIN (VERBOSE on) SELECT * FROM categories;

EXPLAIN (COSTS off) SELECT * FROM categories;

EXPLAIN (COSTS on) SELECT * FROM categories;

EXPLAIN (ANALYZE on, TIMING off) SELECT * FROM categories;

EXPLAIN (ANALYZE, SUMMARY on) SELECT * FROM categories;

EXPLAIN (ANALYZE, BUFFERS on) SELECT * FROM categories;

EXPLAIN (WAL on, ANALYZE on, FORMAT yaml)
insert into users( username, gecos, email)
select 'username'||v, v, v||'@c.b.com' from generate_series(1, 100000) v;

EXPLAIN SELECT * FROM posts ORDER BY created_on;

EXPLAIN ANALYZE SELECT * FROM posts ORDER BY created_on;

CREATE INDEX idx_posts_date ON posts( created_on );

EXPLAIN ANALYZE SELECT * FROM posts ORDER BY created_on;

SELECT pg_size_pretty( pg_relation_size( 'posts' ) ) AS table_size,
pg_size_pretty( pg_relation_size( 'idx_posts_date' ) ) AS index_size;

EXPLAIN SELECT p.title, u.username
FROM posts p
JOIN users u ON u.pk = p.author
WHERE u.username = 'fluca1978'
AND
daterange( CURRENT_DATE - 2, CURRENT_DATE ) @> p.created_on::date;

EXPLAIN ANALYZE SELECT p.title, u.username
FROM posts p
JOIN users u ON u.pk = p.author
WHERE u.username = 'fluca1978'
AND daterange( CURRENT_DATE - 2, CURRENT_DATE ) @> p.created_on::date;

CREATE INDEX idx_posts_author ON posts( author );

EXPLAIN ANALYZE SELECT p.title, u.username
FROM posts p
JOIN users u ON u.pk = p.author
WHERE u.username = 'fluca1978'
AND daterange( CURRENT_DATE - 2, CURRENT_DATE ) @> p.created_on::date;

SELECT pg_size_pretty( pg_relation_size( 'posts') ) AS table_size,
pg_size_pretty( pg_relation_size( 'idx_posts_date' ) ) AS idx_date_size,
pg_size_pretty( pg_relation_size( 'idx_posts_author' ) ) AS idx_author_size;

SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch FROM
pg_stat_user_indexes WHERE relname = 'posts';


\timing

ANALYZE posts ;

SELECT n_distinct
FROM pg_stats
WHERE attname = 'author' AND tablename = 'posts';

SELECT * FROM pg_stats;

SELECT count(*) FROM posts WHERE author = 2358;

SELECT count(*) -- p.title, u.username
FROM posts p
JOIN users u ON u.pk = p.author
WHERE u.username = 'fluca1978'
AND daterange( CURRENT_DATE - 20, CURRENT_DATE ) @> p.created_on::date;
