#+title: Transactions, MVCC; WALs and Checkpoints
#+subtitle: Chapter 11

* Description :no_export:
This chapter presents you a very fundamental concept in PostgreSQL: the Write Ahead Log. You will learn why such log is so much important, how it deals with transactions and how you can interact with transactions from an SQL point of view.

The chapter will present you with the concept of transaction isolation, ACID rules and how the database can implement it. Then you will discover how the WAL can speed up the database work and, at the very same time, can protect it against crashes. You will understand what MVCC is why it is important.

Last, the chapter will provide an insight about checkpoints and related tunables.

** Main Headings
1.  	WAL and COMMITs
2.  	Data persistency
3.  	Transaction boundaries
4.  	Checkpoint



* DONE Abstract
  CLOSED: [2020-02-15 sab 16:20]

This chapter introduces you to transactions, a fundamental part in every enterprise level database system. PostgreSQL has a very rich and standard compliant transaction machinery that allows users to define exactly the transaction properties, including nested transactions.

PostgreSQL relies heavily on transactions to keep data consistent across concurrent connections and parallel activities, and thanks to the Write Ahead Logs (WALs) PostgreSQL does its best to keep the data safe and reliable. Moreover, PostgreSQL implements the Multi Version Concurrency Control (MVCC), a way to mantain high concurrency between transactions.

The chapter can be split into two parts: the first one is more practical and provides concrete examples on what transactions are, how to use them and how to understand MVCC. The second part is much more theoretical and explains how Write Ahead Logs work and how they allows PostgreSQL to recover even from a crash.

In this chapter you will learn:
- what transactions are;
- how to start, confirm or cancel a transaction and subtransactions;
- how to inspect MVCC data on every tuple;
- what is VACUUM and why it is so important;
- how to configure checkpoints.

In order to proceed, you need to know:
- how to issue SQL statements via psql;
- how to connect to the cluster and a database;
- how to check and modify the cluster configuration.

* DONE Transactions
  CLOSED: [2020-02-15 sab 11:01]

A transaction is an atomic unit of work that either succeed or fail.
Transaction are a key features of any database system and are what allows a database to implemente the ACID properties: Atomicity, Consistency, Isolability and Durability.
All together, the ACID properties means that the database must be able to handle unit of works on their whole (atomicity), store data in a permanent way (durability), without inter-mixed changes to the data (consistency) and in a way so that concurrent actions are executed as if they were alone (isolability).

You can think a transaction is a bunch of related statements that, on the end, will all succeed or all fail.
Transactions are everywhere in the database, and you have already used them even if you did not realize it: function calls, single statements and so on are executed in a transaction block. In other words, every action you issue against the database is executed within a transaction, even if you did not ask for it explicitly.
Thanks to this automatic wrapping of any statement into a transaction, the database engine can assure its data is always consistent and somehow protected by corruption, and we will see later in this chapter how PostgreSQL gurantees this.

Sometimes, however, you don't want the database to have control over your statements, rather you want to be able to define yourself the boundaries of transactions, and of course the database allows you to do it. For this reason, we call "implicit transactions" those transaction the database starts for you without need to ask, and "explicit transactions" those that you asks the database to start.

Before we can examine both type of transactions and compare them together, we need a little more background on transaction concepts.
First of all, any transaction is assigned an unique number, called the transaction identifier, or xid for short. The system automatically assigns the xid to newly created transactions, either implicit or explicit, and guarantees that no two transactions with the very same xid exist in the database.
The other main concept that we need to understand early in our transaction explaination is that PostgreSQL stores the xid that generates and or modified a certain tuple within the tuple itself. The reason will be clear when we will see how PostgreSQL handles transaction concurrency, so for the sake of this part let's just assume that every tuple in every table is automatically labeled with the xid of the transaction that created such tuple.

You can inspect what the current transaction is by means of the special function txid_current(), so for example if you ask your system a couple of simple statements like the current time, you will see that every SELECT is executed as a different transaction:

forumdb=> SELECT current_time, txid_current();
    current_time    | txid_current
--------------------+--------------
 16:51:35.042584+01 |         4813
(1 row)

forumdb=> SELECT current_time, txid_current();
    current_time    | txid_current
--------------------+--------------
 16:52:23.028124+01 |         4814
(1 row)


As you can see from the example above, the system has assigned two different transaction identifiers, respectively 4813 and 4814, to every statement, confirming that those statements have executed in different implicit transactions.

If you inspect the special hidden column xmin in a table, you can get information about what transaction did create such tuple. As an example:

forumdb=> SELECT xmin, * FROM categories;
 xmin | pk |         title         |           description
------+----+-----------------------+---------------------------------
  561 |  1 | DATABASE              | Database related discussions
  561 |  2 | UNIX                  | Unix and Linux discussions
  561 |  3 | PROGRAMMING LANGUAGES | All about programming languages
(3 rows)


As you can see, all the tuples in the above tables have been created by the very same transaction, the number 561.

              PostgreSQL manages a few different hidden columns, that you need to explicitly ask for when querying a table to be able to see. In particular, every table has an xmin, xmax, cmin and cmax hidden columns those use and aim will be explained later in this chapter.


Now that you know that every transaction is numbered, and that such number is used to label tuples in every table, we can move forward and see the difference between implicit and explicit transactions.


** DONE Implicit Transactions vs Explicit Transactions

Implicit transactions are those that you don't ask for, but that the system applies to your statements.
In other words, it is PostgreSQL that decides where the transaction starts and when it ends (transaction boundaries) and the rule is simple: every single statement is executed into its own different transaction.

In order to better understand this concept, let's insert a few records into a table:


forumdb=> INSERT INTO tags( tag ) VALUES( 'linux' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES( 'BSD' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES( 'Java' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES( 'Perl' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES( 'Raku' );
INSERT 0 1

and let's see the data that has been stored into the table:

forumdb=> SELECT xmin, * FROM tags;
 xmin | pk |  tag  | parent
------+----+-------+--------
 4824 |  9 | linux |
 4825 | 10 | BSD   |
 4826 | 11 | Java  |
 4827 | 12 | Perl  |
 4828 | 13 | Raku  |
(5 rows)


as you can see, the field xmin has a different (incremented) value for every single tuple inserted, that means a new transaction identifier (xid) has been assigned to the tuple or, more precisely, to the statement that executed the INSERT. This means that every single statement has executed in its own single-statement transaction.

              The fact that you are seeing xids incremented by a single unit is because on the machine used for the exampels there is no concurrency, that is no other database activity is going on. However, you cannot make any prediction about what the next xid will be in a live system with different concurrent conncetions and running statements.


What if we would have inserted all the above tags in one shot, being sure that if only one of them could not be stored for any reason, all of them will disappear? To this aim, we could use explicit transactions.
An explicit transaction is a group of statements with a well established transaction boundaries: you issue a BEGIN statement to mark the start of the transaction, and either a COMMIT or a ROLLBACK to end the transaction. If you issue a COMMIT the transaction is marked as succesful, therefore the modified data is stored permanently; on the other hand if you issue a ROLLBACK the transaction is considered failed and all changes disappear.

Let's see this in practice: add another bunch of tags, but this time within a single explicit transaction.

forumdb=> BEGIN;
BEGIN
forumdb=> INSERT INTO tags( tag ) VALUES( 'PHP' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES( 'C#' );
INSERT 0 1
forumdb=> COMMIT;
COMMIT


The only difference with respect to the previous bunch of insert statements is the explicit usage of BEGIN and COMMIT; since the transaction has committed, the data must be stored in the table:

forumdb=> SELECT xmin, * FROM tags;
 xmin | pk |  tag  | parent
------+----+-------+--------
 4824 |  9 | linux |
 4825 | 10 | BSD   |
 4826 | 11 | Java  |
 4827 | 12 | Perl  |
 4828 | 13 | Raku  |
 4829 | 14 | PHP   |
 4829 | 15 | C#    |
(7 rows)


As you can see, not only the data is stored as we expected, but both the last rows have the very same transaction identifier that is 4829. This means that PostgreSQL has somehow merged the two different statements into a single one.

Let's see what happens if a transaction ends with a ROLLBACK statement: the final result will be that the changes must not be stored. As an example, modify the tag value of every tuple to full uppercase:


forumdb=> BEGIN;
BEGIN
forumdb=> UPDATE tags SET tag = upper( tag );
UPDATE 7
forumdb=> SELECT tag FROM tags;
  tag
-------
 LINUX
 BSD
 JAVA
 PERL
 RAKU
 PHP
 C#
(7 rows)

forumdb=> ROLLBACK;
ROLLBACK
forumdb=> SELECT tag FROM tags;
  tag
-------
 linux
 BSD
 Java
 Perl
 Raku
 PHP
 C#
(7 rows)


We first changed to uppercase all the descriptions, and the SELECT statement proves the database has done the job, but in the end we changed our mind and issued a ROLLBACK. At this point, PostgreSQL throws away our changes and keeps the pre-transaction state, that is the description are not fully uppercase.

Therefore, we can summarize that every single statement is always executed as an implicit transaction, while if you need more control over what you need to atomically change, you need to open (BEGIN) and close (COMMIT or ROLLBACK) an explicit transaction.

Being in control of an explicit transaction does not mean that you will have always the choice about how to terminate it: sometimes PostgreSQL cannot allow you to COMMIT and consolidate a transaction because there are unrecoverable errors in it.
The most trivial example is when you do a syntax error:

forumdb=> BEGIN;
BEGIN
forumdb=> UPDATE tags SET tag = uppr( tag );
ERROR:  function uppr(text) does not exist
LINE 1: UPDATE tags SET tag = uppr( tag );
                              ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
forumdb=> COMMIT;
ROLLBACK

When PostgreSQL issues an error, it aborts the current transaction. Aborting a transaction means that, while the transaction is still open, it will not honor any following command nor COMMIT and will automatically issue a ROLLBACK as soon as you close the transaction. Therefore, even if you try to do work after a mistake, PostgreSQL will refuse to accept your statements:

forumdb=> BEGIN;
BEGIN
forumdb=> INSERT INTO tags( tag ) VALUES( 'C#' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES( PHP );
ERROR:  column "php" does not exist
LINE 1: INSERT INTO tags( tag ) VALUES( PHP );
                                        ^
forumdb=> INSERT INTO tags( tag ) VALUES( 'Ocaml' );
ERROR:  current transaction is aborted, commands ignored until end of transaction block
forumdb=> COMMIT;
ROLLBACK


Anyway, handling syntax errors or mispelled object names is not the only problem you can find when running a transaction, and after all it is somehow quite simple to fix, but you can find that your transaction cannot continue because there is some data constraint that prevents the statement to complete succesfully.
Imagine we don't allow any tag with a description shorter than two charaters:

forumdb=> ALTER TABLE tags
          ADD CONSTRAINT constraint_tag_length
          CHECK ( length( tag ) >= 2 );
ALTER TABLE

and that try to do an unit of work that insert the following:

forumdb=> BEGIN;
BEGIN
forumdb=> INSERT INTO tags( tag ) VALUES( 'C' );
ERROR:  new row for relation "tags" violates check constraint "constraint_tag_length"
DETAIL:  Failing row contains (17, C, null).
forumdb=> INSERT INTO tags( tag ) VALUES( 'C++' );
ERROR:  current transaction is aborted, commands ignored until end of transaction block
forumdb=> COMMIT;
ROLLBACK

As you have seen, as soon as a DML statement fails, PostgreSQL aborts the transaction and refuses to handle any other statement. The only way you have to clear the situation is by ending the explicit transaction, and no matter the way you end it (either a COMMIT or a ROLLBACK), PostgreSQL will throw away your changes rolling back the current transaction.

      In the above examples we have shown always a COMMIT ending of a transaction, but it is clear that when you are in doubt about your data, changes you have made or an unrecoverable error, you should issue a ROLLBACK. We have shown a COMMIT to make it clear that PostgreSQL will prevent "erronous" works to succesfully terminate.


So when are you supposed to use an explicit transaction? Every time you have a workload that must either succeed or fail, you have to wrap it into an explicit transaction. In particular, when loosing a part of the work can compromise the remaining data, that is a good advice to use a transaction. As an example, imagine an online shopping application: you surely do not want to charge your client before you have updated their cart and checked the availability of the products in the storage. On the other hand, as a client, I would not get a message saying that my order has been confirmed just to discover that the payment has failed for any reason. Therefore, since all the steps and actions have to be atomically performed (check the available for the products, update the cart, do the payment, confirm the order), an explicit transaction is what we need to keep our data consistent.


*** DONE Time Within Transactions

Transactions are time-discrete: the time does not change during a transaction.
You can easily see this by opening a transaction and querying several time the current time:


forumdb=> BEGIN;
BEGIN
forumdb=> SELECT CURRENT_TIME;
    current_time
--------------------
 14:51:50.730287+01
(1 row)

forumdb=> SELECT pg_sleep_for( '5 seconds' );
 pg_sleep_for
--------------

(1 row)

forumdb=> SELECT CURRENT_TIME;
    current_time
--------------------
 14:51:50.730287+01
(1 row)

forumdb=> ROLLBACK;






If you really need a time-continous source, you can use clock_timestamp():




forumdb=> BEGIN;
BEGIN
forumdb=> SELECT CURRENT_TIME, clock_timestamp()::time;
    current_time    | clock_timestamp
--------------------+-----------------
 14:53:17.479177+01 | 14:53:22.152435
(1 row)

forumdb=> SELECT pg_sleep_for( '5 seconds' );
 pg_sleep_for
--------------

(1 row)

forumdb=> SELECT CURRENT_TIME, clock_timestamp()::time;
    current_time    | clock_timestamp
--------------------+-----------------
 14:53:17.479177+01 | 14:53:33.022884


forumdb=> ROLLBACK;



** DONE More about Transaction Identifiers: the XID Wraparound Problem
   CLOSED: [2020-02-10 lun 17:32]

PostgreSQL does not allow in any case two transaction to share the same xid.
However, being an automatically incremented counter, the xid will sooner or later do a wrap-around, that means it will start counting over. This is known as the "xid wraparound problem" and PostgreSQL does a lot of work to prevent this to happen, as you will see later, but in the case the database is near the wraparound PostgreSQL will start claiming it in the logs with messages like:




WARNING:  database "forumdb" must be vacuumed within 177009986 transactions
HINT:  To avoid a database shutdown, execute a database-wide VACUUM in "forumdb".


If you read carefully the warning message, you will see that the system is talking about a shutdown: in the case the database undergoes a xid wraparound data could be lost, so in order to prevent this the system will automatically shutdown if the xid wraparoung is approaching.
There is, however, a way to avoid this automatic shutdown by forcing a cleanup by means of running VACUUM. As you will see later in this chapter, one of the capabilities of VACUUM is to freeze old tuples so to prevent the side effects of the xid wraparound, and therefore allowing the continuity of the database service.

But what are the effects of the xid wraparound?
In order to understand such problems, we have to remember that every transaction is assigned an unique xid and that the next assignable xid is obtained by incrementing the last assigned one by a single unit. 
This means that a transaction with an higher xid has started later than a transaction with a lower xid. In other words, a higher xid means the transaction is in the near future with regard to a transaction with a lower xid. And since the xid is stored along every tuple, a tuple with an higher xmin has been created later than a tuple with a lower xmin.
But when the xid overflows, and therefore restarts its numbering from low numbers, transaction started later will appear with lower xid than already running transactions, and therefore they will appear suddenly in the past. As a consequence, tuples with lower transaction xid could become also in the past, instead of being in the future after the overflow, and therefore there will be a mismatch of the temporal workflow and tuple storage.

To avoid the xid wraparound, PostgreSQL implements a couple of tricks. First of all, the xid counter does not start from zero, but from the value 3. Values before 3 are reserved for internal use and no one transaction is allowed to store such a xid. Second, every tuple is enhanced with a status bit that indicates if the tuple has been frozen or not: once a tuple has been frozen, its xmin must be always considered in the past, even if the value is greater than the current one.
Therefore, as the xid overflow is approaching, VACUUM performs a wide freeze execution marking all the tuple in the past as frozen, so that even if the xid restart its counting from lower numbers, the tuple already in the database will appear always in the past.

       In older PostgreSQL version the VACUUM was literally removing the xmin value of the tuples to freeze substituting its value with the special value 2, that being lower than the minimum usable value of 3, was indicating that the tuple was in the past. However, when a forensic analysis is required, having the original xmin is valuable, and therefore PostgreSQL now uses a status bit to indicate if the tuple has been frozen.

*** DONE Virtual and Real Transaction Identifiers

Being such an important resource, PostgreSQL is smart enough to avoid wasting transaction identifier numbers. In particular, when a transaction is initiated, the cluster uses a "virtual xid", something that  works like a xid but is not obtained from the transaction identifier counter. In this way, every transaction does not consume a xid number from the very beginning. Once the transaction has done some work that involves data manipulation and changes, the virtual xid is transformed in a "real" xid, that is one obtained from the xid counter. Thanks to this extra work, PostgreSQL does not waste trasanction identifiers for those transactions that do not strictly require a strong identification. For example, there is no need to waste a xid for a transaction block like the following:

forumdb=> BEGIN;
BEGIN
forumdb=> ROLLBACK;
ROLLBACK

Since the above transaction does nothing at all, why should PostgreSQL involve all the xid machinery? There is no reason to use a xid, that will not be attached to any tuple in database and therefore will not interfere with any active snapshot.

There is, however, an important thing to note: the usage of the function txid_current() always materializes a xid even if the transaction has not got one yet. For that reason, PostgreSQL provides another introspection function named txid_current_if_assigned(), that returns NULL if the transaction is still in the "virtual xid" phase.
It is important to note that PostgreSQL will not assign a real xid unless the transaction has manipulated some data, and this can be easily proved with a workflow like the following one:

forumdb=> BEGIN;
BEGIN
forumdb=> SELECT txid_current_if_assigned();
 txid_current_if_assigned
--------------------------

(1 row)

forumdb=> SELECT count(*) FROM tags;
 count
-------
     7
(1 row)

forumdb=> SELECT txid_current_if_assigned();
 txid_current_if_assigned
--------------------------

(1 row)

forumdb=> UPDATE tags SET tag = upper( tag );
UPDATE 7
forumdb=> SELECT txid_current_if_assigned();
 txid_current_if_assigned
--------------------------
                     4837
(1 row)

forumdb=> SELECT txid_current();
 txid_current
--------------
         4837
(1 row)

forumdb=> ROLLBACK;
ROLLBACK
forumdb=>

In the beginning of the transaction there is no xid assigned, and in fact txid_current_if_assigned() returns NULL. Een after a data read (i.e., SELECT) the xid has not been assigned. However, as soon as the transaction performs some write activity (e.g., an UPDATE), the xid is assigned and the result of both txid_current_if_assigned() and txid_current() is the same.



** DONE Transaction Concurrency and MVCC
   CLOSED: [2020-02-10 lun 18:26]

What happens if two transactions, either implicit or explicit, try to perform conflicting changes over the same amount of data? PostgreSQL must ensure the data is always consistent, and therefore it must have a way to "lock" (i.e., block and protect) data subject to conflicting changes.
Locks are an heavy mechanism that limits the concurrency of the system: the more locks you have, the more your transactions are going to wait to acquire the lock. To mitigate this problem, PostgreSQL implements the Multi Version Concurrency Control (MVCC), a well known technique used in enterprise level databases.

MVCC dictates that, instead of modifying an existing tuple within the database, the system has to replicate such tuple, apply the changes and invalidate the original one. You can think of this as a Copy-On-Write mechanism used in operating file systems like ZFS.

To better understand what this mean, let's assume the categories table has three tuples, and that we update one of them, to alter its description. What happens is that a new tuple, derived from the one we are going to apply the UPDATE, is inserted into the table, and the original one is invalidated.



     Figure 11.1 - Effects of changing an existing tuple in a table: a new tuple is created and the previous one is invalidated.


Why is PostgreSQL and MVCC dealing with this extra work instead of doing an on-place update of the tuple?
The reason is that in this way the database can cope with multi versions of the same tuple, and every version is valid within a specific time window. This means that less locks are required to modify the data, since the database is able to handle multi versions of the same data at the same time and different transactions are going to see potentially different values.

For MVCC to work properly, PostgreSQL must handle the concept of snapshots: a snapshot indicate the time window a certain transaction is allowed to perceive data. A snapshot is, at its bare meaning, the range of transaction xids that define the boundaries of data available to current transaction: every row in the database labeled with a xid between such range will be perceivable and usable by the current transaction. In other words, every transaction "sees" a dedicated subset of all the available data in the database.

The special function txid_current_snapshot() returns the minimum and maximum transaction identifiers that define the current transaction time boundaries. It becomes quite easy to demonstrate the concept with a couple of parallel sessions.
In the first session, let's run an explicit transaction, extract the identifier and the snapshot for future reference, and perform an operation:


-- session 1
forumdb=> BEGIN;
BEGIN
forumdb=> SELECT txid_current(), txid_current_snapshot();
 txid_current | txid_current_snapshot  
--------------+------------------------
   4928 | 4928:4928:
(1 row)

forumdb=> UPDATE tags SET tag = lower( tag );
UPDATE 5


As you can see, the transaction is number 4928 and its snapshot is bounded to itself, meaning that the transaction will see everything has been already consolidated on the database.
Now let's pause for a moment, and open another session to the same database: perform a single INSERT statement that is wrapped into an implicite transaction and get back the information about its xid.


forumdb=> INSERT INTO tags( tag ) VALUES( 'KDE' ) RETURNING txid_current();
 txid_current 
--------------
   4929
(1 row)


The single-shot transaction has been assigned xid 4929, that is of course the very next xid available after the former explicit transaction (the system is running no other concurrent transactions to make it simpler to follow the numbering).
Get back the first session and inspect again the information about the transaction snapshot:


-- session 1
forumdb=> SELECT txid_current(), txid_current_snapshot();
 txid_current | txid_current_snapshot  
--------------+------------------------
   4928 | 4928:4930:
(1 row)


This time the transaction has grown its snapshot from itself to the transaction 4930, that has not yet been started (txi_current_snapshot() reports its upper bound as non-inclusive).
In other words, the current transaction now sees data consolidated even from a transaction began after it, the 4929. This can be even more explicit if the transaction queries the table:


-- session 1 
forumdb=> SELECT xmin, tag FROM tags;
    xmin    |  tag  
------------+-------
 4928 | linux
 4928 | bsd
 4928 | java
 4928 | perl
 4928 | raku
 4929 | KDE
(6 rows)


As you can see, all the tuples but the last have been generated by the current transaction, and the last has been generated by xid 4929.
But the above is just a part of the story: while the first transaction is still uncompleted, let's inspect the same table from another parallel session:



forumdb=> SELECT xmin, tag FROM tags;
    xmin    |  tag  
------------+-------
 4922 | linux
 4923 | BSD
 4924 | Java
 4925 | Perl
 4926 | Raku
 4929 | KDE
(6 rows)

All but the last tuple have different descriptions and, most notably, a different value of xmin from what the transaction 4928 is seeing. What does it means? It means that while the table has undergone an almost full rewrite of every tuple (an UPDATE on all but the last tuples), other concurrent transactions can still get access to the data in the table without having been blocked by a lock.
This is the essence of the MVCC: every transaction perceives a different view over the storage, and the view is valid depending on the time window (snapshot) associated to such transaction.

Sooner or later, the data on the storage has to be consolidated, and therefore when the transaction 4928 completes COMMIT-ing its work, the data on the table will become the truth that every transaction from there on will perceive.

-- session 1
forumdb=> COMMIT;
COMMIT

-- out from the transaction now
-- we all see consolidated data
forumdb=> SELECT xmin, tag FROM tags;
    xmin    |  tag  
------------+-------
 4928 | linux
 4928 | bsd
 4928 | java
 4928 | perl
 4928 | raku
 4929 | KDE
(6 rows)


MVCC does not prevent always the usage of locks: if two or more concurrent transaction starts manipulating the same set of data, the system has to apply ordered changes, and therefore must force a lock on every concurrent transaction so that only one can proceed.
It is quite simple to prove this with two parallel session similar to the above one:

-- session 1 
BEGIN
forumdb=> SELECT txid_current(), txid_current_snapshot();
 txid_current | txid_current_snapshot  
--------------+------------------------
   4930 | 4930:4930:
(1 row)

forumdb=> UPDATE tags SET tag = upper( tag );
UPDATE 6


and in the meantime in another session

-- session 2
forumdb=> BEGIN;
BEGIN
forumdb=> SELECT txid_current(), txid_current_snapshot();
 txid_current | txid_current_snapshot  
--------------+------------------------
   4931 | 4930:4930:
(1 row)

forumdb=> UPDATE tags SET tag = lower( tag );
-- BLOCKED!!!!

The transaction 4931 is locked because PostgreSQL cannot decide which data manipulation to apply. On one hand, transaction 4930 is applying an uppercase to all the tags, but at the same time transaction 4931 is applying a lowercase to the very same data. Since the two changes conflicts, and the final result (i.e., the result that will be consolidated on the database) depends on the exact order on which changes will be applied (and in particular on the last one applied), PostgreSQL cannot allow both transaction to proceed. Therefore, since 4930 has applied the changes before the 4931, the latter is suspended waiting for the transaction 4930 to complete either with success or failure. As soon as you end the first transaction, the second one will be unblocked (showing the message status for the UPDATE statement):

-- session 1
forumdb=> COMMIT;
COMMIT


-- session 2
UPDATE 6
-- unblocked, can proceed further ...
forumdb=>



Therefore, MVCC is not a silver bullet against lock usage, but allows for a better concurrency in the overall usage of the database.

From the above description, it should be clear that MVCC comes at a cost: since the system has to mantain different tuple versions depending on the active transactions and their snapshots, the storage will literally grow over the effective size of consolidated data.
To prevent this problem, a specific tool named VACUUM, along with its background running brother autovacuum, is in charge to scan tables (and indexes) for tuple versions that can be throw away reclaiming therefore storage space. But when is a tuple version elegible for being destroyed by VACUUM? When there are no more any transaction referencing the tuple xid (i.e., xmin), that is when the tuple is no more consolidated.


* DONE Transaction Isolation Levels

In a concurrent system you could encounter three different problems:

- dirty reads

- unrepeatable reads

- phantom reads

A dirty read happens when the database is allowing a transaction to see work-in-progress data from other not yet finished transactions. In other words, data that has not been consolidated is visible to other transactions. No one production ready database allows that, and PostgreSQL is no exception: you are assured your transaction will only perceive the data that has been consolidated and, in order to be consolidated, the transactions that created such data must be completed.

An unrepeatable read happens when the same query, within the same transaction, executed multiple times, perceive a different set of data. This essentially means that the data has changed between two sequential execution of the same query into the same transaction. PostgreSQL does not allow this kind of problem by means of the snapshots: every transaction can perceive the snapshot of the data available depending on a specific transaction boundaries.

A phantom read happens is somehow similar to the unrepeatable read, but what changes between sequential execution of the same query is the size of the result set. This means that the data has not changed, but new data has been "appended" to the last execution result set.


The SQL standard provides four isolation levels that a transaction can adopt to prevent any of the above problems:


- Read Uncommitted

- Read Committed

- Repeatable Read

- Serializable

Each level provides an increasing isolation upon the previous level, so for example Read Committed enhances the behavior of Read Uncommited, Repeatable Read enhances Read Committed (and Read Uncommitted), and Serializable enhances all of the previous levels.

PostgreSQL does not support all the above levels, as you will see in detail in the following subsections.
You can always specify the isolation level you desire for the explicit transaction at the transaction beginning; every isolation level has the very same name as reported in the above list, so for example the following begins a transaction in Read Committed mode:

forumdb=> BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN

You can omit the optional keyword TRANSACTION, even if in our opinion this improves readability.
It is also possible to explicitly set the transaction isolation level by means of a SET TRANSACTION statement, as an example the following snippet produces the same effects of the one above:

forumdb=> BEGIN;
BEGIN
forumdb=> SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET



It is important to note that the transaction isolation level cannot be changed once the transaction has started.
In order to have effects, the SET TRANSACTION must be the very first statement executed into a transaction block. Every subsequent SET TRANSACTION that change the already set isolation level will produce a failure and put the transaction in an aborting state, otherwise if the subsequent SET TRANSACTION do not change the isolation level they will have no effect and will produce no error.
To better understand this case, the following is an example of wrong workflow where the isolation level is changed after the transaction has already executed a statement, even if not changing any data:


forumdb=> BEGIN;
BEGIN
forumdb=> SELECT count(*) FROM tags;
 count
-------
     7
(1 row)

-- a query has been executed, the SET TRANSACTION
-- is not anymore the very first command
forumdb=> SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
ERROR:  SET TRANSACTION ISOLATION LEVEL must be called before any query







** DONE Read Uncommitted

The Read Uncommitted isolation level allows a transaction to be subjected to the dirty reads problem, that means it can perceive not consolidated data from other not completed transactions.

PostgreSQL does not support this isolation level. Period.

You can set the isolation level explicitly, but PostgreSQL will ignore your wills and set it silently to the most robust Read Committed one.


** DONE Read Committed

The isolation level READ COMMITTED is the default one used by PostgreSQL: if you don't set a level every transaction (implicit or explicit) will have this isolation level.

This level prevents the dirty reads and allows the current transaction to see all the already consolidated data at the time every single statement in the transaction is executed. We have alrady seen this behavior in practice in the snapshot example.

** DONE Repeatable Read

The REPEATABLE READ isolation level imposes that every statement in the transaction will perceive only data already consolidated at the time the transaction started, or better at the time the first statement of the transacction is started.

** DONE Serializable

The SERIALIZABLE isolation level imposes the REPEATABLE READ level and assures that two concurrent transacctions will be able to succesfully complete only if the end result would have been the same of the two transaction running in a sequential order.

In other words, if two (or more) transaction are in SERIALIZABLE isolation level and try to modify the same subset of data in an conflicting way, PostgreSQL will ensure that only one transaction can complete and will make the other to fail.
Let's see this in action by creating a first transaction and modify a subset of data.


-- session 1
forumdb=> BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN
forumdb=> UPDATE tags SET tag = lower( tag );
UPDATE 7


To simulate concurrency, let's pause this transaction and open a new one in another session applying other changes to the same set of data:


-- session 2
forumdb=> BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN
forumdb=> UPDATE tags SET tag = '[' || tag || ']';
-- blocked


Since the manipulated set of data is the same, the second transaction is locked as we saw in other examples before. Now assume the first transaction completes succesfully:


-- session 1
forumdb=> COMMIT;
COMMIT


PostgreSQL realizes that making also the other transaction able to proceed would break the SERIALIZABLE promise, because applying the transaction sequentially would produce different results depending on their order. Therefore, as soon as the first transaction commits, the second one is automatically aborted with a serializable error:


-- session 2
forumdb=> UPDATE tags SET tag = '[' || tag || ']';
ERROR:  could not serialize access due to concurrent update


What happens if the transaction manipulate data that apparently is not related?
One transaction may fail again, in fact let's modify one single tuple from one transaction:


-- session 1
forumdb=> BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN
forumdb=> UPDATE tags SET tag = '{' || tag || '}' WHERE tag = 'java';
UPDATE 1


and in the meantime modify exactly one other transaction from another session:


-- session 2
forumdb=> BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN
forumdb=> UPDATE tags SET tag = '[' || tag || ']' WHERE tag = 'perl';
UPDATE 1


This time there is no locking of the second transaction because the touched tuples are completely different. However, as soon as the first transaction executes a COMMIT, the second transaction is no more able to COMMIT by itself:


-- session 2 (assume session 1 has issued COMMIT)
forumdb=> COMMIT;
ERROR:  could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot, during commit attempt.
HINT:  The transaction might succeed if retried.


This is a quite common problem when using serializable transactions: the application or the user must be ready to execute over and over his transaction because PostgreSQL could make it fail due to the serializability of the workflows.




* DONE More on MVCC: xmin and friends

xmin is only a part of the story of managing MVCC. PostgreSQL labels every tuple in the database with four different fields named xmin (already descripted), xmax, cmin and cmax. Similarly to what you have learnt about xmin, in order to make those fields to appear in a query result you need to explicitly reference them.
For instance:



forumdb=> SELECT xmin, xmax, cmin, cmax, * FROM tags ORDER BY tag;
 xmin | xmax | cmin | cmax | pk | tag  | parent
------+------+------+------+----+------+--------
 4854 |    0 |    0 |    0 | 24 | c++  |
 4853 |    0 |    0 |    0 | 23 | java |
 4852 |    0 |    0 |    0 | 22 | perl |
 4855 |    0 |    0 |    0 | 25 | unix |
(4 rows)


The meaning of xmin has been already described in a previous section: it indicates the transaction identifier of the transaction that created the tuple.
The xmax field, on the other hand, indicates the xid of the transaction that invalidated the tuple, for example because it has deleted the data.
The cmin and cmax fields indicate respectively the command identifiers that created and invalidated the tuple within the same transaction (PostgreSQL numbers every statement within a transaction starting from zero).

Why is it important to keep track of the statement identifier (cmin, cmax)? Since the lowest isolation level that PostgreSQL applies is Read Committed, every single statement (i.e., command) in a transaction must see the snapshot of the data consolidated when the command is started.
You can see the usage of cmin and cmax within the same transaction with the following example. First of all, we begin an explicit transaction, then we insert a couple of tuples with two different INSERT statements; this means that the created tuples will have a different cmin.



forumdb=> BEGIN;
BEGIN


forumdb=> SELECT xmin, xmax, cmin, cmax, tag, txid_current()
          FROM tags ORDER BY tag;

 xmin | xmax | cmin | cmax | tag  | txid_current
------+------+------+------+------+--------------
 4854 |    0 |    0 |    0 | c++  |         4856
 4853 |    0 |    0 |    0 | java |         4856
 4852 |    0 |    0 |    0 | perl |         4856
 4855 |    0 |    0 |    0 | unix |         4856
(4 rows)

-- first writing command (number 0)
forumdb=> INSERT INTO tags( tag ) values( 'raku' );
INSERT 0 1

-- second writing command (number 1)
forumdb=> INSERT INTO tags( tag ) values( 'lua' );
INSERT 0 1

-- fourth command within transaction (number 3)
forumdb=> SELECT xmin, xmax, cmin, cmax, tag, txid_current()
          FROM tags ORDER BY tag;

 xmin | xmax | cmin | cmax | tag  | txid_current
------+------+------+------+------+--------------
 4854 |    0 |    0 |    0 | c++  |         4856
 4853 |    0 |    0 |    0 | java |         4856
 4856 |    0 |    1 |    1 | lua  |         4856
 4852 |    0 |    0 |    0 | perl |         4856
 4856 |    0 |    0 |    0 | raku |         4856
 4855 |    0 |    0 |    0 | unix |         4856
(6 rows)



So far, within the same transaction, the two new tuples inserted have a xmin that is the same as txid_current(), obviously those tuples have been created by the same transaction. However, please note that the second tuple, being in the second writing command, has a cmin that holds 1 (command counting starts from zero).
Therefore, PostgreSQL knows every tuple when it has been created by means of transaction and command within that transaction.
Let's move on with our transaction: declare a cursor that holds a query against the tags table and delete all tuples but two.

forumdb=> DECLARE tag_cursor CURSOR FOR SELECT xmin, xmax, cmin, cmax, tag, txid_current() FROM tags ORDER BY tag;
DECLARE CURSOR

forumdb=> DELETE FROM tags WHERE tag NOT IN ( 'perl', 'raku' );
DELETE 4

forumdb=> SELECT xmin, xmax, cmin, cmax, tag, txid_current()
          FROM tags ORDER BY tag;
 xmin | xmax | cmin | cmax | tag  | txid_current
------+------+------+------+------+--------------
 4852 |    0 |    0 |    0 | perl |         4856
 4856 |    0 |    0 |    0 | raku |         4856
(2 rows)


As you can see, the table now holds only two tuples, and this is the expected behavior after all.
But the cursor has started before the DELETE, and therefore it must perceive the data as it was before the DELETE. In fact, if we ask to the cursor what data it can obtain, we see that it returns all the tuples as they were before the DELETE:



forumdb=> FETCH ALL FROM tag_cursor;
 xmin | xmax | cmin | cmax | tag  | txid_current
------+------+------+------+------+--------------
 4854 | 4856 |    2 |    2 | c++  |         4856
 4853 | 4856 |    2 |    2 | java |         4856
 4856 | 4856 |    0 |    0 | lua  |         4856
 4852 |    0 |    0 |    0 | perl |         4856
 4856 |    0 |    0 |    0 | raku |         4856
 4855 | 4856 |    2 |    2 | unix |         4856
(6 rows)


There is an important thing to note: every deleted tuple has a value into xmax that holds the current transaction identifier (4856), meaning that this very own transaction has deleted the tuples. However the transaction has not committed yet, therefore the tuples are still there but are marked to be tied to the snapshot than ends in 4856. Moreover, the deleted tuples have a cmax that holds the value 2, that means that the tuples have been deleted from the third writing command in the transaction.
Since the cursor has been defined before such statement, it is able to "see" the tuples as they were, even if PostgreSQL knows exactly from which point in time they have disappeared.


      Readers may have noted that cmin and cmax holds the same value, and that is due to the fact that the fields are overlapping the very same storage.











* DONE Savepoints

A savepoint is a way to split a transaction into smaller blocks that can be rolled back indipendently from each other.
Thanks to savepoints, you can handle a big transaction (i.e., one transaction with multiple statements) into smaller chunks allowing a subset of the bigger transaction to fail without having the overall transaction to fail.
PostgreSQL does not handle transaction nesting, so you cannot issue a nested set of BEGIN, nor COMMIT/ROLLBACK statements. Savepoints allow PostgreSQL to mimic the nesting of transaction blocks.

Savepoints are marked with a mnemonic name, that you can use to commit or rollback. The name must be unique within the transaction, and if you re-use the same over and over the previous savepoints with the same name will be discarded.
Let's see an example:


forumdb=> BEGIN;
BEGIN
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Eclipse IDE' );
INSERT 0 1
forumdb=> SAVEPOINT other_tags;
SAVEPOINT
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Netbeans IDE' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Comma IDE' );
INSERT 0 1
forumdb=> ROLLBACK TO SAVEPOINT other_tags;
ROLLBACK
forumdb=> INSERT INTO tags( tag ) VALUES ( 'IntelliJIdea IDE' );
INSERT 0 1
forumdb=> COMMIT;
COMMIT


forumdb=> SELECT tag FROM tags WHERE tag like '%IDE';
       tag
------------------
 Eclipse IDE
 IntelliJIdea IDE
(2 rows)



In the above transaction, the first statement does not belong to any savepoint and therefore follows the life of the transaction itself. After the other_tags savepoint is created, all the following statements follow the lifecycle of the savepoint itself, therefore once the ROLLBACK TO SAVEPOINT is issued the statements within the savepoint are discarded. After that, other statements belong to outer transaction, and therefore follows the lifecycle of the transaction itself.
In the end, the result is that everything that has been executed outside the savepoint is stored into the table.


Once you have defined a savepoint you can also change your mind and release it, so that statements within the savepoint follow the same lifecycle of the main transaction. As an example:




forumdb=> BEGIN;
BEGIN
forumdb=> SAVEPOINT editors;
SAVEPOINT
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Emacs Editor' );
INSERT 0 1
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Vi Editor' );
INSERT 0 1
forumdb=> RELEASE SAVEPOINT editors;
RELEASE
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Atom Editor' );
INSERT 0 1
forumdb=> COMMIT;
COMMIT

forumdb=> SELECT tag FROM tags WHERE tag LIKE '%Editor';
     tag
--------------
 Emacs Editor
 Vi Editor
 Atom Editor
(3 rows)


When the RELEASE SAVEPOINT is issued, the savepoint is like has disappeared and therefore the two INSERT statements follow the main transaction lifecycle. In other words, it is like the savepoint has never been defined.


In a transaction you can have multiple savepoints, but once you rollback a savepoint, you rollback also all the savepoints that follow it:



forumdb=> BEGIN;
BEGIN
forumdb=> SAVEPOINT perl;
SAVEPOINT
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Rakudo Compiler' );
INSERT 0 1
forumdb=> SAVEPOINT gcc;
SAVEPOINT
forumdb=> INSERT INTO tags( tag ) VALUES ( 'Gnu C Compiler' );
INSERT 0 1
forumdb=> ROLLBACK TO SAVEPOINT perl;
ROLLBACK
forumdb=> COMMIT;
COMMIT

forumdb=> SELECT tag FROM tags WHERE tag LIKE '%Compiler';
 tag
-----
(0 rows)


As you can see, even if the transaction has issued a COMMIT, everything that has been done after the savepoint perl, to which the transaction has rolled back, has been rolled back to.
In other words, rolling back to a savepoint means you roll back everything after such savepoint.


* DONE Deadlocks

A deadlock is an event that happens when different transaction depends on each other in a circular way.
Deadlocks are, to some extent, normal events in a concurrent database environment and nothing an administrator should worry about, unless they became extremely frequent, meaning there is some dependency error in the applications and the transactions.

When a deadlock happens there is no choice but to terminate the locked transactions.
PostgreSQL has a very powerful deadlock detection engine that does exactly such job: it finds out stalled transactions and, in the case of a deadlock, terminates them (producing a ROLLBACK).

In order to produce a deadlock, imagine two concurrent transaction applying changes to the very same tuples in a conflicting way. For example, the first transaction could do something like:


-- session 1
forumdb=> BEGIN;
BEGIN
forumdb=> SELECT txid_current();
 txid_current
--------------
         4875
(1 row)

forumdb=> UPDATE tags SET tag = 'Perl 5' WHERE tag = 'perl';
UPDATE 1



and in the meantime, the other transaction performs the following:


-- session 2
forumdb=> BEGIN;
BEGIN
forumdb=> SELECT txid_current();
 txid_current
--------------
         4876
(1 row)

forumdb=> UPDATE tags SET tag = 'Java and Groovy' WHERE tag = 'java';
UPDATE 1



So far, both the transactions have updated a single tuple without conflicting each other. Now imagine that the first transaction tries to modify the tuple that the other transaction has already changed; as we have already seen in previous examples, the transaction will remain locked waiting to acquire the lock on the tuple:

-- session 1
forumdb=> UPDATE tags SET tag = 'The Java Language' WHERE tag = 'java';
UPDATE 1
-- locked


If the second transactions tries, on the other hand, to modifiy a tuple already touched by the first transaction, it will be locked waiting for the lock acquisition:


-- session 2
forumdb=> UPDATE tags SET tag = 'Perl and Raku' WHERE tag = 'perl';
ERROR:  deadlock detected
DETAIL:  Process 78918 waits for ShareLock on transaction 4875; blocked by process 80105.
Process 80105 waits for ShareLock on transaction 4876; blocked by process 78918.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,1) in relation "tags"


This time however, PostgreSQL realizes the two transactions cannot solve the problem because they are waiting on a circular dependency, and therefore decides to kill the second transaction in order to let the first one a chance to complete. As you can see from the error message, PostgreSQL knows that transaction 4875 is waiting for a lock hold by transaction 4876 and viceversa, so there is no solution to proceed but killing one of the two.

Being natural events in a concurrent transactional system, deadlocks are something you have to deal with and your applications must be prepared to replay a transaction in the case it is forced to ROLLBACK by deadlock detection.


Deadlock detection is a complex and resource expensive process, therefore PostgreSQL does it on a scheduled basis. In particular, the configuration parameter deadlock_timeout express how often PostgreSQL should search for a dependency among stalled transactions. By default such value is set at one second, and is expressed in milliseconds:

forumdb=> SELECT name, setting
          FROM pg_settings
          WHERE name like '%deadlock%';
       name       | setting
------------------+---------
 deadlock_timeout | 1000
(1 row)


Decreasing such value is often a bad idea: while your applications and transactions will fail sooner, your cluster will be forced to consume extra resources in dependecy analysis.


* DONE How PostgreSQL Handles Persistency and Consistency: WALs
  CLOSED: [2020-02-15 sab 16:07]

In the previous sections you have seen how to interact with explicit transactions, and most notably how PostgreSQL executes every single statement within a transaction.

PostgreSQL does internally a lot of effort to ensure that consolidated data on storage reflects the status of the committed transactions. In other words, data can be considered consolidated only if the transaction that produced (or modified)  it has been committed. But this also means that, once a transaction has been committed, its data is "safe" on storage, no matter what will happen in the future.

PostgreSQL manages transactions and data consolidations by means of Write Ahead Logs (WALs). This section introduces you to the concept of WALs and their use within PostgreSQL.


** DONE Write Ahead Logs (WALs)
   CLOSED: [2020-02-15 sab 11:50]

Before we dig into the details, it is required to briefly explain how PostgreSQL internally handles data. Tuples are stored into the mass storage, usually a disk, under the $PGDATA/base directory, in files named only by numbers. When a transaction requests access to a particular set of tuples, PostgreSQL loads the data from the $PGDATA/base directory and places requested data in one or more shared buffers. The shared buffers are in-memory copy of the on-disk data, and all the transactions access the shared data because they provide much more performance and do not require every single transaction to seek the data out of the storage.
Figure 10.2 shows the loading of a few data pages into the shared buffers memory location.


!!!!! FIGURE 11.2 !!!!!!



When a transaction modifies some data, it does so modifying the in-copy memory, that means modifies the shared buffers area.
At this point the in-memory copy of the data does not corresponds to the stored version, and it is here that PostgreSQL has to guarantee consistency and persistency without loosing in performances.
What happens is that the data is kept in memory but is marked as dirty, meaning that it is a copy not yet synchronized with the on-disk original source. Once the changes to a dirty buffer has been committed, PostgreSQL consolidates such changes into the WALs and keeps the dirty buffer in memory to be served as the most recent available copy to other transactions.
Sooner or later, PostgreSQL will push the dirty buffer to the storage, replacing the original copy with the modified version, but a transaction usually do not know and do not care of when this is going to happen.

Figure 11.3 explains the above workflow: the red buffer has been modified by a transaction and therefore does not match anymore what is on disk; however when the transaction issues a COMMIT the changes are forced and flushed to the WALs.


!!!!!! FIGURE 11.3 !!!!!!!!!


Why is the WAL space supposed to be faster than overwriting the original data block in the $PGDATA/base directory? The trick is that in order to find the exact position on the disk storage where the block has to be overwritten, PostgreSQL should have to perform what is called a random-seek, that is a costly I/O operation. On the other hand, the WALs are sequentially written as a journal, and therefore there is no need to perform a random-seek. Therefore, doing the WALs writing prevents the I/O performance degradation and allows PostgreSQL to overwrite the data block in a future moment, when for instance the cluster is not overloaded and has I/O bandwidth available.

Every time a transaction performs a COMMIT, its actions and modified data are permanently stored into a piece of the WAL, in particular a specific part of the current WAL segment (more on this later). Therefore, PostgreSQL can reproduce the transaction and its effects in order to perform back the very same data changes.

This however does not suffice in making PostgreSQL reliable: PostgreSQL does a big effort to ensure the data actually hits the disk storage. In particular, during the WALs writing, PostgreSQL isolates itself from the outside world disabling operating system signals, so that it cannot be interrupted. Moreover, PostgreSQL issues a fsync(2), a particular operating system call that forces the filesystem cache to flush data on disk.
PostgreSQL does all the above in order to ensure that the data phisically hit the disk layer, but it must be clear that if the filesystem, or the disk controller (i.e., the hardware) lies, the data could not be phisically on the disk. This is important, but PostgreSQL cannot do nothing about that and have to trust what the operating system (and thus the hardware) reports back as feedback.

In any case, the COMMIT will return success to the invoking transaction if an only if PostgreSQL has been able to write the changes on the disk. Therefore, at the transaction level, if a COMMIT succeed (i.e., there is no error), the data has been written in the WALs, and therefore can be asusmed to be "safe" on the storage layer.

WALs are split into so called segments, a segment is a file made by exactly 16 MB of changes in the data. While it is possible to modify the size of segments during an initdb, we strongly discourage this and will assume every segment is of 16 MB.
This means that PostgreSQL writes, sequentially, a single file at the time (i.e., WAL segment) and when this has reached the size of 16 MB it is closed and a new 16 MB file is created.
The WAL segements (or WALs for short) are stored into the pg_wal directory under $PGDATA. Every segment has a name made by hexadecimal digits, and 24 characters long. The first 8 characters indicates the so called "time-line" of the cluster (something related to replication), the second 8 digits indicates an increasing sequence number named Log Sequence Number (LSN for short), and the last 8 digits provide the offset within the LSN. Here there's an example:



$ sudo -u postgres ls -1 $PGDATA/pg_wal
0000000700000247000000A8
0000000700000247000000A9
0000000700000247000000AA
0000000700000247000000AB
0000000700000247000000AC
0000000700000247000000AD
...


In the previous content of the pg_wal, you can see that every WAL segment has the same timeline, number 7, and the LSN is 247. Every file, then, has a different offset with the first one being A8, the second A9 and so on.
As you can imagine, WAL segment names are not made for humans, but PostgreSQL knows exactly how and in which file it has to search for information.


Sooner or later, depending on the memory resources and usage of the cluster, the data in memory will be written back to its original disk positions, meaning that the WALs are serving only as a temporary safe storage on disk. The reason for that is not only tied to a performance bottleneck, as already explained, but also to allow data restoration in the case of a crash.

** DONE WALs as a Rescue in Case of a Crash
   CLOSED: [2020-02-15 sab 11:43]

When you cleanly stops a running cluster, for example by means of pg_ctl, PostgreSQL ensures that every dirty data in memory is flushed to the storage in the correct order, and then halts itself.
But what happens if the cluster is uncleanly stopped, for example by means of a power failure?
This even is named a "crash", and once PostgreSQL starts over, it performs a so called "crash-recovery". In particular, PostgreSQL understands it has stopped in an unclean way, and therefore the data on the storage could not be the last version that existed when the cluster terminated its activity. But PostgreSQL knows that every committed data is at least present in the WALs, and therefore starts reading the WALs in what is called as "WAL-replay", and adjusts the data on the storage according to what is in the WALs. Until the crashrecovery has completed, the cluster is not usable and does not accept connections; once the crash recovery has finished, the cluster knows that the data on the storage has been made coherent and therefore normal operations can start again.

This process allows the cluster to somehow self-heal after an external event has caused the lifecicle to abort. This makes it clear that the main aim of the WALs is not to avoid performance degradations, rather to ensure the cluster is able to recover after a crash. 
And in order to be able to do that, it must have data written permanently to the storage, but thanks to the sequentially way by which WALs are written, data is made persistent with less I/O penalties.


** DONE Avoiding Infinite WALs: Checkpoints
   CLOSED: [2020-02-15 sab 11:50]

Sooner or later, the cluster must made every change that has already been written in the WALs also available in the data files, that is it has to write tuples in random-seek way.
This writes happen at very specific times named checkpoints. A checkpoint is a point in time in which the database makes an extra effort to ensure that evreything already present in the WALs is also written in the correct position in the data storage.
Figure 11.4 helps understanding what happens during a CHECKPOINT.


!!!! FIGURE 11.4 !!!!!!!!



But why should the database made this extra synchronization effort?
If the synchronization does not happen, the WALs wil keep growing and thus consume storage space. Moreover, if the database crashes for any reason, the WAL-replay must walk across a very long set of WALs.
Thanks to checkpoint instead, the cluster knows that in the case of crash it has to synchronize data between the storage and the WALs only after the last checpoint succesfully performed. In other words, the storage space and time required to replay the WALs is reduced from the crash instant to the last checpoint.

But there is another advantage: since after a checkpoint PostgreSQL knows that the data in the WALs has been synchronized with the data in the storage, it can throw away already sycnrhonized WALs. In fact, even in the case of a crash, PostgreSQL will not need at all any WAL part that is preceeding the last checkpoint. Therefore, PostgreSQL performs WALs recycling: after a checkpoint a WAL segment is reused as an empty segment for the next-to-be checkpoint.

Thanks to this machinery, the space required to store WAL segments will pretty much remain the same during the cluster lifecycle, because at every checkpoint segments will be reused. Most notably, in the case of a crash, the number of WAL segments to replay will be the total number of thos produced since the last checkpoint.

** DONE Checkpoints Configuration Parameters
   CLOSED: [2020-02-15 sab 15:59]

The database administrator can fine tune the checkpoints, meaning she can decide when and how often a checkpoint can happen. Since the checkpoints are consolidating points, the more often they happen and the less time will be required to recover from a crash, on the other hand the more seldom they are executed and the more the database will not suffer from I/O bottlenecks. In fact, when a checkpoint is reached, the database must force every dirty buffer from memory to disk, and this usually means that an I/O spike is introduced; during such spike other concurrent database activities, like getting new data from the storage, will be penlized because the I/O bandwidth is temporarily exhausted from the checkpoint activity.
For the above reasons, it is very important to tune carefully the checkpoints and in particular their tuning must reflect the cluster workload.

Checkpoints can be tuned by means of three main configuration parameters that interacct each other, and that are explained in the following subsections.


*** DONE Checkpoint Timeout and WAL Size
    CLOSED: [2020-02-15 sab 15:59]

Checkpoint frequency can be tuned by two hortogonal parameters: max_wal_size and checkpoint_timeout.

The max_wal_size parameter dictates how much space the pg_wal directory can occupy. Since at every checkpoint the WAL segments are recycled, the pg_wal directory tends to occupy the very same size in time. Tuning the max_wal_size parameter specifies after how many data changes the checkpoint must be completed, and therefore this parameter is a "quantity" specification.
The checkpoint_timeout expresses after how many time the checkpoint must be forced.

The two parameters are hortogonal, meaning that the first that happens triggers the checkpoint execution: your database produces data changes over the max_wal_size parameter or the checkpoint_timeout has elapsed.

As an example, in a system with the following settings:


forumdb=> SELECT name, setting, unit FROM pg_settings 
          WHERE name IN ( 'checkpoint_timeout', 'max_wal_size' ); 
        name        | setting | unit 
--------------------+---------+------
 checkpoint_timeout | 300     | s
 max_wal_size       | 1024    | MB
(2 rows)


After 300 seconds (5 minutes) a checkpoint is triggered, unless in the meantime 1024 MB of data has been changed. Therefore if your database is not doing much activity, a checkpoint is triggered by checkpoint_timeout, while in the case the database is heavily accessed, a checkpoint is triggered every 1GB of data produced.

*** DONE Checkpoint Throttling
    CLOSED: [2020-02-15 sab 16:07]

In order to avoid an I/O spike at the execution of a checkpoint, PostgreSQL introduced a third parameter named checkpoint_completion_target, that can handle values between 0 and 1. Such parameters indicates the amount of time the checkpoint can delay the writing of dirty buffers, in particular the time provided to complete a checkpoint is computed as checkpoint_timeout x checkpoint_completion_target.

For example, is checkpoint_completion_target is set to 0.2 and checkpoint_timemout is 300 seconds, the system will have 60 seconds to write all the data. The system calibrates the required I/O bandwidth to fulfill the dirty buffers writing.

Therefore, if you set the checkpoint_completion_target torwards 0 you are going to see spikes at the checkpoint executions, with the consequence of an high usage of I/O bandwidth, while setting the parameter torwards 1 means you are going to see continous I/O activity with low I/O bandwidth.


** DONE Manually Issuing a Checkpoint

It is always possible, for the cluster administrator, to manually start a checkpoint process: the PostgreSQL statement CHECKPOINT starts all the activities that would normally happens at checkpoint_timeout or max_wal_size.

Being the checkpoint such an invasive operation, why should someone want to perform it manually?
One reason could be to ensure that all the data on the disk has been synchronized, for example before starting a streaming replication or a file-level backup.

* TODO VACUUM

In the previous sections you have learnt how PostgreSQL exploits the MVCC to store different versions of the same data (tuples) that different transactions can perceived depending on their active snapshot. However, keeping different versions of the same tuples requires an extra-space with regard to the last active version, and this space could fill your storage sooner or later.
To prevent that, and reclaim storage space, PostgreSQL provides an internal tool named vacuum, which aim is to analyze the stored tuple versions and remove the ones that are surely no more perceivable.
Remember: a tuple is not perceivable when there no more active transactions that can references such version, that means have the tuple version within their snapshot.

Vacuum  a can be an I/O intensive operation, since it must reclaim no more used disk space, and therefore can be an invasive operation. For that reason, you are not supposed to run vacuum very frequently and PostgreSQL provides also a background job, named autovacuum, that can run vacuum for you depending on the current database activity.
The following subsections will show you both the manual and automatic vacuum.

** DONE Manual Vaccum
   CLOSED: [2020-02-16 dom 11:14]

The manual vacuum can be run against a single table, a subset of table columns, or a whole database, and the synopsis is as follows:


VACUUM [ FULL ] [ FREEZE ] [ VERBOSE ] [ ANALYZE ] [ table_and_columns [, ...] ]


There are three main versions of VACUUM that perform progressively more aggressive refactoring:
- plain VACUUM (the default) does a micro-space-reclaim, that means throws away dead tuple versions but does not defragment the table, and therefore the final effect is of no space reclaimed;
- VACUUM FULL performs a whole table rewrite, throwing away dead tuples and removing defragmentation, thus reclaiming also disk space;
- VACUUM FREEZE marks as frozen already consolidated tuples, preventing the xid wraparound problem.

VACUUM cannot be executed within a transaction nor a function or procedure. The extra options VERBOSE and ANALYZE provide respectively a verbose output and perform also a statistic update of the table contents (this is sueful for performance gain).


In order to see the effects of VACUUM, let's build a simple example. First of all, ensure that autovacuum is set to off, if not edit the configuration file $PGDATA/postgresql.conf and set the parameter to off, then restart the cluster. After that, inspect the size of the tags table:



forumdb=> SHOW autovacuum;
 autovacuum 
------------
 off
(1 row)

forumdb=> SELECT relname, reltuples, relpages, pg_size_pretty( pg_relation_size( 'tags' ) )
FROM pg_class WHERE relname = 'tags' AND relkind = 'r';
 relname | reltuples | relpages | pg_size_pretty 
---------+-----------+----------+----------------
 tags    |         6 |        1 | 8192 bytes
(1 row)


As you can see, the table has only 6 tuples and occupies a single data page on disk, of the size of 8kB. Now let's populate the table with about one million randon tuples:


forumdb=> INSERT INTO tags( tag )
SELECT 'FAKE-TAG-#' || x
FROM generate_series( 1, 1000000 ) x;
INSERT 0 1000000

and since we have stopped autovacuum let's know PostgreSQL about the new size of the table issuing an ANALYZE independently:


forumdb=> ANALYZE tags;
ANALYZE
forumdb=> SELECT relname, reltuples, relpages, pg_size_pretty( pg_relation_size( 'tags' ) )
FROM pg_class WHERE relname = 'tags' AND relkind = 'r';
 relname |  reltuples  | relpages | pg_size_pretty 
---------+-------------+----------+----------------
 tags    | 1.00001e+06 |     6370 | 50 MB


It is now the time to invalidate all the tuples we have inserted, for example by overwriting them with an UPDATE (that due to MVCC will duplicate the tuples):


forumdb=> UPDATE tags SET tag = lower( tag ) WHERE tag LIKE 'FAKE%';
UPDATE 1000000



The table now has still around one million valid tuples, but the size has almost doubled because every tuple now exists in two versions, one of which is dead:


forumdb=> ANALYZE tags;
ANALYZE
forumdb=> SELECT relname, reltuples, relpages, pg_size_pretty( pg_relation_size( 'tags' ) )
FROM pg_class WHERE relname = 'tags' AND relkind = 'r';
 relname |  reltuples  | relpages | pg_size_pretty 
---------+-------------+----------+----------------
 tags    | 1.00001e+06 |    12739 | 100 MB
(1 row)


We have built now something that can be used as a test lab for VACUUM. If we execute the plain VACUUM, every single data page will be freed of the dead tuples but pages will not be reconstructed, so the number of data pages will remain the same, and the final table size on storage will be the same too:



forumdb=> VACUUM VERBOSE tags;
...
INFO:  "tags": found 1000000 removable, 1000006 nonremovable row versions in 12739 out of 12739 pages

VACUUM

forumdb=> ANALYZE tags;
ANALYZE

forumdb=> SELECT relname, reltuples, relpages, pg_size_pretty( pg_relation_size( 'tags' ) )
FROM pg_class WHERE relname = 'tags' AND relkind = 'r';
 relname |  reltuples  | relpages | pg_size_pretty 
---------+-------------+----------+----------------
 tags    | 1.00001e+06 |    12739 | 100 MB
(1 row)



VACUUM informs us that one million tuples can be safely removed, while one million (plus the original six tuples) cannot be removed because they represent the last active version. However, after this execution the table size has not changed: all data pages are essentially fragmented.

So what is the aim of plain VACUUM? This kind of VACUUM provides new free space in every single page, so the table can essentially sustain a new one million tuples without changing its own size. We can prove this by performing the same tuple invalidation we had already done:



forumdb=> UPDATE tags SET tag = upper( tag ) WHERE tag LIKE 'fake%';
UPDATE 1000000
forumdb=> ANALYZE tags;
ANALYZE
forumdb=> SELECT relname, reltuples, relpages, pg_size_pretty( pg_relation_size( 'tags' ) )
FROM pg_class WHERE relname = 'tags' AND relkind = 'r';
 relname |  reltuples  | relpages | pg_size_pretty 
---------+-------------+----------+----------------
 tags    | 1.00001e+06 |    12739 | 100 MB
(1 row)


As you can see, nothing has chaned in the number of tuples, pages and table size. Essentially, it went like this: we introduced one million new tuples in the beginning, than we updated all of them making the one million becoming two millions, then we VACUUM the table lowering the number again to one million but leaving off the free space already allocated so that the table was occupying space for two millions but only the half was full. After that we did created a new million of tuple versions but the system does not need to allocate more space because there is enough free, even if scattered across the whole table.

On the other hand, a VACUUM FULL not only frees the space within the table, but also reclaims all such space compacting the table to its mimimum size. If we execute VACUUM FULL right now, at least 50 MB of data space will be reclaimed because one million tuples will be thrown away:



forumdb=> VACUUM FULL VERBOSE tags;
INFO:  vacuuming "public.tags"
INFO:  "tags": found 1000000 removable, 1000006 nonremovable row versions in 12739 pages
DETAIL:  0 dead row versions cannot be removed yet.
CPU: user: 0.18 s, system: 0.61 s, elapsed: 1.03 s.
VACUUM
forumdb=> ANALYZE tags;
ANALYZE
forumdb=> SELECT relname, reltuples, relpages, pg_size_pretty( pg_relation_size( 'tags' ) )
FROM pg_class WHERE relname = 'tags' AND relkind = 'r';
 relname |  reltuples  | relpages | pg_size_pretty 
---------+-------------+----------+----------------
 tags    | 1.00001e+06 |     6370 | 50 MB
(1 row)


The output of VACUUM FULL is pretty much the same of the plain VACUUM: it croacks that one million tuples can be thrown away. The end result, however, is that the whole table has gained the space occupied by such tuples.
It is important to remember, however, that while tempting, a VACUUM FULL forces a complete table rewrite and therefore pushes a lot of work down to the I/O system, thus incurring in potential performance penalties.


It is possible to summarize the main effects of VACUUM throuhg pictures. Imagine a situation like the one depicted in Figure 11.5, where a table is occupying two data pages, respectively with four and three valid tuples.

!!!! PCITURE 11.5 !!!!!!!

If a plain vacuum executes, the total number of pages will remain the same but every page will free the space occupied by dead tuples and will compact valid tuples together, as show in Figure 11.6.


!!!! PICTURE 11.6 !!!!!!!

If a VACUUM FULL executes, the table data pages are fully rewritten to compact all valid tuples together. In this situation the second page of the table results empty, and therefore is discarded at all, and therefore there is a gain in the space consumption on the storage device.


!!!!  PICTURE 11.7 !!!!


In the case you are approaching the xid wraparound, a VACUUM FREEZE solves the problem by marking as "always in the past" the tuples.

For other usages of VACUUM, please see the official documentation.

** DONE Autovacuum
   CLOSED: [2020-02-16 dom 11:33]

Since PostgreSQL 8.4 there is a background job named autovacuum that is responsible for running VACUUM on the behalf of the system administrator.
The idea is that, being VACUUM an I/O intensive operation, a background job can perform small micro-vacuums without interferying with the normal database activity.

Usually you don't have to worry about the autovacuum, since it is enabled by default and has general settings that can be useful in many scenarios. However, there are different settings that can help you in fine tuning the autovacuum. A system with a good autovacuum configuration usually does not need any manual VACUUM, and often the symptoms for a manual VACUUM are that the autovacuum must be configured to run more frequently than else.

The main settings about autovacuum can be inspected from the configuration file $PGDATA/postgresql.conf or, as usual, the pg_settings catalog. The most important configuration parameters are:

- autovacuum enables or disables the autovacuum background machinery. There is no reason, behind that of doing experiments like we did in the previous section, to keep the autovacuum disabled.

- autovacuum_vacuum_threshold indicates how many new tuple versions will be allowed before autovacuum can activate on a table. The idea is that we don't want autovacuum to triggers if only a small amount of tuples have changed in a table, because that will produce an I/O penalty without an effective gain in space.

- autovacuum_vacuum_scale_factor indicates the amount, as percentage, of tuples that have to be changed before autovacuum performs a concrete vauum on a table. The idea is that the more the table grows, the more autovacuum will wait for dead tuples before it performs its activities.

- autovacuum_cost_limit a value that measure the maximum threshold over the which the background process must suspend itself to resume later on.

- autovacuum_cost_delay indicates how many milliseconds (mutliple of ten) the autovacuum will suspend to not interfere with other database activities. The suspend is performed only when the cost is reached.


Essentially the activity of the autovacuum goes like this: if the number of changed tuples is greater than autovacuum_vacuum_threshold + ( table-tuples * autovacuum_vacuum_scale_factor )  the autovacuum process activates. It then performs a vacuum on the table measuring the amount of work. If the amount of work reaches the autovacuum_cost_limit, the process suspends itself for autovacuum_cost_delay milliseconds, and then resumes and proceeds further. Any time the autovacuum reaches the threshold it does suspend itself, producing the effect of a incremental vacuum.

But how does autovacuum computes the cost of the activity it is doing? There are a set of tunable values that express how much does it cost to fecth a new data page, to scan a dirty page, and so on:


forumdb=> SELECT name, setting
   FROM pg_settings
   WHERE name like 'vacuum_cost%';
          name          | setting
------------------------+---------
 vacuum_cost_delay      | 10
 vacuum_cost_limit      | 10000
 vacuum_cost_page_dirty | 20
 vacuum_cost_page_hit   | 1
 vacuum_cost_page_miss  | 10


Such values are used for both manual VACUUM and autovacuum, with the exception that autovacuum has its own autovacuum_vacuum_cost_limit that usually is set to 200.


        Manual VACUUM is never subjected to the cost machinery, and therefore performs until it finishes its job.

Similar parameters exists for the anaylze part, because the autovacuum background process performs a VACUUM ANALYZE and therefore you  have autovacuum_analyze_threshold and autovacuum_analyze_scale_factor that are in charge of defining the window of activity for the ANALYZE part (that is related to update the statics on the content of the table).


You can have more than one background process doing the autovacuum activity, in particular the parameter autovacuum_max_workers defines how many background processes PostgreSQL can start in parallel to perform the autovacuum activities. On a single database there will be only one worker active in a specific instant, therefore it does not make sense to raise this value over than the number of actively used databases in the system.



* DONE Conclusions
  CLOSED: [2020-02-15 sab 16:26]

This chapter has presented you the transaction machinery. PostgreSQL uses transactions everywhere, either implicit (one statement transactions) or explicit (whole units of work). Every transaction is isolated from each other by means of a specific isolation level, that can be set at the transaction begin. Depending on the isolation level, some transactions may be aborted automatically and thus must be restarted.

PostgreSQL exploits MVCC to enable high concurrent access to the underlying data, and this means that every transaction perceive a snapshot of the data while the system is keeping different versions of the same tuples. Sooner or later, invalid tuples will be removed and the storage space will be reclaimed.
On one hand, MVCC provides better concurrency, but on the other hand requires extra effort to reclaim back the storage space once transactions no more reference dead tuples. PostgreSQL provides VACUUM to this aim, and has also a background process named autovacuum to periodically and non-invasively reclaim storage space and keep the system clean and healthy.

In order to improve I/O and reliability, PostgreSQL stores data into a journal written sequentially, the Write Ahead Log. The WAL is split into segments, and at particular intervals of time, named checkpoints, all the dirty data in memory is forced to the exact position in the storage and WAL segments are recycled.

* References
PostgreSQL Transaction Isolation Levels, official documentation <https://www.postgresql.org/docs/12/sql-set-transaction.html>
PostgreSQL Transaction Isolation Level SERIALIZABLE, official documentation <https://www.postgresql.org/docs/current/transaction-iso.html#XACT-SERIALIZABLE>
PostgreSQL Savepoints, official documentation <https://www.postgresql.org/docs/12/sql-savepoint.html>
PostgreSQL VACUUM, official documentation <https://www.postgresql.org/docs/12/sql-vacuum.html>
