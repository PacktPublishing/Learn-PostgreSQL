-- create 1000 users
INSERT INTO users( username, gecos, email )
SELECT 'user-' || v, 'Automatically generated user #' || v, 'author'|| v || '@learn-postgresql.org'
  FROM generate_series( 1, 1000 ) v;




-- generate 5000 post per author
-- this will create a table around 400 MB in size!
INSERT INTO posts( title,  author, category, editable )
SELECT 'Thread-' || v,  a.pk, v % 3 + 1, case v % 2 when 0 then true else false end
  FROM generate_series( 1, 5000 ) v, users a;
