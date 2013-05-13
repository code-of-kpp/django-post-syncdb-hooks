from django.conf import settings
from django.db import connections, DEFAULT_DB_ALIAS

BROKEN_INSERT_RETURN = ('django.db.backends.postgresql_psycopg2', )

def to_partition(func):
    """Decorator that wraps turning off `can_return_id_from_insert`
    db connection feature"""
    if any(((settings.DATABASES[alias]['ENGINE'] in BROKEN_INSERT_RETURN)
            for alias in settings.DATABASES)):
        def wrapper(using=DEFAULT_DB_ALIAS, *args, **kwargs):
            """{}
            Wrapped with
            {}""".format(func.__doc__, to_partition.__doc__)
            kwargs['using'] = using
            if settings.DATABASES[using]['ENGINE'] in BROKEN_INSERT_RETURN:
                oldval = connections[using].features.can_return_id_from_insert
                connections[using].features.can_return_id_from_insert = False
                return_value = func(*args, **kwargs)
                connections[using].features.can_return_id_from_insert = oldval
                return return_value
            else:
                return func(*args, **kwargs)
        return wrapper
    else:
        return func
