/*
RESEARCH STAGE 2: What room type and property size appear to be more suitable for an Airbnb property?
*/

# temporary tables

# for limiting reviews to those dated in desired years

DROP TABLE IF EXISTS recent_rev_info_rome;
CREATE TEMPORARY TABLE recent_rev_info_rome AS
SELECT lc.listing_id, COUNT(*) AS review_count FROM rev_c rc
JOIN list_c lc
	ON rc.listing_id = lc.listing_id
WHERE YEAR(date) BETWEEN 2017 AND 2019
AND date IS NOT NULL
AND city = 'Rome'
GROUP BY 1;


# Temporary table to calculate experienced host frequency in each neighbourhood and bedroom count for entire-place listings.

DROP TABLE IF EXISTS temp1_room;
CREATE TEMPORARY TABLE temp1_room AS
WITH temp3_room AS 
(
	SELECT neighbourhood, room_type, COUNT(DISTINCT(host_id)) AS host_N FROM list_c
    WHERE city = 'Rome'
    AND neighbourhood IN ('I Centro Storico','VII San Giovanni/Cinecitta','II Parioli/Nomentano')
    GROUP BY 1, 2
)

SELECT l.neighbourhood, l.room_type, 
	COUNT(DISTINCT l.host_id) AS experienced_hosts,
    RANK () OVER (PARTITION BY l.neighbourhood ORDER BY COUNT(DISTINCT l.host_id) ASC) AS major_host_rnk, 	# rank 1 = least experienced hosts
    ROUND(100 * COUNT(DISTINCT l.host_id) / t.host_N, 1) AS exp_host_percentage,
    RANK () OVER (PARTITION BY l.neighbourhood ORDER BY COUNT(DISTINCT l.host_id) / host_N ASC) AS major_host_perc_rnk
FROM list_c l
JOIN host_info h
	ON h.host_id = l.host_id
JOIN temp3_room t
    ON l.room_type = t.room_type
    AND l.neighbourhood = t.neighbourhood
WHERE host_is_superhost = 't'
AND host_total_listings_count >= 5
AND YEAR(host_since) < 2015
AND l.city = 'Rome'
AND l.neighbourhood IN ('I Centro Storico','VII San Giovanni/Cinecitta','II Parioli/Nomentano')
GROUP BY 1, 2;


# Comparing the room types for the chosen neighbourhoods

WITH t1_room AS (
SELECT l.neighbourhood, l.room_type,
	COUNT(*) AS N,
    ROUND(AVG(price_euro), 0) AS avg_price, 
	(SELECT ROUND(AVG(review_scores_rating), 2) FROM list_c WHERE city = 'rome') AS avg_review_score,  
	ROUND(AVG(review_scores_rating) - (SELECT AVG(review_scores_rating) FROM list_c WHERE city = 'rome'), 2) AS rating_dev_from_avg,
	SUM(lr.review_count) AS total_reviews,
    ROUND((SUM(lr.review_count) ) / COUNT(*), 2) AS reviews_per_listing
FROM list_c l
LEFT JOIN recent_rev_info_rome lr
	ON l.listing_id = lr.listing_id
WHERE l.city = 'rome'
AND l.neighbourhood IN ('I Centro Storico','VII San Giovanni/Cinecitta','II Parioli/Nomentano')
GROUP BY 1, 2)

SELECT t1_room.*, temp1_room.major_host_rnk, temp1_room.exp_host_percentage
FROM t1_room
LEFT JOIN temp1_room
    ON t1_room.room_type = temp1_room.room_type
	AND t1_room.neighbourhood = temp1_room.neighbourhood
ORDER BY 1, 2;



# accommodates / bedrooms research

# temporary tables required for main query

# for limiting reviews to those dated in desired years

DROP TABLE IF EXISTS recent_rev_info_rome;
CREATE TEMPORARY TABLE recent_rev_info_rome AS
SELECT lc.listing_id, COUNT(*) AS review_count FROM rev_c rc
JOIN list_c lc
	ON rc.listing_id = lc.listing_id
WHERE YEAR(date) BETWEEN 2017 AND 2019
AND date IS NOT NULL
AND city = 'Rome'
GROUP BY 1;


# temporary table to calculate experienced host frequency in our neighbourhoods per bedrooms count

DROP TABLE IF EXISTS temp1_acc;
CREATE TEMPORARY TABLE temp1_acc AS
WITH temp3_acc AS 
(
	#SELECT accommodates, COUNT(DISTINCT(host_id)) AS host_N FROM list_c
    SELECT bedrooms, COUNT(DISTINCT(host_id)) AS host_N FROM list_c
    WHERE city = 'Rome'
    AND neighbourhood IN ('I Centro Storico','VII San Giovanni/Cinecitta','II Parioli/Nomentano')
    AND room_type = 'entire place'
    GROUP BY 1
)

#SELECT l.neighbourhood, l.accommodates,
SELECT l.bedrooms,
	COUNT(DISTINCT l.host_id) AS experienced_hosts,
    RANK () OVER (ORDER BY COUNT(DISTINCT l.host_id) ASC) AS major_host_rnk, 	# rank 1 = least experienced hosts
    ROUND(100 * COUNT(DISTINCT l.host_id) / host_N, 1) AS exp_host_percentage,
    RANK () OVER (ORDER BY COUNT(DISTINCT l.host_id) / host_N ASC) AS major_host_perc_rnk
FROM list_c l
JOIN host_info h
	ON h.host_id = l.host_id
JOIN temp3_acc t
    #ON l.accommodates = t.accommodates
    ON l.bedrooms = t.bedrooms
WHERE host_is_superhost = 't'
AND host_total_listings_count >= 5
AND YEAR(host_since) < 2015
AND l.city = 'Rome'
AND l.neighbourhood IN ('I Centro Storico','VII San Giovanni/Cinecitta','II Parioli/Nomentano')
AND room_type = 'entire place'
GROUP BY 1;


# main query

WITH t1_acc AS (
#SELECT l.accommodates,
SELECT l.bedrooms,
	COUNT(*) AS N,
    ROUND(AVG(price_euro), 0) AS avg_price, 
	(SELECT ROUND(AVG(review_scores_rating), 2) FROM list_c WHERE city = 'rome' AND room_type = 'entire place') AS avg_review_score,  
	ROUND(AVG(review_scores_rating) - (SELECT AVG(review_scores_rating) FROM list_c WHERE city = 'rome' AND room_type = 'entire place'), 2) AS rating_dev_from_avg,
	SUM(lr.review_count) AS total_reviews,
    ROUND((SUM(lr.review_count) ) / COUNT(*), 2) AS reviews_per_listing
FROM list_c l
LEFT JOIN recent_rev_info_rome lr
	ON l.listing_id = lr.listing_id
WHERE l.city = 'rome'
AND l.neighbourhood IN ('I Centro Storico','VII San Giovanni/Cinecitta','II Parioli/Nomentano')
AND room_type = 'entire place'
GROUP BY 1)

SELECT t1_acc.*, temp1_acc.major_host_rnk, temp1_acc.exp_host_percentage
FROM t1_acc
LEFT JOIN temp1_acc
    #ON t1_acc.accommodates = temp1_acc.accommodates
    ON t1_acc.bedrooms = temp1_acc.bedrooms
#WHERE t1_acc.neighbourhood = 'I Centro Storico'
#WHERE t1_acc.neighbourhood = 'VII San Giovanni/Cinecitta'
# WHERE t1_acc.neighbourhood = 'II Parioli/Nomentano'
WHERE t1_acc.bedrooms IS NOT NULL
ORDER BY 1, 2 ASC
;
