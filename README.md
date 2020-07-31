# Learn PostgreSQL

This repository is related to the Packt book **[Learn PostgreSQL](https://www.packtpub.com/data/learn-postgresql-12)**, authored by *[Luca Ferrari](https://fluca1978.github.io)* and *[Enrico Pirozzi](http://www.pgtraining.com/chi-siamo/enrico-pirozzi)*.

<center>
<a href="https://www.packtpub.com/data/learn-postgresql-12" target="_blank" >
<img src="https://www.packtpub.com/media/catalog/product/cache/4cdce5a811acc0d2926d7f857dceb83b/9/7/9781838985288-original_45.jpeg" alt="Learn PostgreSQL" />
</a>
</center>

# What is this book about?

The book is about [PostgreSQL](https://www.postgresql.org), the world most advanced open source database. In particular, the book focuses on PostgreSQL *versions 12 and 13*, respectively the latest production ready release and the upcoming new major release. However, the book will be a very good starting point even for versions greater than those, as well as many examples will run also on previous versions.

## Book Outline

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
- an *abstract* that introduces the chapter content at glance;
- a *conclusion* section that provides a summary of the chapter and focus on the main concepts;
- a *reference* section with links to documentation, articles and external resources.


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

Please note the presence of the `#` in the `forumdb=#` prompt, as opposed to the `>` sign in the normal user `forumdb=>` prompt.

In the case a command on the operating system must be run with superuser (`root`) privileges, the command will be run via `sudo(1)`, as in:

```sql
$ sudo initdb -D /postgres/12
```

and therefore in this case the command prompt will not change, rather the presence of the `sudo(1)` command indicates `root` privileges are required.

## Creating the example database

The book is built over an example database that implements an *online forum* storage. In order to be able to execute any example of any chapter, the reader has to initialize the forum database.

The scripts in the folder `setup`, executed in lexicographically order, implement the example database and setup the environment so that other examples can be run against the database.



