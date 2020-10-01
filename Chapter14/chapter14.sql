SELECT CURRENT_DATE;

SELECT 1 + 1;

SELECT count(*) FROM posts;

PREPARE my_query( text ) AS SELECT * FROM categories WHERE title like $1;

EXECUTE my_query( 'PROGRAMMING%' );

CREATE EXTENSION pgaudit;

SET pgaudit.log TO 'write, ddl';

SELECT count(*) FROM categories;

INSERT INTO categories( description, title ) VALUES( 'Fake', 'A Malicious Category' );

SELECT count(*) FROM categories;

INSERT INTO categories( description, title ) VALUES( 'Fake2','Another Malicious Category' );

DO $$ BEGIN
EXECUTE 'TRUNCATE TABLE ' || 'tags CASCADE';
END $$;

CREATE ROLE auditor WITH NOLOGIN;

GRANT DELETE ON ALL TABLES IN SCHEMA public TO auditor;

GRANT INSERT ON posts TO auditor;

GRANT INSERT ON categories TO auditor;

SET pgaudit.role TO auditor;

INSERT INTO categories( title, description ) VALUES( 'PgAudit','Topics related to auditing in PostgreSQL' );

INSERT INTO tags( tag ) VALUES( 'pgaudit' );

DELETE FROM posts WHERE author NOT IN ( SELECT pk FROM users WHERE username NOT IN ( 'fluca1978', 'sscotty71' ) );
