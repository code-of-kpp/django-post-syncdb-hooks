DROP AGGREGATE IF EXISTS sum(BOOLEAN);

CREATE OR REPLACE FUNCTION add(INTEGER, BOOLEAN)
returns INTEGER AS $$
    SELECT $1 + $2::INTEGER AS result;
$$
LANGUAGE plpgsql;

CREATE AGGREGATE sum (BOOLEAN)
(
    sfunc = add,
    stype = INTEGER,
    initcond = '0'
);
