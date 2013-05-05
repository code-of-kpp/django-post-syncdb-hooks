# django-post-syncdb-hooks

Run some SQL files after Django's syncdb.

Usage:

1. Add `post_syncdb_hooks` to `INSTALLED_APPS`.
2. Add submodules you need (currently only `post_syncdb_hooks.partitioning` is available) to your `INSTALLED_APPS`. This will add functions to your DB after every syncdb.
3. Create a file `sql/post_syncdb-hook.sql` (or `sql/post_syncdb-hook.<last part of db-backend mame>.sql`) in your app directory with calls to the functions. Now after every `syncdb` these SQL files will be sent to the DB engine.

If you have multiple DB configuration, Django will call this hook with DB-alias used to syncdb your app.

## Partitioning

Partitioning is currently implemented only for PostgreSQL. Use `db_index` parameter in the fields of your models to automatically create indexes on partitions.

Drawbacks:

* Empty indexes on master-table;
* You need to run `manage.py syncdb` twice since Django create indexes after `post-syncdb` hook.
