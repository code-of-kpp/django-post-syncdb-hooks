from __future__ import print_function

import os.path
import sys
from django.db.models import signals
from django.db import connections, transaction
from django.conf import settings


def load_customized_sql(app, created_models, db, verbosity=2, **kwargs):
    """Loads custom SQL from app/sql/post_syncdb-hook.<backend>.sql and
    from app/sql/post_syncdb-hook.sql and send it to the database"""

    app_dir = os.path.normpath(os.path.join(os.path.dirname(app.__file__),
        'sql'))

    custom_files = (os.path.join(app_dir, "post_syncdb-hook.%s.sql" %
                        settings.DATABASES[db]['ENGINE'].split('.')[-1]),
                    os.path.join(app_dir, "post_syncdb-hook.sql"))

    for custom_file in custom_files:
        if os.path.exists(custom_file):
            if verbosity >= 2:
                print("Loading customized SQL for %s using file %s" %
                      app.__name__,
                      custom_file)

            try:
                with open(custom_file, 'U') as fp:
                    cursor = connections[db].cursor()
                    cursor.execute(fp.read().decode(settings.FILE_CHARSET))
            except Exception as exc:
                sys.stderr.write("Couldn't execute custom SQL for %s" %
                        app.__name__)
                import traceback
                traceback.print_exc(exc)
                transaction.rollback_unless_managed(using=db)
            else:
                transaction.commit_unless_managed(using=db)
        elif verbosity >= 2:
            print("No customized SQL file %s" %
                  custom_file)

signals.post_syncdb.connect(load_customized_sql)
