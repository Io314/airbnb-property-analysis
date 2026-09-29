SET SQL_SAFE_UPDATES = 0;

# listing id
# it is a primary key so we know there are no dupes

SELECT * FROM listings
WHERE listing_id = 0;


# listing name 
SELECT * FROM listings
WHERE TRIM(listing_name) = ''
OR listing_name IS NULL;

# there are 171 instances of Null name, however, since the name of the listing is mostly irrelevant we do not mind keeping them in the dataset as long as the other fields seem proper.


# host id

SELECT * FROM listings
WHERE host_id IS NULL
OR host_id <= 0;

# Each host should have the same host_since date across their listings.
# Grouping by both host_id and host_since should therefore produce one row per host. Hosts with N > 1 have conflicting host_since values.

SELECT host_id, count(*) AS N FROM				
(												
	SELECT host_id, host_since FROM listings
	GROUP BY 1, 2
) TEMP
GROUP BY 1
HAVING N > 1;

# 1 host detected
SELECT * FROM listings
WHERE host_id = 39368584;

SELECT count(*) FROM reviews
WHERE listing_id IN 
(
SELECT listing_id FROM listings 
WHERE host_id = 39368584
);

# The host represented only 3 listings, and host-level inconsistencies were ultimately handled through grouping in the later analysis.


# host since
SELECT count(*) FROM listings
#WHERE host_since IS NULL
WHERE host_since = 0;

UPDATE listings
SET host_since = NULL 
WHERE host_since = 0;

SELECT MIN(host_since), MAX(host_since) FROM listings;

SELECT host_id FROM listings
WHERE host_id IN (
SELECT distinct(host_id) FROM listings
WHERE host_since IS NULL)
AND host_since IS NOT NULL;

#  NULL values do exist in "host_since" column. The attempt to see if they can be filled in by checking the host's other listings failed as these hosts dont have other entries.


# Host location

SELECT count(*) FROM listings
WHERE TRIM(host_location) = ''
OR host_location IS NULL			# 833 NULLs
;

SELECT count(distinct(host_location)) FROM listings;	#7151 distinct

# Host location contains many different formats, making reliable extraction of city/country difficult.

# Several attempts were made to determine whether hosts were located in the same city as their listing, but the approach was dropped due to the high
# possibility of false negatives. For example, in the France data, around 1/3 of negative classifications had locations listed only as "France" or "FR".

# Host proximity was therefore excluded from the analysis. A separate variable, "greeted by host", was considered a more relevant indicator for this purpose.


SELECT 
(SELECT COUNT(*) FROM (
SELECT host_id, host_location FROM listings
GROUP BY 1,2
) A),
count(distinct(host_id)) FROM listings;

# all hosts except for 2 always have the same host location

SELECT * FROM listings
WHERE host_id IN 
(
SELECT host_id FROM
	(
	SELECT host_id, host_location FROM listings
	GROUP BY 1,2
    ) a
GROUP BY 1
HAVING count(*) > 1
);

# The 2 hosts that have more than 1 host location do so because of a NULL value. Seeing that the rest of their rows for all listings have problems and due to their insignificance there is no need to update


# host response time
SELECT host_response_time, COUNT(*) FROM listings
GROUP BY 1;

UPDATE listings
SET host_response_time = NULL
WHERE host_response_time = '1'
OR host_response_time = '0';

# confirming each host has the same "host_response_time" in all their entries.
# if all hosts have the same response time grouping both should give us as many results as grouping only the hosts.

SELECT count(*), (SELECT count(distinct(host_id)) FROM listings) AS total_hosts FROM 
(
SELECT host_id, host_response_time FROM listings
GROUP BY 1, 2											
) a;


CREATE TEMPORARY TABLE t1 AS 			# list of all host_ids that had more than 1 host_response_time value
	SELECT host_id FROM 
		(
		SELECT host_id, host_response_time FROM listings
		GROUP BY 1, 2
		) a
	GROUP BY 1
	HAVING count(*) > 1;

SELECT host_id, host_response_time FROM listings		# taking a look at the rows in more detail
WHERE host_id IN (SELECT * FROM t1)
GROUP BY 1, 2;


# Inconsistent values will be resolved later when handling NULL values and organizing the host-level information.


# host response rate, host acceptance rate

SELECT host_response_rate, COUNT(*) FROM listings
GROUP BY 1;

SELECT host_acceptance_rate, count(*) FROM listings
GROUP BY 1;


# host total listings

SELECT host_total_listings_count, COUNT(*) FROM listings
GROUP BY 1;

# values of 0 can be found in host_total_listings_count which can't be true as they have at least 1 listing by being in the dataset. 
# In general we excpect the following to be true for hosts listing count: 
#	1) Provided this dataset contains all listings on airbnb at specific time snapshot and that the hosts "total_listings_count" is the number of all the listings they have up right now, it makes sense that
#	   the listing_count will be more than or equal to the host's number of appearances in the dataset (it could be more if the host has listings in cities other than the 10 in our dataset)
#	2) the minimum and maximum listings_count throughout all their listings in the dataset should be the same number


# Lets check to see how many listings each of these hosts (detected with a value of 0) have by grouping their id

SELECT COUNT(*) FROM 					# Count how many hosts have a 0 in total_listings_count
(
SELECT host_id, count(*), max(host_total_listings_count) FROM listings	# a view on how many times each of these hosts appear in the dataset. Meaning, how many total_listings they should have at least
WHERE host_id IN (														# as well as their max value in the field in case we can retrieve the info from their other listings
SELECT distinct(host_id) FROM listings
WHERE host_total_listings_count = 0)
GROUP BY 1
ORDER BY 2 DESC
) A;
# 25.724 distinct hosts. with the top 5 having 627, 295, 189, 151, 65 listings.



# comparing hosts' total rows count in the dataset vs their max and min entry in their "host_total_listings_count" columns. 
SELECT host_id, count(*) AS total_appearances, MAX(host_total_listings_count) AS max_count, MIN(host_total_listings_count) AS min_count FROM listings
GROUP BY 1
HAVING max_count - min_count <> 0		# checking how many hosts don't have the same number of max and min
ORDER BY 2 DESC;

# The vast majority of hosts have the same max and min, with only 6 being the exception (and with a small variation except for 1 case).
# the difference is small enough that will not affect the analysis so we can leave as is, for now, for all except the host with a difference of ~1000

SELECT * FROM listings WHERE host_id = 344804377;

# this host seems to have a different value based on the city the listing is from (in all cities it is 64 except for mexico city and istabul)
# Nonetheless as it is the only host with such a drastic change, we will set these values to NULL

UPDATE listings
SET host_total_listings_count = NULL
WHERE host_id = 344804377;


# this query counts how many times each host_id exists in dataset (in other words, how many listings they have in our dataset), each host's max value for host_response_time in the dataset 
# and then checks their relative size (when they are equal, or when each is larger than the other)
SELECT 
    (SELECT 
            COUNT(*)
        FROM
            (SELECT 
                host_id,
                    COUNT(*) AS total_appearances,
                    MAX(host_total_listings_count) AS max_count
            FROM
                listings
            GROUP BY 1
            HAVING total_appearances - max_count = 0) a) AS equal,
    (SELECT 
            COUNT(*)
        FROM
            (SELECT 
                host_id,
                    COUNT(*) AS total_appearances,
                    MAX(host_total_listings_count) AS max_count
            FROM
                listings
            GROUP BY 1
            HAVING total_appearances - max_count < 0) b) AS max_larger,
    (SELECT 
            COUNT(*)
        FROM
            (SELECT 
                host_id,
                    COUNT(*) AS total_appearances,
                    MAX(host_total_listings_count) AS max_count
            FROM
                listings
            GROUP BY 1
            HAVING total_appearances - max_count > 0) b) AS total_larger,
    (SELECT 
            COUNT(*)
        FROM
            (SELECT 
                host_id,
                    COUNT(*) AS total_appearances,
                    MAX(host_total_listings_count) AS max_count
            FROM
                listings
            GROUP BY 1
            HAVING max_count IS NULL) c) AS null_values,
    (SELECT 
            COUNT(DISTINCT (host_id)) AS sum_of_the_3_should_be
        FROM
            listings) AS theoretical_sum_for_cross_checking;

# The number being equal and the total_listings_count max being higher is no problem as stated earlier. However we see a large number of values that need to be looked into.
# 30653 hosts have a smaller number of listings in their column than their appearances in the datset. 25724 of them are the afforementioned hosts with a value of 0, thus we have a total of
# 4929 hosts that have a peculiar value.


# checking how big the difference (count() - max(total_listings)) is
SELECT COUNT(*) FROM LISTINGS WHERE HOST_ID IN ( SELECT host_id FROM (
SELECT 
	host_id,
		COUNT(*) AS total_appearances,
		MAX(host_total_listings_count) AS max_count,
		MIN(host_total_listings_count) AS min_count,
        COUNT(*) - MAX(host_total_listings_count) AS diff
FROM
	listings
GROUP BY 1
HAVING diff > 0
#AND max_count <> 0
ORDER BY diff DESC
) A );

# These values are problematic, as some hosts have fewer listings in this column than their number of appearances in the dataset. The reason for this discrepancy is uncertain, so replacing the values based on the
# dataset count could introduce incorrect information.

# Setting the values to NULL would also affect a large number of hosts and listings, so the column was left unchanged and excluded from the analysis.



# host is superhost. host has profile pic, host identity verified

SELECT host_is_superhost, COUNT(*) FROM listings
GROUP BY 1;

UPDATE listings
SET host_is_superhost = NULL
WHERE host_is_superhost <> 'f'
AND host_is_superhost <> 't';

# host is superhost comparison with host_id

SELECT host_id FROM (
SELECT host_id, host_is_superhost FROM listings
GROUP BY 1, 2) A
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT * FROM listings 
WHERE host_id = '39368584';

# Only 1 host had inconsistent values, caused by NULL values. No update was made because the host's other fields were also problematic and the affected listings were likely to be removed later.

SELECT host_has_profile_pic, COUNT(*) FROM listings
GROUP BY 1;

# host has profile pic comparison with host_id

SELECT host_id FROM (
SELECT host_id, host_has_profile_pic FROM listings
GROUP BY 1, 2) A
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT * FROM listings 
WHERE host_id = '39368584';

# same host as earlier.


SELECT host_identity_verified, COUNT(*) FROM listings
GROUP BY 1;

UPDATE listings
SET host_identity_verified = NULL
WHERE host_identity_verified <> 'f'
AND host_identity_verified <> 't';

# host identity pic comparison with host_id

SELECT host_id FROM (
SELECT host_id, host_identity_verified FROM listings
GROUP BY 1, 2) A
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT * FROM listings 
WHERE host_id = '22860550';

# this host has both f and t among their listings in the field. Their values will be thus set to NULL

UPDATE listings
SET host_identity_verified = NULL
WHERE host_id = '22860550';


# neighbourhood
SELECT neighbourhood, count(*) FROM listings
GROUP BY 1
ORDER BY 2 DESC;

SELECT count(*) FROM listings
where neighbourhood IS NULL;

SELECT COUNT(*) AS normalized_groups
FROM (
    SELECT LOWER(TRIM(neighbourhood)) AS neighbourhood_normalized
    FROM listings
    WHERE neighbourhood IS NOT NULL
    GROUP BY LOWER(TRIM(neighbourhood))
) A;

# No significant additional groups were created after normalization, so no normalization was required.


# district

SELECT district, city, count(*) FROM listings		# all districts are district of New York so the only city we should see is New York
WHERE district IS NOT NULL
OR (district IS NULL AND city = 'New York')
GROUP BY 1, 2;

UPDATE listings
SET district = NULL 
WHERE district IN ('Bangkok', 'Hong Kong', 'Mexico City', 'Rome');


# city

SELECT city, count(*) FROM listings
GROUP BY 1;

UPDATE listings
SET city = NULL
WHERE city IN ('13.7801', '22.5115', '19.41074', '41.90679');


SELECT city, neighbourhood FROM listings
WHERE city IS NOT NULL
GROUP BY 1,2;
# 660 rows returned (the same as grouping by neighbourhood alone) means that no same neighbourhood exists in more than 1 city



# coordinates 

SELECT latitude, longitude, count(*) AS n FROM (
SELECT latitude, longitude, property_type, count(*) FROM listings
GROUP BY 1, 2, 3
HAVING count(*) > 1
ORDER BY COUNT(*) DESC
) a
GROUP BY 1,2
HAVING n > 1;	
# listings that have the same coordinates and different property type. Provided rooms/ appartments in buildings exist as property type it is possible for multiple listings to have same coordinates
# by checkin if same coordinates exist for properties type like "entire" (eg entire villa) we find that while they do exist, they tend to have different values in other fields 
# (like price or "accomodates") thus meaning that they are not duplicates with different id, rather intentional different listing of the same property

SELECT max(latitude), min(latitude), max(longitude), min(longitude) FROM listings;

SELECT COUNT(*) FROM listings
WHERE latitude = 0
OR longitude = 0;


# property type

SELECT property_type, count(*) FROM listings
GROUP BY 1;

SELECT 
    LOWER(TRIM(property_type)) AS normalized_name,
    COUNT(*) AS total,
    GROUP_CONCAT(DISTINCT(property_type)) AS variants
FROM listings
GROUP BY 1
HAVING COUNT(DISTINCT property_type) > 1
ORDER BY total DESC;

# No meaningful duplicate categories were found after accounting for capitalization and surrounding spaces, so no normalization was needed.


# room_type

SELECT room_type FROM listings
GROUP BY 1;

UPDATE listings
SET room_type = NULL
WHERE room_type IN ('4', '2');

SELECT room_type, property_type FROM listings
WHERE (room_type = 'Entire place' AND (property_type LIKE '%private%' OR property_type LIKE '%room%') AND property_type <> 'Room in aparthotel')
OR (room_type <> 'Entire place' AND property_type LIKE '%entire%');

# Some combinations such as "Entire place" with "Room in hotel" or "Room in boutique hotel" could be considered inconsistent.
# However, these occurred only in small numbers and the classification is somewhat subjective, so they were left unchanged.



# accommodates, bedrooms

SELECT room_type, max(accommodates), min(accommodates), max(bedrooms), min(bedrooms) FROM listings
GROUP BY 1;

SELECT * FROM listings 
WHERE listing_id IN (
SELECT listing_id FROM listings
WHERE accommodates = 0
);
# most seem to be problematic rows in general (in other columns too)

UPDATE listings
SET accommodates = NULL
WHERE accommodates = 0;

SELECT property_type, room_type, count(*) FROM listings
WHERE room_type <> 'Entire place'
AND bedrooms > 1
GROUP BY 1, 2;

# Multiple bedrooms are not considered an error, as room_type describes the type of accommodation offered to the guest and does not necessarily imply that the listing contains only one bedroom.



# min/ max nights
SELECT min(minimum_nights), min(maximum_nights), max(minimum_nights), max(maximum_nights) FROM listings;


SELECT * FROM listings
WHERE maximum_nights = 0
OR minimum_nights = 0;

UPDATE listings
#SET minimum_nights = NULL
SET maximum_nights = NULL
#WHERE minimum_nights = 0;
WHERE maximum_nights = 0;

SELECT listing_id FROM listings
WHERE minimum_nights > maximum_nights;

UPDATE listings
SET minimum_nights = NULL 
WHERE listing_id IN ('23109351','38227897','42070528');

SELECT
CASE
	WHEN minimum_nights BETWEEN 1 AND 10 THEN '1-10'
    WHEN minimum_nights BETWEEN 11 AND 100 THEN '11-100'
    WHEN minimum_nights BETWEEN 101 AND 1000 THEN '101-1000'
    WHEN minimum_nights BETWEEN 1001 AND 1100 THEN '1001-1100'
    WHEN minimum_nights BETWEEN 1101 AND 5000 THEN '1101-5000'
    WHEN minimum_nights > 5000 THEN '>5000'
END AS min_nights, count(*)
FROM listings
GROUP BY 1;

UPDATE listings 
SET minimum_nights = NULL
WHERE minimum_nights > 5000;
# removing the one outlier with 9999 value in min nights

SELECT
CASE
	WHEN maximum_nights BETWEEN 1 AND 10 THEN '1-10'
    WHEN maximum_nights BETWEEN 11 AND 100 THEN '11-100'
    WHEN maximum_nights BETWEEN 101 AND 1000 THEN '101-1000'
    WHEN maximum_nights BETWEEN 1001 AND 1500 THEN '1001-1500'
    WHEN maximum_nights BETWEEN 1501 AND 2000 THEN '1501-5000'
    WHEN maximum_nights BETWEEN 5001 AND 10000 THEN '5001-10000'
    WHEN maximum_nights > 10000 THEN '>10000'
END AS max_nights, count(*)
FROM listings
GROUP BY 1
HAVING max_nights IS NOT NULL;

SELECT * FROM listings
WHERE maximum_nights = 2147483647;

# a large number of maximum nights is acceptable as it could have been intentionally set because the host does not want to set an upper limit

SELECT * FROM listings 
WHERE maximum_nights = minimum_nights;


# instant bookable

SELECT instant_bookable, count(*) FROM listings
GROUP BY 1;

UPDATE listings
SET instant_bookable = NULL
WHERE instant_bookable = ' ""Long te';


# ratings

SELECT review_scores_value, COUNT(*) FROM listings
GROUP BY 1
ORDER BY 1;

SELECT * FROM listings
WHERE review_scores_value = 0;	

UPDATE listings 
SET review_scores_rating = NULL		# most likely a null due to other problematic fields and due to the fact that it is the only 0
WHERE review_scores_rating = 0;		# this entry has all other of its score related fields as 0, instead of fixing each 1 it will just be filtered out later as a problematic row


# extra cleaning for host_id 

SELECT host_id FROM listings
WHERE host_id BETWEEN 2000 AND 2030;
# 4 IDs seem to be years, and will thus be set to NULLs as they should not be proper IDs, rather they got mixed up with another column (most likely host_since)

UPDATE listings
SET host_id = NULL
WHERE host_id = 2017
OR host_id = 2018
OR host_id = 2014;


# prices

UPDATE listings
SET price = NULL
WHERE price = 0;

SELECT city, min(price), max(price) FROM listings
GROUP BY 1;

# converting prices to common currency

ALTER TABLE listings
ADD COLUMN price_euro FLOAT AFTER price;

UPDATE listings
SET price_euro =
CASE
	WHEN city = 'Bangkok' THEN ROUND(price * 0.027, 2)
    WHEN city = 'Cape Town' THEN ROUND(price * 0.056, 2)
    WHEN city = 'Hong Kong' THEN ROUND(price * 0.105, 2)
    WHEN city = 'Istanbul' THEN ROUND(price * 0.111, 2)
    WHEN city = 'Mexico City' THEN ROUND(price * 0.042, 2)
    WHEN city = 'New York' THEN ROUND(price * 0.813, 2)
    WHEN city = 'Paris' THEN ROUND(price * 1, 2)
    WHEN city = 'Rio de Janeiro' THEN ROUND(price * 0.157, 2)
    WHEN city = 'Rome' THEN ROUND(price * 1, 2)
    WHEN city = 'Sydney' THEN ROUND(price * 0.624, 2)
END;


SELECT 
	city, min(price), min(price_euro), max(price_euro), 
	SUM(price_euro < 1) AS '<1 euro',
	SUM(price_euro BETWEEN 1 AND 5) AS '<1-5 euro',
    SUM(price_euro BETWEEN 6 AND 10) AS '<6-10 euro' 
FROM listings
GROUP BY 1;


# istanbul requires further research

SELECT 
CASE
	WHEN price_euro < 1 THEN '<1 euro'
    WHEN price_euro BETWEEN 1 AND 5 THEN '1 - 5 euros'
    WHEN price_euro BETWEEN 6 AND 10 THEN '6 - 10 euros'
    WHEN price_euro BETWEEN 11 AND 25 THEN '11 - 25 euros'
    WHEN price_euro BETWEEN 26 AND 50 THEN '26 - 50 euros'
    WHEN price_euro BETWEEN 51 AND 100 THEN '51 - 100 euros'
    WHEN price_euro BETWEEN 101 AND 200 THEN '101 - 200 euros'
    WHEN price_euro BETWEEN 201 AND 300 THEN '201 - 300 euros'
    WHEN price_euro BETWEEN 301 AND 500 THEN '301 - 500 euros'
    WHEN price_euro BETWEEN 501 AND 1000 THEN '501 - 1000 euros'
    WHEN price_euro > 1000 THEN '> 1000 euros'
END AS price_range,
COUNT(*)
FROM listings
WHERE city = 'istanbul'
GROUP BY 1
HAVING price_range IS NOT NULL
ORDER BY MIN(price_euro);

# peak seems to be in 1-5 range which is problematic


SELECT 
CASE
	WHEN price < 1 THEN '<1 euro'
    WHEN price BETWEEN 1 AND 5 THEN '1 - 5 euros'
    WHEN price BETWEEN 6 AND 10 THEN '6 - 10 euros'
    WHEN price BETWEEN 11 AND 25 THEN '11 - 25 euros'
    WHEN price BETWEEN 26 AND 50 THEN '26 - 50 euros'
    WHEN price BETWEEN 51 AND 100 THEN '51 - 100 euros'
    WHEN price BETWEEN 101 AND 200 THEN '101 - 200 euros'
    WHEN price BETWEEN 201 AND 300 THEN '201 - 300 euros'
    WHEN price BETWEEN 301 AND 500 THEN '301 - 500 euros'
    WHEN price BETWEEN 501 AND 1000 THEN '501 - 1000 euros'
    WHEN price > 1000 THEN '> 1000 euros'
END AS price_range,
COUNT(*)
FROM listings
WHERE city = 'istanbul'
GROUP BY 1
HAVING price_range IS NOT NULL
ORDER BY MIN(price);

# The original values were also examined as if they were already in EUR. This produced a more plausible distribution, but historical exchange-rate
# changes provided a better explanation for the discrepancy.

SELECT city, ROUND(AVG(price_euro), 0) FROM listings
GROUP BY 1;

SELECT room_type, ROUND(AVG(price_euro), 0) FROM listings
GROUP BY 1;

SELECT city, room_type, ROUND(AVG(price_euro), 0) FROM listings
GROUP BY 1, 2
ORDER BY 1, 2;

# Shared rooms in Rio de Janeiro showed an unusually high average price, so the distribution was examined further.

SELECT 
CASE
	WHEN price_euro < 1 THEN '<1 euro'
    WHEN price_euro BETWEEN 1 AND 5 THEN '1 - 5 euros'
    WHEN price_euro BETWEEN 6 AND 10 THEN '6 - 10 euros'
    WHEN price_euro BETWEEN 11 AND 25 THEN '11 - 25 euros'
    WHEN price_euro BETWEEN 26 AND 50 THEN '26 - 50 euros'
    WHEN price_euro BETWEEN 51 AND 100 THEN '51 - 100 euros'
    WHEN price_euro BETWEEN 101 AND 200 THEN '101 - 200 euros'
    WHEN price_euro BETWEEN 201 AND 300 THEN '201 - 300 euros'
    WHEN price_euro BETWEEN 301 AND 500 THEN '301 - 500 euros'
    WHEN price_euro BETWEEN 501 AND 1000 THEN '501 - 1000 euros'
    WHEN price_euro > 1000 THEN '> 1000 euros'
END AS price_range,
count(*)
FROM listings
WHERE city = 'Rio de Janeiro'
AND room_type = 'shared room'
GROUP BY 1
ORDER BY MIN(price_euro);

SELECT * FROM listings
#WHERE city = 'Rio de Janeiro'
WHERE room_type = 'shared room'
AND price_euro > 3000;

# One extreme value was identified. Other high values were also present, but there was insufficient evidence to classify them as errors, so they were left unchanged.

UPDATE listings
SET price_euro = NULL
WHERE city = 'Rio de Janeiro'
AND room_type = 'shared room'
AND price_euro > 90000;


# amenities

SELECT listing_id, amenities FROM listings
WHERE JSON_VALID(amenities) = 0;

# 1059 invalid JSON values were found. The issue was caused by escaped quotation marks within the amenity strings. These were corrected in Excel before the cleaned data was re-imported.

ALTER TABLE listings
MODIFY COLUMN amenities JSON;

SELECT COUNT(*), SUM(N) FROM (
SELECT a.amenity, count(*) AS N FROM listings l
JOIN JSON_TABLE(
    l.amenities,
    '$[*]' COLUMNS (
        amenity VARCHAR(255) PATH '$'
    )
) AS a
GROUP BY 1
HAVING count(*) > 100
) b;

# Amenities appearing more than 100 times account for approximately 99.6% of all amenity occurrences, so excluding less frequent amenities has a negligible effect on the overall analysis.

# The following amenities were identified as representing the same amenity under different names, and were grouped together during the analysis because the differences would
# significantly affect their overall counts: TV (TV, Cable TV, HDTV) Coffee maker (Coffee maker, Nespresso machine, Keurig coffee machine, Pour-over coffee)
# Clothing storage (Clothing storage, Clothing storage: closet, Clothing storage: wardrobe)

SELECT * FROM listings
WHERE json_length(amenities) = 0;



# Cleaning and Final Filtering
# excluding the rows that are expected to have nulls, the rows that contain null values will be dropped after some final checks

DROP TABLE IF EXISTS list_c;
CREATE TABLE list_c AS		# creating new table for the cleaned data
SELECT * FROM listings;

# Check whether listings that will be removed have a substantial number of reviews, to make sure important/high-activity listings are not being removed unexpectedly.
SELECT listing_id, count(*) FROM reviews 
WHERE listing_id IN(
SELECT listing_id FROM listings
WHERE host_id IS NULL
   OR host_since IS NULL
   OR host_is_superhost IS NULL
   OR host_total_listings_count IS NULL
   OR host_has_profile_pic IS NULL
   OR host_identity_verified IS NULL
   OR neighbourhood IS NULL
   OR city IS NULL
   OR latitude IS NULL
   OR longitude IS NULL
   OR property_type IS NULL
   OR room_type IS NULL
   OR accommodates IS NULL
   OR amenities IS NULL
   OR price_euro IS NULL
   OR minimum_nights IS NULL
   OR maximum_nights IS NULL
   OR instant_bookable IS NULL
   )
GROUP BY 1
ORDER BY 2 DESC;

# Review count for all listings, used as a reference for the previous check.
SELECT listing_id, count(*) FROM reviews
GROUP BY 1
ORDER BY 2 DESC;


DELETE FROM list_c
WHERE host_id IS NULL
   OR host_since IS NULL
   OR host_is_superhost IS NULL
   OR host_total_listings_count IS NULL
   OR host_has_profile_pic IS NULL
   OR host_identity_verified IS NULL
   OR neighbourhood IS NULL
   OR city IS NULL
   OR latitude IS NULL
   OR longitude IS NULL
   OR property_type IS NULL
   OR room_type IS NULL
   OR accommodates IS NULL
   OR amenities IS NULL
   OR price_euro IS NULL
   OR minimum_nights IS NULL
   OR maximum_nights IS NULL
   OR instant_bookable IS NULL
;

# Only rows with NULL values in fields that were considered problematic for the analysis were removed. Fields with large amounts of NULL values
# but that were still considered usable were retained, with their NULL values taken into account when calculating the relevant metrics later.


SELECT COUNT(*) FROM list_c
WHERE host_id IS NULL
   OR host_since IS NULL
   OR host_is_superhost IS NULL
   OR host_total_listings_count IS NULL
   OR host_has_profile_pic IS NULL
   OR host_identity_verified IS NULL
   OR neighbourhood IS NULL
   OR city IS NULL
   OR latitude IS NULL
   OR longitude IS NULL
   OR property_type IS NULL
   OR room_type IS NULL
   OR accommodates IS NULL
   OR amenities IS NULL
   OR price_euro IS NULL
   OR minimum_nights IS NULL
   OR maximum_nights IS NULL
   OR instant_bookable IS NULL
;



# reviews table cleaning

SELECT * FROM reviews
WHERE listing_id IS NULL;


# Reviewer IDs can be used to identify reviewers who leave many reviews, although this does not necessarily represent all frequent travelers.
SELECT * FROM reviews
WHERE reviewer_id = 0;

SELECT * FROM reviews
WHERE date IS NULL
OR date = 0;

# Check the overall date range before applying the time filters used in the analysis.
SELECT max(date), min(date) FROM reviews;
