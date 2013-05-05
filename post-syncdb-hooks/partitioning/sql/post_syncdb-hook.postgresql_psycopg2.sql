CREATE OR REPLACE FUNCTION month_partition_creation( DATE, DATE, VARCHAR, VARCHAR )
returns void AS $$
DECLARE
    create_query TEXT;
    date_str VARCHAR;
    index_name VARCHAR;
    index_fields VARCHAR;
BEGIN
    FOR create_query, date_str IN SELECT
            'create table if not exists '
            || $3
            || '_'
            || TO_CHAR( dt_month, 'YYYY_MM' )
            || ' ( check( '
            || $4
            || '::timestamptz >= '''
            || TO_CHAR( dt_month, 'YYYY-MM-DD' )
            || '''::timestamptz and '
            || $4
            || '::timestamptz < '''
            || TO_CHAR( dt_month + INTERVAL '1 month', 'YYYY-MM-DD' )
            || '''::timestamptz ) ) inherits ( '
            || $3
            || ' );'
            ,
            TO_CHAR( dt_month, 'YYYY_MM' )
        FROM generate_series( $1, $2, '1 month' ) AS dt_month
    LOOP
        EXECUTE create_query;
        FOR index_name, index_fields IN SELECT c.relname as index_name,
                array_to_string(ARRAY(
                    SELECT pg_get_indexdef(i.indexrelid, k + 1, true)
                    FROM generate_subscripts(i.indkey, 1) as k
                    ORDER BY k
                ), ',') as index_fields
                FROM pg_catalog.pg_class c
                    JOIN pg_catalog.pg_index i ON i.indexrelid = c.oid
                    JOIN pg_catalog.pg_class c2 ON i.indrelid = c2.oid
                    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                WHERE c.relkind IN ('i','')
                    AND n.nspname NOT IN ('pg_catalog', 'pg_toast')
                    AND pg_catalog.pg_table_is_visible(c.oid)
                    AND c2.relname = $3
        LOOP
            EXECUTE 'drop index if exists '
                || index_name
                || '_'
                || date_str
                || ';'
                ;
            EXECUTE 'create index '
                || index_name
                || '_'
                || date_str
                || ' on '
                || $3
                || '_'
                || date_str
                || ' ( '
                || index_fields
                || ' );'
                ;
        END LOOP;
    END LOOP;
    EXECUTE 'CREATE OR REPLACE FUNCTION month_partition_trigger_function'
    || '_'
    || $3
    || '() '
    || 'returns TRIGGER AS $trigger$ '
    || 'DECLARE '
    || 'table_name VARCHAR; '
    || 'BEGIN '
    || 'table_name := '''
    || $3
    || '_'' || TO_CHAR( NEW.'
    || $4
    || ', ''YYYY_MM'' ); '
    || 'EXECUTE'
    || ' ''INSERT INTO '' || table_name || '' VALUES ($1.*); '' USING NEW;'
    || 'RETURN NULL; '
    || 'END; '
    || '$trigger$ '
    || 'language plpgsql; '
    ;
    EXECUTE 'DROP TRIGGER IF EXISTS month_partition_trigger_'
    || $3
    || ' ON '
    || $3
    || '; '
    || 'CREATE TRIGGER month_partition_trigger_'
    || $3
    || ' BEFORE INSERT ON '
    || $3
    || ' FOR EACH ROW EXECUTE PROCEDURE month_partition_trigger_function'
    || '_'
    || $3
    || '(); '
    ;
END;
$$
language plpgsql;

-- In your application create file `sql/post_syncdb-hook.postgresql_psycopg2.sql` with contents like this: 
--SELECT month_partition_creation(
--    date_trunc('MONTH', NOW())::date,
--    date_trunc('MONTH', NOW() + INTERVAL '1 year' )::date,
--    'some_table', 'some_timestamp_field');
--SELECT month_partition_creation(
--    date_trunc('MONTH', NOW())::date,
--    date_trunc('MONTH', NOW() + INTERVAL '1 year' )::date,
--    'other_table', 'date');
