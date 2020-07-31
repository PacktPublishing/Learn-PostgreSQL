-- load 1000 authors into the table
INSERT INTO users( username, gecos, email )
SELECT 'author-' || v,
      CASE v % 2
      WHEN 0 THEN 'Mr. '
      ELSE  'Mrs. '
      END
      || 'Author The Writer ' || v
      , 'author.' || v || '@email.com'
FROM generate_series( 1, 1000 ) v;


CREATE OR REPLACE FUNCTION f_load_data()
RETURNS INT
AS $CODE$
DECLARE
   author users%rowtype;
   tag    categories%rowtype;
   counter int;
   total   int;
BEGIN
   total := 0;

   FOR author IN SELECT * FROM users LOOP
       RAISE INFO 'User %', author.pk;

       FOR counter IN 1..5000 LOOP
           SELECT *
           INTO tag
           FROM categories
           ORDER BY random()
           LIMIT 1;

           --RAISE INFO '-> tag %', tag.pk;

           INSERT INTO posts( title, content, author, category, created_on )
           SELECT 'Problem #' || counter
                  , 'Blah Blah'
                  , author.pk
                  , tag.pk
                  , current_date - ( counter || ' days' )::interval;

           total := total + 1;
       END LOOP;


   END LOOP;

   RETURN total;
END
$CODE$
LANGUAGE plpgsql;
