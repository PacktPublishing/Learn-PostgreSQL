-- Chapter 3 Listing 6
-- Creating two groups to handle different permissions

CREATE ROLE forum_admins;

CREATE ROLE forum_stats;

GRANT ALL ON users TO forum_admins;

REVOKE ALL ON users FROM forum_stats;

GRANT SELECT (username, gecos) ON users TO forum_stats;


