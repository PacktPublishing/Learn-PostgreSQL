-- Chapter 3 Listing 4
-- Inspecting a specific role

\x
SELECT rolname, rolcanlogin, rolconnlimit, rolpassword
    FROM pg_roles
WHERE rolname = 'luca';
