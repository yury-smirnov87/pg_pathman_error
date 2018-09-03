CREATE EXTENSION IF NOT EXISTS pg_pathman;

DROP TABLE IF EXISTS root_dict CASCADE;
DROP TABLE IF EXISTS root;
DROP TABLE IF EXISTS dict;

/*
  Step 1: Preparing initial database structure and data
*/

CREATE TABLE root (
  id BIGSERIAL NOT NULL PRIMARY KEY
);

DO
$$
DECLARE
BEGIN
  FOR r IN 1..1000 LOOP
    INSERT INTO root (id) VALUES (r);
  END LOOP;
END
$$;

CREATE TABLE root_dict (
  id         BIGSERIAL PRIMARY KEY NOT NULL,
  root_id    BIGINT                NOT NULL REFERENCES root (id) ON DELETE CASCADE,
  start_date DATE,
  num        TEXT,
  main       TEXT,
  dict_code  TEXT,
  dict_name  TEXT,
  edit_num   TEXT,
  edit_date  DATE
);

CREATE INDEX "root_dict_root_id_idx"
  ON "root_dict" ("root_id");

ALTER TABLE root_dict
  ADD COLUMN sign CHAR(4);

DO
$$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT *
           FROM root
  LOOP
    FOR d IN 1..1000 LOOP
      INSERT INTO root_dict (root_id, start_date, num, main, dict_code, dict_name, edit_num, edit_date, sign) VALUES
        (r.id, now(), 'num_' || d, (d % 2) + 1, 'code_' || d, 'name_' || d, NULL, NULL, '2014');
    END LOOP;
  END LOOP;
END
$$;

/*
  Step 2: Normalization
*/

CREATE TABLE dict (
  id   BIGSERIAL NOT NULL PRIMARY KEY,
  code TEXT      NOT NULL,
  name TEXT      NOT NULL,
  sign CHAR(4)   NOT NULL,

  UNIQUE (code, name, sign)
);

ALTER TABLE root_dict
  ADD COLUMN dict_id BIGINT;

ALTER TABLE root_dict
  ADD CONSTRAINT "root_dict_dict_id_fkey" FOREIGN KEY ("dict_id") REFERENCES dict (id) NOT VALID;


DO
$$
DECLARE
BEGIN
  FOR r IN 1..1000 LOOP
    INSERT INTO dict (id, code, name, sign) VALUES (r, 'code_' || r, 'name_' || r, '2014');
  END LOOP;
END
$$;

DO
$$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT *
           FROM root_dict
  LOOP
    UPDATE root_dict
    SET dict_id = (SELECT d.id
                   FROM dict d
                   WHERE d.code = root_dict.dict_code
                         AND d.name = root_dict.dict_name
                         AND d.sign = root_dict.sign),
      dict_code = NULL,
      dict_name = NULL,
      sign      = NULL
    WHERE id = r.id;
  END LOOP;
END
$$;


ALTER TABLE root_dict
  DROP COLUMN dict_code,
  DROP COLUMN dict_name,
  DROP COLUMN sign;

/*
  Step 3: Partitioning
*/

SELECT create_hash_partitions('root_dict' :: REGCLASS,
                              'root_id',
                              3,
                              FALSE);

SELECT partition_table_concurrently('root_dict' :: REGCLASS);

-- wait for partition_table_concurrently to finish
DO
$$
DECLARE
  count INTEGER := 0;
BEGIN
  LOOP
    SELECT count(*)
    INTO count
    FROM pathman_concurrent_part_tasks;

    EXIT WHEN count = 0;

    PERFORM pg_sleep(5);
  END LOOP;
END
$$;

VACUUM FULL ANALYZE VERBOSE "root_dict";

SELECT set_enable_parent('root_dict' :: REGCLASS, FALSE);