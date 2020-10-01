
CREATE ROLE luca;

CREATE ROLE luca WITH NOCREATEROLE NOCREATEDB;

ALTER ROLE luca WITH CREATEDB;

ALTER ROLE luca WITH CREATEROLE;

ALTER ROLE luca CREATEROLE CREATEDB;

ALTER ROLE luca NOCREATEROLE, NOCREATEDB;

ALTER ROLE enrico RENAME TO enrico_pirozzi;

ALTER ROLE enrico RENAME TO enrico_pirozzi;

SELECT current_user, session_user;

SET ROLE forum_stats;

SET client_min_messages TO 'DEBUG';

ALTER ROLE luca IN DATABASE forumdb SET client_min_messages TO 'DEBUG';

ALTER ROLE luca IN DATABASE forumdb RESET ALL;

\du

SELECT * FROM pg_authid WHERE rolname = 'luca';

SELECT * FROM pg_roles WHERE rolname = 'luca';

SELECT r.rolname, g.rolname AS group, m.admin_option AS is_admin
FROM pg_auth_members m
JOIN pg_roles r ON r.oid = m.member
JOIN pg_roles g ON g.oid = m.roleid
ORDER BY r.rolname;


CREATE ROLE forum_admins WITH NOLOGIN;

CREATE ROLE forum_stats WITH NOLOGIN;

REVOKE ALL ON users FROM forum_stats;

GRANT SELECT (username, gecos) ON users TO forum_stats;

GRANT forum_admins TO enrico;

GRANT forum_stats;

SELECT * FROM users;

GRANT SELECT ON users TO luca;

REVOKE SELECT ON users FROM luca;

CREATE ROLE forum_emails WITH NOLOGIN NOINHERIT;

GRANT SELECT (email) ON users TO forum_emails;

GRANT forum_emails TO forum_stats;

SELECT username, gecos, email FROM users;

SELECT current_role;

SET ROLE TO forum_emails;

SELECT email FROM users;

SELECT gecos FROM users;

ALTER ROLE forum_emails WITH INHERIT;

SELECT gecos, username, email FROM users;

\dp categories

GRANT SELECT, UPDATE, INSERT ON categories TO luca;

GRANT DELETE ON categories TO PUBLIC;

CREATE TABLE foo();

\dp foo

GRANT SELECT, INSERT,UPDATE, DELETE ON foo TO enrico;

\dp foo

REVOKE TRUNCATE ON foo FROM enrico;

REVOKE INSERT ON foo FROM PUBLIC;

SELECT acldefault( 'r', r.oid )
FROM pg_roles r
WHERE r.rolname = CURRENT_ROLE;

SELECT acldefault( 'f', r.oid )
FROM pg_roles r
WHERE r.rolname = CURRENT_ROLE;

REVOKE ALL ON categories FROM forum_stats;

GRANT SELECT, INSERT, UPDATE ON categories TO forum_stats;

\dp categories

REVOKE ALL ON users FROM forum_stats;

GRANT SELECT (username, gecos),
UPDATE (gecos)
ON users TO forum_stats;

SELECT * FROM users;

SELECT gecos, username FROM users;

UPDATE users SET username = upper( username );

UPDATE users SET gecos = lower( gecos );

\dp users

GRANT SELECT ON users TO forum_stats;

SELECT * FROM users;

REVOKE SELECT (pk, email) ON users FROM forum_stats

\dp users

REVOKE SELECT ON users FROM forum_stats;

REVOKE ALL ON SEQUENCE categories_pk_seq FROM luca;

SELECT nextval( 'categories_pk_seq' );

forumdb=# GRANT USAGE ON SEQUENCE categories_pk_seq TO luca;

SELECT setval( 'categories_pk_seq', 10 );

SELECT nextval( 'categories_pk_seq' );

CREATE SCHEMA configuration;

CREATE TABLE configuration.conf( param text,value text,UNIQUE (param) );

GRANT CREATE ON SCHEMA configuration TO luca;

GRANT USAGE ON SCHEMA configuration TO luca;

CREATE TABLE configuration.conf( param text,value text,UNIQUE (param) );

INSERT INTO configuration.conf VALUES( 'posts_per_page', '10' );

REVOKE USAGE ON SCHEMA configuration FROM luca;

SELECT * FROM configuration.conf;

GRANT USAGE ON SCHEMA configuration TO luca;

REVOKE CREATE ON SCHEMA configuration FROM luca;

REVOKE ALL ON ALL TABLES IN SCHEMA configuration FROM luca;

REVOKE GRANT SELECT, INSERT, UPDATE ON ALL TABLES;

REVOKE USAGE ON LANGUAGE plperl FROM PUBLIC;

DO LANGUAGE plperl $$ elog( INFO, "Hello World" ); $$;

GRANT USAGE ON LANGUAGE plperl TO luca;

CREATE FUNCTION get_max( a int, b int ) RETURNS int AS $$
BEGIN
  IF a > b THEN
    RETURN a;
  ELSE
    RETURN b;
    END IF;
END $$ LANGUAGE plpgsql;

REVOKE EXECUTE ON ROUTINE get_max FROM PUBLIC;

GRANT EXECUTE ON ROUTINE get_max TO luca;

REVOKE CONNECT ON DATABASE forumdb FROM PUBLIC;

REVOKE ALL ON DATABASE forumdb FROM public;

GRANT CONNECT, CREATE ON DATABASE forumdb TO luca;

ALTER TABLE categories OWNER TO luca;

ALTER ROUTINE get_max OWNER TO luca;

\dp categories

SELECT relname, relacl FROM pg_class WHERE relname = 'categories';

WITH acl AS (
  SELECT relname,
  (aclexplode(relacl)).grantor,
  (aclexplode(relacl)).grantee,
  (aclexplode(relacl)).privilege_type
  FROM pg_class
)
SELECT g.rolname AS grantee,acl.privilege_type AS permission,gg.rolname AS grantor
FROM acl
JOIN pg_roles g ON g.oid = acl.grantee
JOIN pg_roles gg ON gg.oid = acl.grantor
WHERE acl.relname = 'categories';

CREATE POLICY show_only_my_posts  ON posts
FOR SELECT
USING ( author = ( SELECT pk FROM users
WHERE username = CURRENT_ROLE ) );


ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY manage_only_my_posts ON posts
FOR ALL
USING ( author = ( SELECT pk FROM users
WHERE username = CURRENT_ROLE ) )
WITH CHECK ( author = ( SELECT pk FROM users
WHERE username = CURRENT_ROLE )
AND
last_edited_on + '1 day'::interval >=
CURRENT_TIMESTAMP );

EXPLAIN SELECT * FROM posts;

UPDATE posts SET last_edited_on = last_edited_on - '2 weeks'::interval;

\dp posts

ALTER TABLE posts DISABLE ROW LEVEL SECURITY;

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

SELECT name, setting, enumvals
FROM pg_settings
WHERE name = 'password_encryption';
