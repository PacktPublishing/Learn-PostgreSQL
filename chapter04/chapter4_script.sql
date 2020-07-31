\c forumdb

 \c template1

create table dummytable (dummyfield integer not null primary key);

 \d

 create database dummydb;

 \d

 \c template1

 drop table dummytable;

 drop database dummydb ;

 create database forumdb2 template forumdb;

 \c forumdb2

 \d

 \x

 \l+ forumdb

 select pg_database_size('forumdb');

 select pg_size_pretty(pg_database_size('forumdb'));

 select * from pg_database where datname='forumdb';

 create database forumdb2;

 \c forumdb2

 \d users

 drop table users ;

 create table if not exists users (
    pk int GENERATED ALWAYS AS IDENTITY
   ,username text NOT NULL
   ,gecos text
   ,email text NOT NULL
   ,PRIMARY KEY( pk )
   ,UNIQUE ( username )
);

drop table if exists users;

drop table if exists users;

create temp table if not exists temp_users  (
    pk int GENERATED ALWAYS AS IDENTITY
   ,username text NOT NULL
   ,gecos text
   ,email text NOT NULL
   ,PRIMARY KEY( pk )
   ,UNIQUE ( username )
);

create temp table if not exists temp_users (
    pk int GENERATED ALWAYS AS IDENTITY
   ,username text NOT NULL
   ,gecos text
   ,email text NOT NULL
   ,PRIMARY KEY( pk )
   ,UNIQUE ( username )
) on commit drop;


\d temp_users;

commit work;

\d temp_users;

create unlogged table if not exists unlogged_users (
    pk int GENERATED ALWAYS AS IDENTITY
   ,username text NOT NULL
   ,gecos text
   ,email text NOT NULL
   ,PRIMARY KEY( pk )
   ,UNIQUE ( username )
);

select oid,relname from pg_class where relname='users';

insert into users (username,gecos,email) values ('myusername','mygecos','myemail');


select * from users;

select pk,username,gecos,email from users;


insert into users (username,gecos,email) values ('scotty','scotty_gecos','scotty_email');

select pk,username,gecos,email from users order by username;


 select pk,username,gecos,email from users order by 2;

insert into categories (title,description) values ('apple', 'fruits'), ('orange','fruits'),('lettuce','vegetable');

select * from categories;

 select * from categories where description ='vegetable';


select * from categories where description ='fruits' and title='orange';

select * from categories where description ='fruits' order by title desc;

select * from categories where description ='fruits' order by 2 desc;

insert into categories (title) values ('lemon');

select * from categories;

\pset null NULL

select * from categories;

select title,description from categories where description is null;

select title,description from categories where description is not null;

insert into categories (title,description) values ('apricot','fruits');

select * from categories order by description NULLS last;

select * from categories order by description;

select * from categories order by description NULLS first;

create temp table temp_categories as select * from categories;

select * from temp_categories ;

update temp_categories set title='peach' where pk = 14;

select * from temp_categories where pk=14;

update temp_categories set title = 'no title' where description = 'vegetable';

select * from temp_categories order by description;

delete from temp_categories where pk=10;

select * from temp_categories order by description;

delete from temp_categories where description is null;

delete from temp_categories ;

select * from temp_categories order by description;

insert into temp_categories select * from categories;

select * from temp_categories order by description;

truncate table temp_categories ;

select * from temp_categories order by description;
