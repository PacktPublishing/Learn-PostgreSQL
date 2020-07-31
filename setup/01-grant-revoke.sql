--
-- Users, grant and revokes
--
-- Learn PostgreSQL
--
-- book by
-- Luca Ferrari
-- Enrico Pirozzi


    -- this is a group
CREATE ROLE book_authors
       WITH NOLOGIN;

CREATE ROLE luca
    WITH LOGIN PASSWORD 'xxx'
    IN ROLE book_authors;

CREATE ROLE enrico
    WITH LOGIN PASSWORD 'xxx'
    IN ROLE book_authors;


    -- remove all permissions on a table
REVOKE ALL ON categories FROM PUBLIC;

    -- luca can read categories
GRANT SELECT ON categories TO luca;
