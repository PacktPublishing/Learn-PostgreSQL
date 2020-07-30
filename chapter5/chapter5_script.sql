select * from categories where pk > 12 order by title;

select * from categories where title like 'a%';

select * from categories where title like '%e';

select * from categories where upper(title) like 'A%';

select * from categories where title ilike 'A%';

select coalesce(NULL,'test');

select coalesce('orange','test');

\pset null (NULL)

select description,coalesce(description,'No description') from categories order by 1;

select coalesce(description,'No description') as description from categories order by 1;

select coalesce(description,'No description') as Description from categories order by 1;

select coalesce(description,'No description') as "Description" from categories order by 1;

select distinct coalesce(description,'No description') as description from categories order by 1;

select * from categories order by pk limit 1;

select * from categories order by pk limit 2;

select * from categories order by pk offset 1 limit 1;

create table new_categories as select * from categories limit 0;

\d new_categories

select * from categories where pk=10 or pk=11;

select * from categories where pk in (10,11);

select * from categories where not (pk=10 or pk=11);

select * from categories where pk not in (10,11);

insert into posts(title,content,author,category) values('my orange','my orange is the best orange in the world',1,11);
insert into posts(title,content,author,category) values('my apple','my apple is the best orange in the world',1,10);
insert into posts(title,content,author,category,reply_to) values('Re:my orange','No! It''s my orange the best orange in the world',2,11,2);
insert into posts(title,content,author,category) values('my tomato','my tomato is the best orange in the world',2,12);

select pk,title,content,author,category from posts;

select pk,title,content,author,category from posts where category in (select pk from categories where title ='orange');

select pk from categories where title ='orange')

select pk,title,content,author,category from posts where category not in (select pk from categories where title ='orange');

select pk,title,content,author,category from posts where exists (select 1 from categories where title ='orange' and posts.category=pk);

select pk,title,content,author,category from posts where not exists (select 1 from categories where title ='orange' and posts.category=pk);

select c.pk,c.title,p.pk,p.category,p.title from categories c,posts p;

select c.pk,c.title,p.pk,p.category,p.title from categories c CROSS JOIN posts p;

select c.pk,c.title,p.pk,p.category,p.title from categories c,posts p where c.pk=p.category;

select c.pk,c.title,p.pk,p.category,p.title from categories c inner join posts p on c.pk=p.category;

select p.pk,p.title,p.content,p.author,p.category from categories c inner join posts p on c.pk=p.category where c.title='orange'

select * from categories c where c.pk not in (select category from posts);

select * from categories c where not exists (select 1 from posts where category=c.pk);

select c.*,p.category from categories c left join posts p on p.category=c.pk;

select c.* from categories c left join posts p on p.category=c.pk where p.category is null;

select c.*,p.category,p.title from posts p right join categories c on c.pk=p.category;

insert into tags (tag,parent) values ('fruits',NULL);
insert into tags (tag,parent) values ('vegetables',NULL);
insert into j_posts_tags values (1,2),(1,3);

select * from tags;
select * from j_posts_tags ;

select jpt.*,t.*,p.title from j_posts_tags jpt
inner join tags t on jpt.tag_pk=t.pk
inner join posts p on jpt.post_pk = p.pk;



select jpt.*,t.*,p.title from j_posts_tags jpt full outer join tags t on jpt.tag_pk=t.pk full outer join posts p on jpt.post_pk = p.pk;

select jpt.*,t.*,p.title from j_posts_tags jpt
cross join tags t
cross join posts p ;

insert into posts (title,content,author,category) values ('my new orange','this my post on my new orange',1,11);

select distinct p1.title,p1.author,p1.category from posts p1 where p1.author=1;

select distinct p2.title,p2.author,p2.category from posts p2 where p2.author=2;

select distinct p2.title,p2.author,p2.category from posts p1,posts p2 where p1.category=p2.category and p1.author<>p2.author and p1.author=1 and p2.author=2;

select distinct p2.title,p2.author,p2.category from posts p1 inner join posts p2 on ( p1.category=p2.category and p1.author<>p2.author) where p1.author=1 and p2.author=2;

select category,count(*) from posts group by category;

select category,count(*) from posts group by category;

select category,count(*) from posts group by category having count(*) > 2;

select category,count(*) from posts group by 1 having count(*) > 2;

select category,count(*) as category_count from posts group by category;

select category,count(*) as category_count from posts group by category having count(*) > 2;

insert into tags (tag,parent) values ('apple',1);

select * from tags;

select * from categories;

select title from categories union select tag from tags order by title;

select title from categories union all select tag from tags order by title;

select * from tags;

select * from categories;

select title from categories except select tag from tags order by 1;

select title from categories intersect select tag from tags order by 1;

alter table j_posts_tags add constraint j_posts_tags_pkey primary key (tag_pk,post_pk);

select * from j_posts_tags ;

insert into j_posts_tags values(1,2);

insert into j_posts_tags values(1,2) ON CONFLICT DO NOTHING;

select * from j_posts_tags ;

insert into j_posts_tags values(1,2) ON CONFLICT (tag_pk,post_pk) DO UPDATE set tag_pk=excluded.tag_pk+1;

select * from j_posts_tags ;

insert into j_posts_tags values(1,2) returning *;


insert into j_posts_tags values (1,6) returning tag_pk;

update posts set title = 'my new apple' where pk = 3;

select * from categories order by pk;


select pk,title,category from posts order by pk;

drop table if exists t_posts;
create temp table t_posts as select * from posts;



update t_posts p
set title=p.title||' last updated '||current_date::text
where p.category in (select pk from categories c where c.title='apple');

select current_date;


select pk,title,category from t_posts order by pk;

update t_posts p set title=p.title||' last updated '||current_date::text
where exists (select 1 from categories c where c.pk=p.category and c.title='apple' limit 1);

update t_posts p
set title=p.title||' last updated '||current_date::text
from categories c
where c.pk=p.category and c.title='apple';

delete from t_posts p where exists (select 1 from categories c where c.pk=p.category and c.title='apple' limit 1) returning pk,title,category;

select pk,title,category from t_posts order by 1;

with posts_author_1 as
(select p.* from posts p
 inner join users u on p.author=u.pk
 where username='scotty')
select pk,title from posts_author_1;

select pk,title from
(select p.* from posts p inner join users u on p.author=u.pk where u.username='scotty') posts_author_1;


with posts_author_1 as materialized
(select p.* from posts p
inner join users u on p.author=u.pk
where username='scotty')
select pk,title from posts_author_1;


with posts_author_1 as not materialized
(select p.* from posts p
inner join users u on p.author=u.pk
where username='scotty')
select pk,title from posts_author_1;

drop table if exists t_posts;


create temp table t_posts as select * from posts;


create table delete_posts as select * from posts limit 0;


select pk,title,category from t_posts ;

select pk,title,category from delete_posts ;

with del_posts as (
delete from t_posts
where category in (select pk from categories where title ='apple')
returning *)
insert into delete_posts select * from del_posts;


select pk,title,category from t_posts ;

select pk,title,category from delete_posts ;

drop table if exists t_posts;

create temp table t_posts as select * from posts;

create table inserted_posts as select * from posts limit 0;


with ins_posts as ( insert into inserted_posts select * from t_posts returning pk) delete from t_posts where pk in (select pk from ins_posts);

select pk,title,category from t_posts ;

WITH RECURSIVE tags_tree AS (
 -- non recursive statment
SELECT tag, pk, 1 AS level
FROM tags WHERE parent IS NULL
UNION
-- recursive statement
SELECT tt.tag|| ' -> ' || ct.tag, ct.pk
, tt.level + 1
FROM tags ct
JOIN tags_tree tt ON tt.pk = ct.parent
)
SELECT level,tag FROM tags_tree
order by level;
