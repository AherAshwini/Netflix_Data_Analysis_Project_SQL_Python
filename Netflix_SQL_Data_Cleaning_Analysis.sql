-- DROP TABLE netflix_raw

-- --1) Handling foreign characters by creating New table
-- CREATE TABLE netflix_raw (
-- show_id varchar (10) PRIMARY KEY,
-- show_type varchar (10) NULL,
-- title text NULL,
-- director varchar (250) NULL,
-- cast_members varchar (1000) NULL,
-- country varchar (150) NULL,
-- date_added varchar (20) NULL,
-- release_year int NULL,
-- rating varchar (10) NULL,
-- duration varchar (10) NULL,
-- listed_in varchar (100) NULL,
-- description varchar (500) NULL
-- )

--2) Remove Duplicates
--There are no duplicates in show_id column so making it a primary key.
SELECT show_id, COUNT(*) 
FROM netflix_raw
GROUP BY show_id
HAVING COUNT(*) >1

-- a) Below query finds duplicate rows for title column

SELECT LOWER(title), COUNT(*)
FROM netflix_raw
GROUP BY LOWER(title)
HAVING COUNT(*)>1
ORDER BY LOWER(title)

-- b) Below query filters all the data for rows with same title.
SELECT * FROM netflix_raw
WHERE LOWER(title) IN(
SELECT LOWER(title) from netflix_raw
GROUP BY LOWER(title)
HAVING COUNT(*)>1
)
ORDER BY LOWER(title)

-- c) Below query finds duplicate rows with same title as well as same show_type.

SELECT * FROM netflix_raw
WHERE CONCAT(LOWER(title), show_type) IN (
SELECT CONCAT(LOWER(title), show_type)
FROM netflix_raw
GROUP BY LOWER(title), show_type
HAVING COUNT(*)>1
)
ORDER BY title

-- d)

