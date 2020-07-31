create table table_a (
pk integer not null primary key,
tag text,
parent integer);

create table table_b () inherits (table_a);

alter table table_b add constraint table_b_pk primary key(pk);

forumdb=# insert into table_a (pk,tag,parent) values (1,'fruits',0);

forumdb=# insert into table_b (pk,tag,parent) values (2,'orange',0);

select * from table_b ;

select * from only table_a ;

update table_a set tag='apple' where pk=2;

select * from table_b;

delete from table_a where pk=2;

select * from table_a;

select * from table_b;

drop table table_b;

drop table table_a cascade;

CREATE SEQUENCE part_tags_pk_seq;

CREATE TABLE part_tags (
   pk INTEGER NOT NULL DEFAULT nextval('part_tags_pk_seq') PRIMARY KEY,
   tag VARCHAR(255) NOT NULL,
   level INTEGER DEFAULT 0
);


CREATE TABLE part_tags_level_0 (
  CHECK(level = 0 )
) INHERITS (part_tags);

CREATE TABLE part_tags_level_1 (
  CHECK(level = 1 )
) INHERITS (part_tags);

CREATE TABLE part_tags_level_2 (
  CHECK(level = 2 )
) INHERITS (part_tags);

CREATE TABLE part_tags_level_3 (
  CHECK(level = 3 )
) INHERITS (part_tags);


select name,short_desc,extra_desc from pg_settings where name ='constraint_exclusion';

ALTER TABLE ONLY part_tags_level_0 add constraint part_tags_level_0_pk primary key (pk);
ALTER TABLE ONLY part_tags_level_1 add constraint part_tags_level_1_pk primary key (pk);
ALTER TABLE ONLY part_tags_level_2 add constraint part_tags_level_2_pk primary key (pk);
ALTER TABLE ONLY part_tags_level_3 add constraint part_tags_level_3_pk primary key (pk);

CREATE EXTENSION pg_trgm ;

CREATE INDEX part_tags_level_0_tag on part_tags_level_0 using GIN (tag gin_trgm_ops);
CREATE INDEX part_tags_level_1_tag on part_tags_level_1 using GIN (tag gin_trgm_ops);
CREATE INDEX part_tags_level_2_tag on part_tags_level_2 using GIN (tag gin_trgm_ops);
CREATE INDEX part_tags_level_3_tag on part_tags_level_3 using GIN (tag gin_trgm_ops);

CREATE OR REPLACE FUNCTION insert_part_tags () RETURNS TRIGGER as
$$
BEGIN
IF NEW.level = 0 THEN
   INSERT INTO part_tags_level_0 values (NEW.*);
ELSIF NEW.level = 1 THEN
   INSERT INTO part_tags_level_1 values (NEW.*);
ELSIF NEW.level = 2 THEN
   INSERT INTO part_tags_level_2 values (NEW.*);
ELSIF NEW.level = 3 THEN
   INSERT INTO part_tags_level_3 values (NEW.*);
ELSE
   RAISE EXCEPTION 'Error in part_tags, level out of range';
END IF;
RETURN NULL;
END;
$$
language 'plpgsql';

CREATE TRIGGER insert_part_tags_trigger BEFORE INSERT ON part_tags FOR EACH ROW EXECUTE PROCEDURE insert_part_tags();

forumdb=# insert into part_tags (tag,level) values ('vegetables',0);

forumdb=# insert into part_tags (tag,level) values ('fruits',0);

forumdb=# insert into part_tags (tag,level) values ('orange',1);

forumdb=# insert into part_tags (tag,level) values ('apple',1);

forumdb=# insert into part_tags (tag,level) values ('red apple',2);


select * from part_tags;

select * from only part_tags;

select * from only part_tags_level_0;

select * from only part_tags_level_1;

select * from only part_tags_level_2;

delete from part_tags where tag='apple';

 select * from part_tags;

update part_tags set tag='apple' where pk=8;

select * from part_tags;

select * from only part_tags_level_1;

update part_tags set level=1,tag='apple' where pk=5;

CREATE OR REPLACE FUNCTION update_part_tags() RETURNS TRIGGER AS
$$
BEGIN
 IF (NEW.level != OLD.level) THEN
     DELETE FROM part_tags where pk = OLD.PK;
     INSERT INTO part_tags values (NEW.*);
 END IF;
 RETURN NULL;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER update_part_tags_trigger BEFORE UPDATE ON part_tags_level_0 FOR EACH ROW EXECUTE PROCEDURE update_part_tags();
CREATE TRIGGER update_part_tags_trigger BEFORE UPDATE ON part_tags_level_1 FOR EACH ROW EXECUTE PROCEDURE update_part_tags();
CREATE TRIGGER update_part_tags_trigger BEFORE UPDATE ON part_tags_level_2 FOR EACH ROW EXECUTE PROCEDURE update_part_tags();
CREATE TRIGGER update_part_tags_trigger BEFORE UPDATE ON part_tags_level_3 FOR EACH ROW EXECUTE PROCEDURE update_part_tags();

forumdb=# update part_tags set level=1,tag='apple' where pk=5;

forumdb=# select * from part_tags;

DROP TABLE IF EXISTS part_tags cascade;

CREATE TABLE part_tags (
pk INTEGER NOT NULL DEFAULT nextval('part_tags_pk_seq') ,
level INTEGER NOT NULL DEFAULT 0,
tag VARCHAR (255) NOT NULL,
primary key (pk,level)
)
PARTITION BY LIST (level);

CREATE TABLE part_tags_level_0 PARTITION OF part_tags FOR VALUES IN (0);
CREATE TABLE part_tags_level_1 PARTITION OF part_tags FOR VALUES IN (1);
CREATE TABLE part_tags_level_2 PARTITION OF part_tags FOR VALUES IN (2);
CREATE TABLE part_tags_level_3 PARTITION OF part_tags FOR VALUES IN (3);

CREATE INDEX part_tags_tag on part_tags using GIN (tag gin_trgm_ops);

insert into part_tags (tag,level) values ('vegetables',0);
insert into part_tags (tag,level) values ('fruits',0);
insert into part_tags (tag,level) values ('orange',1);
insert into part_tags (tag,level) values ('apple',1);
insert into part_tags (tag,level) values ('red apple',2);

CREATE TABLE part_tags (
     pk INTEGER NOT NULL DEFAULT nextval('part_tags_pk_seq'),
     ins_date date not null default now()::date,
     tag VARCHAR (255) NOT NULL,
     level INTEGER NOT NULL DEFAULT 0,
     primary key (pk,ins_date)
)
PARTITION BY RANGE (ins_date);


CREATE TABLE part_tags_date_01_2020 PARTITION OF part_tags FOR VALUES FROM ('2020-01-01') TO ('2020-01-31');
CREATE TABLE part_tags_date_02_2020 PARTITION OF part_tags FOR VALUES FROM ('2020-02-01') TO ('2020-02-28');
CREATE TABLE part_tags_date_03_2020 PARTITION OF part_tags FOR VALUES FROM ('2020-03-01') TO ('2020-03-31');
CREATE TABLE part_tags_date_04_2020 PARTITION OF part_tags FOR VALUES FROM ('2020-04-01') TO ('2020-04-30')

CREATE INDEX part_tags_tag on part_tags using GIN (tag gin_trgm_ops);

insert into part_tags (tag,ins_date,level) values ('vegetables','2020-01-01',0);
insert into part_tags (tag,ins_date,level) values ('fruits','2020-01-01',0);
insert into part_tags (tag,ins_date,level) values ('orange','2020-02-01',1);
insert into part_tags (tag,ins_date,level) values ('apple','2020-03-01',1);
insert into part_tags (tag,ins_date,level) values ('red apple','2020-04-01',2);

select * from part_tags;

select * from part_tags_date_01_2020;
select * from part_tags_date_02_2020;
select * from part_tags_date_03_2020;
select * from part_tags_date_04_2020;

CREATE TABLE part_tags_date_05_2020 PARTITION OF part_tags FOR VALUES FROM ('2020-05-01') TO ('2020-05-30');

ALTER TABLE part_tags DETACH PARTITION part_tags_date_05_2020 ;

ALTER TABLE part_tags ATTACH PARTITION part_tags_already_exists FOR VALUES FROM ('1970-01-01') TO ('2019-12-31');
