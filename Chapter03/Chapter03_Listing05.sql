-- Chapter 3 Listing 5
-- Inspecting a specific role

\x
SELECT
      rolname, rolcanlogin, rolconnlimit, rolpassword
     FROM pg_authid
WHERE rolname = 'luca';
