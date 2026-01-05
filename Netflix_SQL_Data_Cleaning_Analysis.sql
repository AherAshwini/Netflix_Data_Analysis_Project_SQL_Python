-- DROP TABLE netflix_raw

-- --1) Handling foreign characters by creating New table.
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

-- a) Below query finds duplicate rows for title column.
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

-- d) Now, drop the rows with duplicate show_type and title, and select required columns.
WITH my_cte AS( 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY LOWER(title), show_type ORDER BY show_id) AS RN
FROM netflix_raw
ORDER BY show_id)
SELECT show_id, show_type, title, CAST(date_added AS date) AS date_added, release_year,
rating, duration, description
FROM my_cte
WHERE RN = 1

-- e) Create new table for listed_in, director, country, cast.
---- 1) New table for director
SELECT show_id, TRIM(regexp_split_to_table(director, ',')) AS director
INTO netflix_directors
FROM netflix_raw

---- 2) New table for country
SELECT show_id, TRIM(regexp_split_to_table(country, ',')) AS country
INTO netflix_country
FROM netflix_raw

---- 3) New table for listed_in
SELECT show_id, TRIM(regexp_split_to_table(listed_in, ',')) AS genre
INTO netflix_genre
FROM netflix_raw

---- 4) New table for cast_members
SELECT show_id, TRIM(regexp_split_to_table(cast_members, ',')) AS cast_members
INTO netflix_cast
FROM netflix_raw

-- f) Populate missing values in country column.
INSERT INTO netflix_country
SELECT show_id, m.country
FROM netflix_raw nr
INNER JOIN (
SELECT director, country 
FROM netflix_directors nd
INNER JOIN netflix_country nc ON nd.show_id = nc.show_id
GROUP BY director, country
) m on nr.director = m.director
WHERE nr.country is NULL

-- g) Populate missing values for duration column and create final new table as netflix table.
WITH my_cte AS( 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY LOWER(title), show_type ORDER BY show_id) AS RN
FROM netflix_raw
ORDER BY show_id)
SELECT show_id, show_type, title, CAST(date_added AS date) AS date_added, release_year,
rating, CASE WHEN duration IS NULL THEN rating ELSE duration END AS duration, description
INTO netflix
FROM my_cte

/*Netflix Data Analysis*/

/* 1) For each director, count the no of movies and tv shows created by them in separate columns
for directors who have created tv shows and movies both */
SELECT nd.director, COUNT(DISTINCT CASE WHEN n.show_type = 'Movie' THEN n.show_id END) AS no_of_movies,
COUNT(DISTINCT CASE WHEN n.show_type = 'TV Show' THEN n.show_id END) AS no_of_shows
FROM netflix n
JOIN netflix_directors nd ON n.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT n.show_type) > 1

-- 2) Which country has highest number of comedy movies?
WITH my_cte AS(
SELECT DISTINCT n.show_id, n.show_type, nc.country, ng.genre
FROM netflix n
INNER JOIN netflix_country nc ON n.show_id = nc.show_id
INNER JOIN netflix_genre ng ON n.show_id = ng.show_id
WHERE show_type = 'Movie' AND genre = 'Comedies')
SELECT country, COUNT(*) AS no_of_movies
FROM my_cte
GROUP BY country
ORDER BY no_of_movies DESC
LIMIT 1

/* 3) For each year, (as per date added to netflix), 
which director has maximum number of movies released ? */
WITH my_cte1 AS(
SELECT nd.director, EXTRACT(YEAR FROM n.date_added) AS year_added, 
COUNT(DISTINCT n.show_id) AS no_of_movies
FROM netflix n
JOIN netflix_directors nd ON n.show_id = nd.show_id
WHERE show_type = 'Movie'
GROUP BY nd.director, EXTRACT(YEAR FROM n.date_added)
),
my_cte2 AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY year_added ORDER BY no_of_movies DESC, director) AS RN
FROM my_cte1)
SELECT * FROM my_cte2
WHERE RN = 1
ORDER BY year_added

-- 4) What is the average duration of movies in each genre?
WITH my_cte AS(
SELECT ng.genre, n.duration
FROM netflix n
JOIN netflix_genre ng ON n.show_id = ng.show_id
WHERE show_type = 'Movie'
)
SELECT genre, AVG(CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g')AS INT)) AS average_duration
FROM my_cte
GROUP BY genre
ORDER BY genre

/* 5) Find the list of directors who have created horror and comedy movies both.
 Display director names along with number of comedy and horror movies directed by them. */
SELECT nd.director, COUNT(DISTINCT CASE WHEN ng.genre = 'Comedies' THEN n.show_id end) AS no_of_comedy_movies, 
COUNT(DISTINCT CASE WHEN ng.genre = 'Horror Movies' THEN n.show_id end) AS no_of_horror_movies
FROM netflix_directors nd
JOIN netflix_genre ng ON nd.show_id = ng.show_id
JOIN netflix n ON n.show_id = nd.show_id
WHERE show_type = 'Movie' AND ng.genre IN ('Horror Movies', 'Comedies')
GROUP BY nd.director
HAVING COUNT(DISTINCT ng.genre) = 2
ORDER BY nd.director

















