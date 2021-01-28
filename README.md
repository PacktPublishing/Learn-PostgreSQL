# Learn PostgreSQL

<a href="https://www.packtpub.com/product/learn-postgresql/9781838985288"><img src="https://static.packt-cdn.com/products/9781838985288/cover/smaller" alt="Learn PostgreSQL" height="256px" align="right"></a>



**Build and manage high-performance database solutions using PostgreSQL 12 and 13**

## What is this book about?
PostgreSQL is one of the fastest-growing open source object-relational database management systems (DBMS) in the world. As well as being easy to use, it’s scalable and highly efficient. In this book, you’ll explore PostgreSQL 12 and 13 and learn how to build database solutions using it. Complete with hands-on tutorials, this guide will teach you how to achieve the right database design required for a reliable environment.

This book covers the following exciting features:
* Understand how users and connections are managed by running a PostgreSQL instance
* Interact with transaction boundaries using server-side programming
* Identify bottlenecks to maintain your database efficiently
* Create and manage extensions to add new functionalities to your cluster
* Choose the best index type for each situation

If you feel this book is for you, get your [copy](https://www.amazon.com/dp/183898528X) today!

<a href="https://www.packtpub.com/?utm_source=github&utm_medium=banner&utm_campaign=GitHubBanner"><img src="https://raw.githubusercontent.com/PacktPublishing/GitHub/master/GitHub.png"
alt="https://www.packtpub.com/" border="5" /></a>

## Errata

It is regarding To get the most out of this book section.

**Page 5**

It is: All the SQL examples can be run using the psql program or using the GUI tool pdAdmin.

Should be: All the SQL examples can be run using the psql program or using the GUI tool pgAdmin.


## Book Outline

This Postgres book is for anyone interested in learning about the PostgreSQL database from scratch. Anyone looking to build robust data warehousing applications and scale the database for high-availability and performance using the latest features of PostgreSQL will also find this book useful. Although prior knowledge of PostgreSQL is not required, familiarity with databases is expected.


The book is divided into five main parts. The following is a list of the book chapters.

### Part 1

1) Introduction to PostgreSQL
2) Getting to know your cluster
3) Managing Users and Connections

### Part 2

4) Basic Statements
5) Advanced Statements
6) Window Functions
7) Server Side Programming
8) Triggers and Rules
9) Partitioning

### Part 3

10)	Users, Roles and Database Security
11)	Transactions, MVCC, WALs and Checkpoints
12)	Extending the database: the Extension ecosystem
13)	Indexes and Performance Optimization
14)	Logging and Auditing
15)	Backup and Restore
16)	Configuration and Monitoring

### Part 4

17) Physical Replication
18) Logical Replication

### Part 5

19) Usefult tools and useful extensions
20) Towards PostgreSQL 13



## Chapters Content

Every chapter will have the following main structure:
- a *What you will learn* bullet list that summarize what the reader will learn thru the chapter;
- a *What you need to know* bullet list that reminds the user basic knowledge **required** to fully understand the contents of the chapter;
- an *Abstract* that introduces the chapter content at glance;
- a *Conclusions* section that provides a summary of the chapter and focus on the main concepts;
- a *References* section with links to documentation, articles and external resources.


## Content of this repository

This repository contains ongoing stuff related to the book, including code examples.

### Naming conventions used in this repository

Every chapter has its own folder named after the chapter number, for instance `Chapter01` for the very first chapter.

In order to ease the execution of the code examples by readers, every chapter will have a set of source scripts that the reader can immediatly load into her database.

Every file is named after the its type, for example `.sql` for an SQL script or a collection of SQL statements.


### Pictures

Any picture will be named with the pattern `Chapter<CC>_picture<PP>.<type>` where:
- `CC` is the chapter number;
- `PP` is the picture number as listed within the chapter;
- `type` is a suffix related to the picture file type (e.g., `png` for a Portable Network Graphic image).

*Images could appear differently from the printed book due to graphical needs*.

### Command prompts

In the book code listings and examples, the command prompts are one of the two that follows:
- a `$` stands for an Unix shell prompt (like Bourne, Bash, Zsh);
- a `forumdb=>` stands for the `psql(1)` command prompt when an active connection to the database is opened.

As an example, the following is a command issued on the operating system:

```shell
$ sudo service postgresql restart
```

while the following is a query issued within an active database connection:

```sql
forumdb=> SELECT CURRENT_TIMESTAMP;
```

### Administrative/Superusers command prompts

Whenere there is the need to execute a command or a statement with administrative privileges, the command prompt will reflect it using a `#` sign as the end part of the command prompt. For example, the following is an SQL statement issued as PostgreSQL administrator:

```sql
forumdb=# SELECT pg_terminate_backend( 987 );
```

ùPlease note the presence of the `#` in the `forumdb=#` prompt, as opposed to the `>` sign in the normal user `forumdb=>` prompt.

In the case a command on the operating system must be run with superuser (`root`) privileges, the command will be run via `sudo(1)`, as in:

```sql
$ sudo initdb -D /postgres/12
```

and therefore in this case the command prompt will not change, rather the presence of the `sudo(1)` command indicates `root` privileges are required.

## Creating the example database

The book is built over an example database that implements an *online forum* storage. In order to be able to execute any example of any chapter, the reader has to initialize the forum database.

The scripts in the folder `setup`, executed in lexicographically order, implement the example database and setup the environment so that other examples can be run against the database.


### Software and Hardware List

| Chapter  | Software required                   | OS required                        |
| -------- | ------------------------------------| -----------------------------------|
| 1        | PostgreSQL 12 - 13                  | Linux OS / FreeBSD |


[We also provide a PDF file](https://static.packt-cdn.com/downloads/9781838985288_ColorImages.pdf)
that has color images of the screenshots/diagrams used in this book.


### Related products
- Mastering PostgreSQL 12 [[Packt]](https://www.packtpub.com/product/mastering-postgresql-12-third-edition/9781838988821) [[Amazon]](https://www.amazon.com/dp/1838988823)
- PostgreSQL 12 High Availability Cookbook - Third Edition [[Packt]](https://www.packtpub.com/product/postgresql-12-high-availability-cookbook-third-edition/9781838984854) [[Amazon]](https://www.amazon.com/dp/1838984852)
- PostgreSQL 11 Server Side Programming - Quick Start Guide [[Packt]](https://www.packtpub.com/product/postgresql-11-server-side-programming-quick-start-guide/9781789342222) [[Amazon]](https://www.amazon.com/PostgreSQL-Server-Programming-Quick-Start-ebook/dp/B07L1MP1F8/ref=sr_1_1?crid=2I7PGMZDCI9O0&dchild=1&keywords=postgresql+11+server+side+programming+quick+start+guide&qid=1605375687&sprefix=postgresql+11+server+%2Caps%2C278&sr=8-1)


## Get to Know the Authors
**Luca Ferrari**
has been passionate about computer science since the Commodore 64 era, and today holds a master's degree (with honors) and a Ph.D. from the University of Modena and Reggio Emilia. He has written several research papers, technical articles, and book chapters. In 2011, he was named an Adjunct Professor by Nipissing University. An avid Unix user, he is a strong advocate of open source, and in his free time, he collaborates with a few projects. He met PostgreSQL back in release 7.3; he was a founder and former president of the Italian PostgreSQL Community (ITPUG). He also talks regularly at technical conferences and events and delivers professional training.

**Enrico Pirozzi**
has been passionate about computer science since he was a 13-year-old, his first computer was a Commodore 64, and today he holds a master's degree from the University of Bologna. He has participated as a speaker at national and international conferences on PostgreSQL. He met PostgreSQL back in release 7.2, he was a co-founder of the first PostgreSQL Italian mailing list and the first Italian PostgreSQL website, and he talks regularly at technical conferences and events and delivers professional training. Right now, he is employed as a PostgreSQL database administrator at Nexteam (Zucchetti Group S.p.a.).


### Suggestions and Feedback
[Click here](https://docs.google.com/forms/d/e/1FAIpQLSdy7dATC6QmEL81FIUuymZ0Wy9vH1jHkvpY57OiMeKGqib_Ow/viewform) if you have any feedback or suggestions.


#### Errata
* Page 82 (Dropping databases, first paragraph): **to drop a table** _should be_ **to drop a database**
* Page 122 (Using FULL OUTER JOIN, point 2): **`j_tags_posts`** _should be_ **`j_posts_tags`**
* Page 152 (`LAST_VALUE` Window Function): the query `select category, row_number() over w, title, last_value(title) over w
from posts WINDOW w as (partition by category order by category) order by category;` should be *`select category, row_number () over w, title, last_value (title) over w from posts WINDOW w as (partition by category order by title) order by category;`*. For more information about this error, see the [issue #6](https://github.com/PacktPublishing/Learn-PostgreSQL/issues/6)
* Page 581 (Section 5, heading): **The PostegreSQL System** _should be_ **The PostgreSQL System**


##### About GNU Debian and Ubuntu Repositories

The installation examples in the chapter 1, with particular regard to the section *Installing PostgreSQL 12 on GNU/Linux Debian, Ubuntu and derivatives* refers to the adoption of PostgreSQL Global Development Groupd (*PGDG*) repositories, as specified at the first step in the example. 

Since PostgreSQL 10, both the GNU Debian and Ubuntu operating system families have renamed the *PostgreSQL Contrib* module removing the version number suffix, therefore the right package to install is `postgresql-contrib` instead of the one presented in the installation instruction in the above chapter, wrongly named `postgresql-contrib-12`.

The package `postgresql-contrib-12` is a virtual package that refers to `postgresql-12`, threfore to the whole server and not to the contrib module.
