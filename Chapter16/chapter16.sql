SELECT name, setting || ' ' || unit AS current_value, short_desc,extra_desc, min_val, max_val, reset_val
FROM pg_settings;

SELECT name, setting AS current_value, sourcefile, sourceline,pending_restart FROM pg_settings;

SELECT name, setting, sourcefile, sourceline, applied, error FROM pg_file_settings ORDER BY name;

SELECT name, setting, sourcefile, sourceline, applied, error FROM pg_file_settings ORDER BY name;

SELECT distinct context FROM pg_settings ORDER BY context;

ALTER SYSTEM SET archive_mode = 'on';

ALTER SYSTEM SET archive_mode TO DEFAULT;

ALTER SYSTEM RESET archive_mode;

ALTER SYSTEM RESET ALL;

SELECT usename, datname, client_addr, application_name,backend_start, query_start,state, backend_xid, query
FROM pg_stat_activity;

SELECT a.usename, a.application_name, a.datname, a.query,l.granted, l.mode
FROM pg_locks l
JOIN pg_stat_activity a ON a.pid = l.pid;

SELECT query, backend_start, xact_start, query_start,state_change, state,now()::time - state_change::time AS locked_since,pid, wait_event_type, wait_event
FROM pg_stat_activity
WHERE wait_event_type IS NOT NULL
ORDER BY locked_since DESC;

SELECT datname, xact_commit, xact_rollback, blks_read, conflicts,deadlocks,tup_fetched, tup_inserted, tup_updated, tup_deleted, stats_reset
FROM pg_stat_database;

SELECT relname, seq_scan, idx_scan,n_tup_ins, n_tup_del, n_tup_upd, n_tup_hot_upd,n_live_tup, n_dead_tup,
last_vacuum, last_autovacuum,last_analyze, last_autoanalyze
FROM pg_stat_user_tables;

SELECT auth.rolname,query, db.datname, calls, min_time, max_time
FROM pg_stat_statements
JOIN pg_authid auth ON auth.oid = userid
JOIN pg_database db ON db.oid = dbid
ORDER BY calls DESC;

SELECT pg_stat_statements_reset();
