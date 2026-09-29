/*
RESEARCH STAGE 3: What property or host characteristics and amenities appear to be most suitable for an Airbnb property?
*/


# quick research regarding host attributes

SELECT h.host_is_superhost, COUNT(*), ROUND(AVG(l.price_euro), 2) AS avg_pricing, ROUND(AVG(l.review_scores_rating), 2) AS avg_score FROM list_c l
LEFT JOIN host_info h
	ON h.host_id = l.host_id
WHERE l.city = 'Rome'
GROUP BY 1;

SELECT h.host_has_profile_pic, COUNT(*), ROUND(AVG(l.price_euro), 2) AS avg_pricing, ROUND(AVG(l.review_scores_rating), 2) AS avg_score FROM list_c l
LEFT JOIN host_info h
	ON h.host_id = l.host_id
WHERE l.city = 'Rome'
GROUP BY 1;

SELECT h.host_identity_verified, ROUND(AVG(l.price_euro), 2) AS avg_pricing, ROUND(AVG(l.review_scores_rating), 2) AS avg_score FROM list_c l
LEFT JOIN host_info h
	ON h.host_id = l.host_id
WHERE l.city = 'Rome'
GROUP BY 1;

SELECT h.host_is_superhost AS SH, h.host_identity_verified AS VR, COUNT(*) AS N, ROUND(AVG(l.price_euro), 2) AS avg_pricing, ROUND(AVG(l.review_scores_rating), 2) AS avg_score FROM list_c l
LEFT JOIN host_info h
	ON h.host_id = l.host_id
WHERE l.city = 'Rome'
GROUP BY 1, 2;

# Note: host_total_listings_count was identified as a problematic and potentially unreliable field during the cleaning process, so these results should be interpreted with caution and should not be treated as definitive.
SELECT 
CASE
	WHEN h.host_total_listings_count = 1 THEN 'one property'
    WHEN h.host_total_listings_count BETWEEN 2 AND 5 THEN 'a few properties'
    WHEN h.host_total_listings_count BETWEEN 6 AND 10 THEN 'multiple properties'
    WHEN h.host_total_listings_count BETWEEN 11 AND 50 THEN 'large number of properties'
    WHEN h.host_total_listings_count > 50 THEN 'extremely large number of properties'
END AS host_listing_count, 
COUNT(*) AS N, ROUND(AVG(l.price_euro), 2) AS avg_pricing, ROUND(AVG(l.review_scores_rating), 2) AS avg_score FROM list_c l
LEFT JOIN host_info h
	ON h.host_id = l.host_id
WHERE h.host_total_listings_count <> 0
AND l.city = 'Rome'
GROUP BY 1
ORDER BY FIELD(host_listing_count, 'one property', 'a few properties', 'multiple properties', 'large number of properties', 'extremely large number of properties');


SELECT 
CASE
    WHEN YEAR(h.host_since) BETWEEN 2008 AND 2012 THEN 'very experienced host'
    WHEN YEAR(h.host_since) BETWEEN 2013 AND 2016 THEN 'experienced host'
    WHEN YEAR(h.host_since) BETWEEN 2017 AND 2019 THEN 'newer host'
    WHEN YEAR(h.host_since) > 2019 THEN 'beginner host'
END AS host_year_exp, 
COUNT(*) AS N, ROUND(AVG(l.price_euro), 2) AS avg_pricing, ROUND(AVG(l.review_scores_rating), 2) AS avg_review_score, ROUND(AVG(l.review_scores_communication), 2) AS avg_communication_score FROM list_c l
LEFT JOIN host_info h
	ON h.host_id = l.host_id
WHERE host_since IS NOT NULL
AND l.city = 'Rome'
GROUP BY 1
ORDER BY FIELD(host_year_exp, 'very experienced host', 'experienced host', 'newer host', 'beginner host');






# temporary tables required for main queries

# amenities

DROP TABLE IF EXISTS amenities;
CREATE TEMPORARY TABLE amenities AS
SELECT distinct l.listing_id, a.amenity
FROM list_c l
JOIN JSON_TABLE(l.amenities, '$[*]' COLUMNS (
    amenity VARCHAR(255) PATH '$'
)) a
WHERE l.city = 'rome'
AND room_type = 'entire place';

SET SQL_SAFE_UPDATES = 0;

# Group equivalent amenity names under a common category.
UPDATE amenities
SET amenity = 
CASE 
	WHEN amenity IN ('Cable TV', 'HDTV') THEN 'TV'
    WHEN amenity IN ('Nespresso machine', 'Keurig coffee machine', 'Pour-over coffee') THEN 'coffee maker'
    WHEN amenity IN ('Clothing storage: closet', 'Clothing storage: wardrobe') THEN 'Clothing storage'
    WHEN amenity IN ('Shampoo', 'Body soap', 'Shower gel') THEN 'Bathroom essentials'
    WHEN amenity IN ('Crib', 'Pack n Play/travel crib', 'Pack u2019n Play/travel crib') THEN 'Crib'
    ELSE amenity
END;


DROP TABLE IF EXISTS exp_host_rome;
CREATE TEMPORARY TABLE exp_host_rome AS 
SELECT distinct l.host_id, h.host_since, h.host_location, h.host_response_time, h.host_response_rate, h.host_acceptance_rate, h.host_is_superhost, h.host_total_listings_count, h.host_has_profile_pic, h.host_identity_verified 
FROM host_info h
JOIN list_c l
	ON h.host_id = l.host_id
WHERE host_is_superhost = 't'
AND host_total_listings_count >= 5
AND YEAR(host_since) < 2015
AND city = 'Rome';


DROP TABLE IF EXISTS recent_rev_info_rome;
CREATE TEMPORARY TABLE recent_rev_info_rome AS
SELECT lc.listing_id, COUNT(*) AS review_count FROM rev_c rc
JOIN list_c lc
	ON rc.listing_id = lc.listing_id
WHERE YEAR(date) BETWEEN 2017 AND 2019
AND date IS NOT NULL
AND city = 'Rome'
GROUP BY 1;



# researching minimum and maximum nights and bookable status


SELECT minimum_nights, count(*) FROM list_c
GROUP BY 1;

SELECT 
    CASE
		WHEN minimum_nights = 1 THEN '1 day'
        WHEN minimum_nights = 2 THEN '2 days'
        WHEN minimum_nights = 3 THEN '3 days'
        WHEN minimum_nights = 4 THEN '4 days'
        WHEN minimum_nights BETWEEN 5 AND 17 THEN '~ 1-2 weeks'
        WHEN minimum_nights BETWEEN 18 AND 31 THEN '~ 1 month'
        WHEN minimum_nights > 31 THEN 'more than 1 month'
    END AS minimum_nights_group,
    COUNT(*) AS N,
    ROUND(AVG(price_euro), 2) AS avg_pricing,
    ROUND(AVG(review_scores_rating), 2) AS avg_score,
    ROUND(SUM(review_count) / COUNT(*), 1) AS rev_per_listing
FROM list_c l
JOIN exp_host_rome eh
	ON l.host_id = eh.host_id
LEFT JOIN recent_rev_info_rome rr
	ON rr.listing_id = l.listing_id
WHERE city = 'Rome'
GROUP BY 1
ORDER BY FIELD(minimum_nights_group, '1 day', '2 days', '3 days', '4 days', '~ 1-2 weeks','~ 1 month', 'more than 1 month');


SELECT 
    CASE
        WHEN maximum_nights BETWEEN 1 AND 14 THEN '1~2 weeks'
        WHEN maximum_nights BETWEEN 15 AND 31 THEN '~ 1 month'
        WHEN maximum_nights BETWEEN 32 AND 60 THEN '1~2 months'
        WHEN maximum_nights BETWEEN 61 AND 90 THEN '2~3 months'
        WHEN maximum_nights BETWEEN 91 AND 120 THEN '3~4 months'
        WHEN maximum_nights BETWEEN 121 AND 150 THEN '4~5 months'
        WHEN maximum_nights > 150 THEN 'half a year or more'
    END AS maximum_nights_group,
    COUNT(*) AS N,
    ROUND(AVG(price_euro), 2) AS avg_pricing,
    ROUND(AVG(review_scores_rating), 2) AS avg_score,
	ROUND(SUM(review_count) / COUNT(*), 1) AS rev_per_listing
FROM list_c l
JOIN exp_host_rome eh
	ON l.host_id = eh.host_id
LEFT JOIN recent_rev_info_rome rr
	ON rr.listing_id = l.listing_id
WHERE city = 'Rome'
GROUP BY 1
ORDER BY FIELD(maximum_nights_group, '1~2 weeks', '~ 1 month', '1~2 months', '2~3 months', '3~4 months', '4~5 months', 'half a year or more');


SELECT instant_bookable, COUNT(*), ROUND(AVG(price_euro), 2) AS avg_pricing, ROUND(AVG(review_scores_rating), 2) AS avg_score, 
ROUND(SUM(review_count) / COUNT(*), 1) AS rev_per_listing, COUNT(eh.host_id) AS exp_host_pref
FROM list_c l
LEFT JOIN exp_host_rome eh
	ON l.host_id = eh.host_id
LEFT JOIN recent_rev_info_rome rr
	ON rr.listing_id = l.listing_id
WHERE city = 'Rome'
GROUP BY 1;


# No particularly notable patterns were identified from these queries, although they provided a useful overview of the distribution of minimum/maximum stay
# requirements and instant booking status.



# Amenities

# most common amenities

SELECT COUNT(distinct eh.host_id) FROM exp_host_rome eh
LEFT JOIN list_c L
	ON l.host_id = eh.host_id
WHERE room_type = 'Entire Place'
AND city = 'rome';	# 159

SELECT amenity, COUNT(distinct l.listing_id) AS N, ROUND(100 * COUNT(distinct l.listing_id) / (SELECT COUNT(*) FROM list_c WHERE city = 'rome' AND room_type = 'Entire Place'), 2) AS percentage ,
ROUND(AVG(price_euro), 2) AS avg_price, ROUND(AVG(price_euro) - (SELECT AVG(price_euro) FROM list_c WHERE city = 'rome' AND room_type = 'Entire Place'), 2) AS avg_dev, 
ROUND(AVG(l.review_scores_value), 2) AS avg_value_rating, ROUND(AVG(l.review_scores_rating), 2) AS avg_rating, ROUND(SUM(review_count) / COUNT(DISTINCT a.listing_id), 2) AS reviews_per_listing,
ROUND(100 * COUNT(distinct eh.host_id) / 159, 2) AS exp_host_N
FROM amenities a
LEFT JOIN list_c l
	ON l.listing_id = a.listing_id
LEFT JOIN recent_rev_info_rome rr
	ON l.listing_id = rr.listing_id
LEFT JOIN exp_host_rome eh
	ON l.host_id = eh.host_id
WHERE room_type = 'Entire Place'
AND city = 'rome'
#AND neighbourhood = 'I Centro Storico'
GROUP BY 1
HAVING N > 500
ORDER BY 2 DESC
;


# researching amount of amenities listed 

SELECT AVG(JSON_LENGTH(amenities)), stddev_pop(JSON_LENGTH(amenities)) FROM list_c;

SELECT 
CASE 
	WHEN JSON_LENGTH(amenities) < 6 THEN '1~5'
    WHEN JSON_LENGTH(amenities) BETWEEN 6 AND 10 THEN '6~10'
    WHEN JSON_LENGTH(amenities) BETWEEN 11 AND 15 THEN '11~15'
    WHEN JSON_LENGTH(amenities) BETWEEN 16 AND 20 THEN '16~20'
    WHEN JSON_LENGTH(amenities) BETWEEN 21 AND 25 THEN '21~25'
    WHEN JSON_LENGTH(amenities) BETWEEN 26 AND 30 THEN '26~30'
	WHEN JSON_LENGTH(amenities) BETWEEN 31 AND 35 THEN '31~35'
	WHEN JSON_LENGTH(amenities) BETWEEN 36 AND 40 THEN '36~40'
    ELSE 'more than 40'
END AS amenities_amount, COUNT(*) AS N, ROUND(AVG(price_euro), 2) AS avg_price, ROUND(AVG(l.review_scores_value), 2) AS avg_value_rating, 
ROUND(AVG(l.review_scores_rating), 2) AS avg_rating, ROUND(SUM(review_count) / COUNT(*), 2) AS reviews_per_listing, COUNT(eh.host_id) AS exp_hosts
FROM list_c l
LEFT JOIN recent_rev_info_rome rr
	ON l.listing_id = rr.listing_id
LEFT JOIN exp_host_rome eh
	ON l.host_id = eh.host_id
WHERE city = 'rome'
AND room_type = 'entire place'
AND accommodates BETWEEN 4 AND 6
#AND neighbourhood = 'I Centro Storico'
GROUP BY 1
ORDER BY MIN(JSON_LENGTH(amenities)) ASC;




# Procedure for comparing listing attributes with and without a specific amenity.

DROP TABLE IF EXISTS amenity_list;
CREATE TABLE amenity_list AS
SELECT a.amenity
FROM list_c l
JOIN JSON_TABLE(
	l.amenities,'$[*]' COLUMNS (amenity VARCHAR(255) PATH '$')
) a
WHERE l.city = 'Rome'
AND l.room_type = 'Entire place'
GROUP BY a.amenity
HAVING COUNT(*) > 500;

ALTER TABLE amenity_list
ADD COLUMN percentage_with_amenity DECIMAL(6,2),
ADD COLUMN price_difference DECIMAL(10,2),
ADD COLUMN score_difference DECIMAL(10,2),
ADD COLUMN value_difference DECIMAL(10,2);


DROP PROCEDURE IF EXISTS update_amenity_differences;

DELIMITER //

CREATE PROCEDURE update_amenity_differences()
BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE v_amenity VARCHAR(255);
	DECLARE cur CURSOR FOR SELECT al.amenity FROM amenity_list al;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	OPEN cur;

	read_loop: LOOP
		FETCH cur INTO v_amenity;
		IF done THEN LEAVE read_loop; END IF;

		UPDATE amenity_list
		SET
	price_difference = (
		SELECT AVG(CASE WHEN JSON_CONTAINS(l.amenities, JSON_QUOTE(v_amenity)) THEN l.price_euro END) -
		       AVG(CASE WHEN NOT JSON_CONTAINS(l.amenities, JSON_QUOTE(v_amenity)) THEN l.price_euro END)
		FROM list_c l
		WHERE l.amenities IS NOT NULL AND l.city = 'Rome' AND l.room_type = 'Entire place'
	),

	score_difference = (
		SELECT AVG(CASE WHEN JSON_CONTAINS(l.amenities, JSON_QUOTE(v_amenity)) THEN l.review_scores_rating END) -
		       AVG(CASE WHEN NOT JSON_CONTAINS(l.amenities, JSON_QUOTE(v_amenity)) THEN l.review_scores_rating END)
		FROM list_c l
		WHERE l.amenities IS NOT NULL AND l.city = 'Rome' AND l.room_type = 'Entire place'
	),

	value_difference = (
		SELECT AVG(CASE WHEN JSON_CONTAINS(l.amenities, JSON_QUOTE(v_amenity)) THEN l.review_scores_value END) -
		       AVG(CASE WHEN NOT JSON_CONTAINS(l.amenities, JSON_QUOTE(v_amenity)) THEN l.review_scores_value END)
		FROM list_c l
		WHERE l.amenities IS NOT NULL AND l.city = 'Rome' AND l.room_type = 'Entire place'
	),
    percentage_with_amenity = (
    SELECT 100.0 * SUM(CASE WHEN JSON_CONTAINS(l.amenities, JSON_QUOTE(v_amenity)) THEN 1 ELSE 0 END) / COUNT(*)
    FROM list_c l
    WHERE l.amenities IS NOT NULL
      AND l.city = 'Rome'
      AND l.room_type = 'Entire place'
)
		WHERE amenity_list.amenity = v_amenity;
	END LOOP;

	CLOSE cur;
END //

DELIMITER ;

SET SQL_SAFE_UPDATES = 0;

CALL update_amenity_differences();


SELECT * FROM amenity_list;
