# django-post-syncdb-hooks

Run some SQL files after Django's syncdb.

Usage:

1. Add `post_syncdb_hooks` to `INSTALLED_APPS`.
2. Add submodules you need (currently only `post_syncdb_hooks.partitioning` is available) to your `INSTALLED_APPS`. This will add functions to your DB after every syncdb.
3. Create a file `sql/post_syncdb-hook.sql` (or `sql/post_syncdb-hook.<last part of db-backend mame>.sql`) in your app directory with calls to the functions. Now after every `syncdb` these SQL files will be sent to the DB engine.

If you have multiple DB configuration, Django will call this hook with DB-alias used to syncdb your app.

## Partitioning

Partitioning is currently implemented only for PostgreSQL. Use `db_index` parameter in the fields of your models to automatically create indexes on partitions.

Apply `post_syncdb_hooks.partitioning.to_partition` decorator to `save()` method of models involved into partitioning:

```python
from post_syncdb_hooks.partitioning import to_partition
from django.db.models import Model

class MyModel(Model):
    #...
    @to_partition
    def save(self, *args, **kwargs):
        #...
        super(self.__class__, self).save(*args, **kwargs)
```

Drawbacks:

* Empty indexes on master-table;
* Two queries per `INSERT INTO` instead of one in PostgreSQL;
* Need to run `manage.py syncdb` twice since Django create indexes after `post-syncdb` hook.
