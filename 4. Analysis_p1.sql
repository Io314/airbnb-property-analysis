/*
ANALYSIS OBJECTIVE
Evaluate whether publicly available Airbnb listing data can help a prospective
host identify a potentially suitable property to acquire.

*/

/*
RESEARCH STAGE 1: Which cities and neighbourhoods appear to be more suitable locations for an Airbnb property?
*/

# First comparison of the main city-level parameters to determine which measures should be used in the location analysis.

SELECT city, 
	COUNT(*) AS N, 
	COUNT(DISTINCT host_id) AS unique_hosts,
    ROUND(AVG(price_euro), 0) AS average_price, 
    ROUND(AVG(review_scores_rating), 2) AS avg_review_score,
    ROUND(AVG(review_scores_rating) - (SELECT AVG(review_scores_rating) FROM list_c), 2) AS review_score_deviation_from_avg,
    SUM(lr.review_count) AS total_reviews
FROM list_c l
JOIN listing_rev_info lr
	ON l.listing_id = lr.listing_id
GROUP BY 1;


# Creating various temporary tables that will be needed for the main query

# Review change from 2019 to 2020, used to examine the effect of the COVID period.

CREATE TEMPORARY TABLE covid_hit AS (
WITH rev_temp AS (
SELECT city, YEAR(date) AS y, COUNT(*) AS rev_count FROM list_c l
LEFT JOIN rev_c c
	ON c.listing_id = l.listing_id
WHERE YEAR(date) IS NOT NULL
GROUP BY 1,2
HAVING y BETWEEN 2019 AND 2020
ORDER BY 1,2
),
rev_lag AS (
SELECT  city, y, rev_count, LAG(rev_count) OVER (PARTITION BY city ORDER BY y) AS previous_year_reviews FROM rev_temp
)

SELECT city, y, rev_count, previous_year_reviews, ROUND((rev_count - previous_year_reviews) / previous_year_reviews * 100, 2) AS pct_change FROM rev_lag
WHERE y = 2020
);


# table for limiting reviews to those dated in desired years

DROP TABLE IF EXISTS recent_rev_info;
CREATE TEMPORARY TABLE recent_rev_info AS
SELECT listing_id, COUNT(*) AS review_count FROM rev_c
WHERE YEAR(date) BETWEEN 2017 AND 2019
AND date IS NOT NULL
GROUP BY 1;


# a table for checking review distribution

DROP TABLE IF EXISTS r_distribution;
CREATE TEMPORARY TABLE r_distribution AS (
SELECT
    l.city,
    COUNT(DISTINCT l.listing_id) AS total_listings,
    COUNT(DISTINCT r.listing_id) AS listings_with_reviews,
    ROUND(
        COUNT(DISTINCT r.listing_id) /
        COUNT(DISTINCT l.listing_id) * 100,
        2
    ) AS pct_with_reviews,
    COUNT(r.listing_id) AS reviews_2019,
    ROUND(
        COUNT(r.listing_id) /
        COUNT(DISTINCT l.listing_id),
        2
    ) AS reviews_per_reviewed_listing
FROM list_c l
LEFT JOIN rev_c r
    ON l.listing_id = r.listing_id
    AND YEAR(r.date) = 2019
GROUP BY l.city
ORDER BY reviews_per_reviewed_listing DESC
);


# temporary table to calculate experienced host frequency in cities

DROP TABLE IF EXISTS temp1;
CREATE TEMPORARY TABLE temp1 AS
WITH temp3 AS 
(
	SELECT city, COUNT(DISTINCT(host_id)) AS host_N FROM list_c
    GROUP BY 1
)

SELECT l.city, 
	COUNT(DISTINCT l.host_id) AS experienced_hosts,
    RANK () OVER (ORDER BY COUNT(DISTINCT l.host_id) ASC) AS major_host_rnk, 	# rank 1 = least experienced hosts 
    ROUND(100 * COUNT(DISTINCT l.host_id) / host_N, 1) AS exp_host_percentage,
    RANK () OVER (ORDER BY COUNT(DISTINCT l.host_id) / host_N ASC) AS major_host_perc_rnk
FROM list_c l
JOIN host_info h
	ON h.host_id = l.host_id
JOIN temp3 t
	ON l.city = t.city
WHERE host_is_superhost = 't'
AND host_total_listings_count >= 5
AND YEAR(host_since) < 2015
GROUP BY 1;


# Final queries comparing various parameters for each city

WITH t1 AS (
SELECT l.city,
	COUNT(*) AS N,
    ROUND(AVG(price_euro), 0) AS avg_price, 
	CONCAT((SELECT ROUND(AVG(review_scores_rating), 2) FROM list_c),  
		IF(ROUND(AVG(review_scores_rating) - (SELECT AVG(review_scores_rating) FROM list_c), 2) >= 0,' + ', '- ') , 
        ABS(ROUND(AVG(review_scores_rating) - (SELECT AVG(review_scores_rating) FROM list_c), 2))) AS rating_dev_from_avg,
	SUM(lr.review_count) AS total_reviews,
    ROUND(COUNT(*) / area_km2, 2) AS property_density,
    ROUND((SUM(lr.review_count) ) / COUNT(*), 2) AS reviews_per_listing
FROM list_c l
LEFT JOIN recent_rev_info lr
	ON l.listing_id = lr.listing_id
JOIN city_area a
	ON a.city = l.city
GROUP BY 1, area_km2
ORDER BY 6 DESC)

SELECT t1.*, temp1.major_host_rnk, temp1.exp_host_percentage, ch.pct_change, 
ROUND(reviews_per_listing * (1 + pct_change / 100), 2) AS adjusted_index, rd.pct_with_reviews AS listiings_with_reviews_perc , reviews_per_reviewed_listing
FROM t1 
LEFT JOIN temp1
	ON t1.city = temp1.city
JOIN covid_hit ch
	ON ch.city = t1.city
JOIN r_distribution	rd
	ON rd.city = t1.city
;



# general demand increase/ decrease over 2017 ~ 2019

WITH rev_temp AS (
SELECT city, YEAR(date) AS y, COUNT(*) AS rev_count FROM list_c l
LEFT JOIN rev_c c
	ON c.listing_id = l.listing_id
WHERE YEAR(date) IS NOT NULL
GROUP BY 1,2
HAVING y BETWEEN 2016 AND 2019
ORDER BY 1,2
),
rev_lag AS (
SELECT  city, y, rev_count, LAG(rev_count) OVER (PARTITION BY city ORDER BY y) AS previous_year_reviews FROM rev_temp
)

SELECT city, y, rev_count, previous_year_reviews, rev_count - previous_year_reviews AS number_diff, ROUND((rev_count - previous_year_reviews) / previous_year_reviews * 100, 2) AS pct_change FROM rev_lag
WHERE y BETWEEN 2017 AND 2019
ORDER BY city, y;





# first look at neighbourhoods

SELECT neighbourhood, count(*) AS N, ROUND(AVG(price_euro), 0) AS avg_price FROM list_c 
WHERE city = 'Rome'
GROUP BY 1;



# temporary tables required for the main query

# for limiting reviews to those dated in desired years (repeated for accessibility)

DROP TABLE IF EXISTS recent_rev_info_rome;
CREATE TEMPORARY TABLE recent_rev_info_rome AS
SELECT lc.listing_id, COUNT(*) AS review_count FROM rev_c rc
JOIN list_c lc
	ON rc.listing_id = lc.listing_id
WHERE YEAR(date) BETWEEN 2017 AND 2019
AND date IS NOT NULL
AND city = 'Rome'
GROUP BY 1;

# Review distribution is not included from this stage onward, as it did not provide additional information than the review count metric.


# temporary table to calculate experienced host frequency in cities

DROP TABLE IF EXISTS temp1_rome;
CREATE TEMPORARY TABLE temp1_rome AS
WITH temp3_rome AS 
(
	SELECT neighbourhood, COUNT(DISTINCT(host_id)) AS host_N FROM list_c
    WHERE city = 'Rome'
    GROUP BY 1
)

SELECT l.neighbourhood, 
	COUNT(DISTINCT l.host_id) AS experienced_hosts,
    RANK () OVER (ORDER BY COUNT(DISTINCT l.host_id) ASC) AS major_host_rnk, 	# rank 1 = least experienced hosts in area
    ROUND(100 * COUNT(DISTINCT l.host_id) / host_N, 1) AS exp_host_percentage,
    RANK () OVER (ORDER BY COUNT(DISTINCT l.host_id) / host_N ASC) AS major_host_perc_rnk
FROM list_c l
JOIN host_info h
	ON h.host_id = l.host_id
JOIN temp3_rome t
	ON l.neighbourhood = t.neighbourhood
WHERE host_is_superhost = 't'
AND host_total_listings_count >= 5		# Potentially unreliable, but retained here as it was not expected to materially affect this analysis.
AND YEAR(host_since) < 2015
AND l.city = 'Rome'
GROUP BY 1;


# Comparing the neighbourhoods

WITH t1_rome AS (
SELECT l.neighbourhood,
	COUNT(*) AS N,
    ROUND(AVG(price_euro), 0) AS avg_price, 
	(SELECT ROUND(AVG(review_scores_rating), 2) FROM list_c WHERE city = 'rome') AS avg_review_score,  
	ROUND(AVG(review_scores_rating) - (SELECT AVG(review_scores_rating) FROM list_c WHERE city = 'rome'), 2) AS rating_dev_from_avg,
	(SELECT ROUND(AVG(review_scores_location), 2) FROM list_c WHERE city = 'rome') AS avg_location_score,  
	ROUND(AVG(review_scores_location) - (SELECT AVG(review_scores_location) FROM list_c WHERE city = 'rome'), 2) AS loc_dev_from_avg,
	SUM(lr.review_count) AS total_reviews,
    ROUND((SUM(lr.review_count) ) / COUNT(*), 2) AS reviews_per_listing
FROM list_c l
LEFT JOIN recent_rev_info_rome lr
	ON l.listing_id = lr.listing_id
WHERE l.city = 'rome'
GROUP BY 1)

SELECT t1_rome.*, temp1_rome.major_host_rnk, temp1_rome.exp_host_percentage
FROM t1_rome
LEFT JOIN temp1_rome
	ON t1_rome.neighbourhood = temp1_rome.neighbourhood
ORDER BY 9 DESC
;

# The queries were also modified to group by both neighbourhood and room type to check for differences in neighbourhoods within specific room types, but no significant differences were found.