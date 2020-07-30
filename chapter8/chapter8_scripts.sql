  select * from tags;

  update tags set tag='orange' where pk=3;

  create table a_tags (
  pk integer not null primary key,
  tag text,
  parent integer);

  create or replace rule r_tags1
  as on INSERT to tags
  where NEW.tag ilike 'a%' DO ALSO
  insert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);

  insert into tags (tag) values ('apple');

  select * from tags;

  select * from a_tags;

  create table b_tags (
  pk integer not null primary key ,
  tag text,
  parent integer);

  create or replace rule r_tags2
  as on INSERT to tags
  where NEW.tag ilike 'b%'
  DO INSTEAD insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);

  insert into tags (tag) values ('banana');

  select * from tags;

  select * from b_tags ;

  create or replace rule r_tags3
  as on INSERT to tags
  where NEW.tag ilike 'c%'
  DO INSTEAD NOTHING;

  insert into tags (tag) values ('cedro');

  select pk,tag,parent,'tags' as tablename
  from tags
  union all
  select pk,tag,parent,'a_tags' as tablename
  from a_tags
  union all
  select pk,tag,parent,'b_tags' as tablename
  from b_tags
  order by tablename, tag;

  create table new_tags as select * from tags limit 0;

  alter table new_tags alter pk set not null ;

  alter table new_tags add constraint new_tags_pk primary key (pk);

  create table new_a_tags as select * from a_tags limit 0;

  alter table new_a_tags alter pk set not null ;

  alter table new_a_tags add constraint new_b_tags_pk primary key (pk);

  create table new_b_tags as select * from a_tags limit 0;

  alter table new_b_tags alter pk set not null ;

  alter table new_b_tags add constraint new_a_tags_pk primary key (pk);

  create or replace rule r_new_tags_insert_a as on INSERT to new_tags where NEW.tag ilike 'a%' DO ALSO insert into new_a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);

  create or replace rule r_new_tags_insert_b as on INSERT to new_tags where NEW.tag ilike 'b%' DO ALSO insert into new_b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);

  insert into new_tags values(1,'fruits',NULL);

  insert into new_tags values(2,'apple',1);

  insert into new_tags values(3,'orange',1);

  insert into new_tags values(4,'banana',1);

  select * from new_tags ;

  select * from new_a_tags ;

  select * from new_b_tags ;

  create or replace rule r_new_tags_delete_a as on delete to new_tags where OLD.tag ilike 'a%' DO ALSO delete from new_a_tags where pk=OLD.pk;

  create or replace rule r_new_tags_delete_b as on delete to new_tags where OLD.tag ilike 'b%' DO ALSO delete from new_b_tags where pk=OLD.pk;

  delete from new_tags where tag = 'apple';

  delete from new_tags where tag = 'banana';

  select * from new_tags ;

  select * from new_a_tags ;

  select * from new_b_tags ;

  create or replace function move_record (p_pk integer, p_tag text, p_parent integer,p_old_pk integer,p_old_tag text ) returns void language plpgsql as
  $$
  BEGIN
  if left(lower(p_tag),1) in ('a','b') THEN
  delete from new_tags where pk = p_old_pk;
  insert into new_tags values(p_pk,p_tag,p_parent);
  end if;
  END;
  $$;


  create or replace rule r_new_tags_update_a as on UPDATE to new_tags DO ALSO select move_record(NEW.pk,NEW.tag,NEW.parent,OLD.pk,OLD.tag);

  update new_tags set tag='apple' where tag='orange';

  select * from new_a_tags ;

  select * from new_tags ;

  update new_tags set tag='banana' where tag='apple';

  select * from new_tags ;

  select * from new_a_tags ;

  select * from new_b_tags ;

  create or replace rule r_tags1
  as on INSERT to tags
  where NEW.tag ilike 'a%' DO ALSO
  insert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);

  drop table if exists new_tags cascade;
  create table new_tags as select * from tags limit 0;
  a_tags;
  select * from new_tags ;
  select * from a_tags ;

  CREATE OR REPLACE FUNCTION f_tags() RETURNS trigger as
  $$
  BEGIN
  IF lower(substring(NEW.tag from 1 for 1)) = 'a' THEN
  insert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  END IF;
  RETURN NEW;
  END;
  $$
  LANGUAGE 'plpgsql';

  CREATE TRIGGER t_tags BEFORE INSERT on new_tags FOR EACH ROW EXECUTE PROCEDURE f_tags();

  insert into new_tags (pk,tag,parent) values (1,'fruits',NULL);

  insert into new_tags (pk,tag,parent) values (2,'apple',1);

  select * from new_tags ;

  select * from a_tags ;

  create or replace rule r_tags2
  as on INSERT to tags
  where NEW.tag ilike 'b%'
  DO INSTEAD insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);

  CREATE OR REPLACE FUNCTION f2_tags() RETURNS trigger as
  $$
  BEGIN
  IF lower(substring(NEW.tag from 1 for 1)) = 'b' THEN
  insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  RETURN NULL;
  END IF;
  RETURN NEW;
  END;
  $$
  LANGUAGE 'plpgsql';

  CREATE TRIGGER t2_tags BEFORE INSERT on new_tags FOR EACH ROW EXECUTE PROCEDURE f2_tags();

  insert into new_tags (pk,tag,parent) values (1,'fruits',NULL);

  insert into new_tags (pk,tag,parent) values (2,'apple',1);

  insert into new_tags (pk,tag,parent) values (3,'banana',1);

  select * from new_tags ;

  select * from a_tags ;

  select * from b_tags ;

  TRUNCATE new_tags;

  TRUNCATE a_tags;

  TRUNCATE b_tags;

  DROP TRIGGER t_tags ON new_tags CASCADE;

  DROP TRIGGER t2_tags ON new_tags CASCADE;

  CREATE OR REPLACE FUNCTION f3_tags() RETURNS trigger as
  $$
  BEGIN
  IF lower(substring(NEW.tag from 1 for 1)) = 'a' THEN
  insert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  RETURN NEW;
  ELSIF lower(substring(NEW.tag from 1 for 1)) = 'b' THEN
  insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  RETURN NULL;
  ELSE
  RETURN NEW;
  END IF;
  END;
  $$
  LANGUAGE 'plpgsql';

  CREATE TRIGGER t3_tags BEFORE INSERT on new_tags FOR EACH ROW EXECUTE PROCEDURE f3_tags();


  insert into new_tags (pk,tag,parent) values (1,'fruits',NULL);

  insert into new_tags (pk,tag,parent) values (2,'apple',1);

  insert into new_tags (pk,tag,parent) values (3,'banana',1);

  select * from new_tags ;

  select * from a_tags ;

  select * from b_tags ;


  CREATE OR REPLACE FUNCTION f3_tags() RETURNS trigger as
  $$
  BEGIN
  IF lower(substring(NEW.tag from 1 for 1)) = 'a' THEN
  nsert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  ELSIF lower(substring(NEW.tag from 1 for 1)) = 'b' THEN
  insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  RETURN NULL;
  END IF;
  RETURN NEW;
  END;
  $$
  LANGUAGE 'plpgsql';

  create or replace rule r_new_tags_insert_a as on INSERT to new_tags where NEW.tag ilike 'a%' DO ALSO insert into new_a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);


  create or replace rule r_new_tags_insert_b as on INSERT to new_tags where NEW.tag ilike 'b%' DO ALSO insert into new_b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);

  TRUNCATE new_tags;
  TRUNCATE a_tags;
  TRUNCATE b_tags;
  drop trigger t3_tags ON new_tags cascade;

  CREATE OR REPLACE FUNCTION fcopy_tags() RETURNS trigger as
  $$
  BEGIN
  IF TG_OP = 'INSERT' THEN
  IF lower(substring(NEW.tag from 1 for 1)) = 'a' THEN
  insert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  ELSIF lower(substring(NEW.tag from 1 for 1)) = 'b' THEN
  insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  END IF;
  RETURN NEW;
  END IF;
  END;
  $$
  LANGUAGE 'plpgsql';

  CREATE TRIGGER tcopy_tags_ins BEFORE INSERT on new_tags FOR EACH ROW EXECUTE PROCEDURE fcopy_tags();

  insert into new_tags (pk,tag,parent) values (1,'fruits',NULL);

  insert into new_tags (pk,tag,parent) values (2,'apple',1);

  insert into new_tags (pk,tag,parent) values (3,'banana',1);

  select * from a_tags;

  select * from b_tags;

  select * from new_tags;

  CREATE OR REPLACE FUNCTION fcopy_tags() RETURNS trigger as
  $$
  BEGIN
  IF TG_OP = 'INSERT' THEN
  IF lower(substring(NEW.tag from 1 for 1)) = 'a' THEN
  insert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  ELSIF lower(substring(NEW.tag from 1 for 1)) = 'b' THEN
  insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  END IF;
  RETURN NEW;
  END IF;
  IF TG_OP = 'DELETE' THEN
  IF lower(substring(OLD.tag from 1 for 1)) = 'a' THEN
  DELETE FROM a_tags WHERE pk = OLD.pk;
  ELSIF lower(substring(OLD.tag from 1 for 1)) = 'b' THEN
  DELETE FROM b_tags WHERE pk = OLD.pk;
  END IF;
  RETURN OLD;
  END IF;
  END;
  $$
  LANGUAGE 'plpgsql';


  CREATE TRIGGER tcopy_tags_del AFTER DELETE on new_tags FOR EACH ROW EXECUTE PROCEDURE fcopy_tags();


  delete from new_tags where pk=2;

  delete from new_tags where pk=3;

  select * from a_tags;

  select * from b_tags;

  select * from new_tags;

  DROP TRIGGER tcopy_tags_ins ON new_tags cascade;

  DROP TRIGGER tcopy_tags_del ON new_tags cascade;

  TRUNCATE new_tags;

  TRUNCATE a_tags;

  TRUNCATE b_tags;

  insert into new_tags (pk,tag,parent) values (1,'fruits',NULL);

  insert into new_tags (pk,tag,parent) values (2,'apple',1);

  insert into new_tags (pk,tag,parent) values (3,'banana',1);

  CREATE OR REPLACE FUNCTION fcopy_tags() RETURNS trigger as
  $$
  BEGIN
  IF TG_OP = 'INSERT' THEN
  IF lower(substring(NEW.tag from 1 for 1)) = 'a' THEN
  insert into a_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  ELSIF lower(substring(NEW.tag from 1 for 1)) = 'b' THEN
  insert into b_tags(pk,tag,parent)values (NEW.pk,NEW.tag,NEW.parent);
  END IF;
  RETURN NEW;
  END IF;
  IF TG_OP = 'DELETE' THEN
  IF lower(substring(OLD.tag from 1 for 1)) = 'a' THEN
  DELETE FROM a_tags WHERE pk = OLD.pk;
  ELSIF lower(substring(OLD.tag from 1 for 1)) = 'b' THEN
  DELETE FROM b_tags WHERE pk = OLD.pk;
  END IF;
  RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' THEN
  IF (lower(substring(OLD.tag from 1 for 1)) in( 'a','b') ) THEN
  DELETE FROM a_tags WHERE pk=OLD.pk;
  DELETE FROM b_tags WHERE pk=OLD.pk;
  DELETE FROM new_tags WHERE pk = OLD.pk;
  INSERT into new_tags(pk,tag,parent) values (NEW.pk,NEW.tag,NEW.parent);
  END IF;
  RETURN NEW;
  END IF;
  END;
  $$
  LANGUAGE 'plpgsql';

  CREATE TRIGGER tcopy_tags_ins
  BEFORE INSERT on new_tags FOR EACH ROW EXECUTE PROCEDURE fcopy_tags();
  CREATE TRIGGER tcopy_tags_del
  AFTER DELETE on new_tags FOR EACH ROW EXECUTE PROCEDURE fcopy_tags();
  CREATE TRIGGER tcopy_tags_upd
  AFTER UPDATE on new_tags FOR EACH ROW EXECUTE PROCEDURE fcopy_tags();

  select * from new_tags;

  select * from a_tags;

  select * from b_tags;

  update new_tags set tag='apricot' where pk=3;

  select * from a_tags;

  select * from new_tags;


  CREATE OR REPLACE FUNCTION
  f_avoid_alter_table()
  RETURNS EVENT_TRIGGER
  AS
  $code$
  DECLARE
  event_tuple record;
  BEGIN

  FOR event_tuple IN SELECT *
          FROM pg_event_trigger_ddl_commands()  LOOP
  IF event_tuple.command_tag = 'ALTER TABLE' AND event_tuple.object_type = 'table' THEN
  RAISE EXCEPTION 'Cannot execute an ALTER TABLE!';
  END IF;
  END LOOP;
  END
  $code$
  LANGUAGE plpgsql;

  CREATE EVENT TRIGGER tr_avoid_alter_table
  ON ddl_cpg_event_trigger_ddl_commandsommand_end EXECUTE FUNCTION f_avoid_alter_table();

  ALTER TABLE tags ADD COLUMN thumbs_up int DEFAULT 0;
