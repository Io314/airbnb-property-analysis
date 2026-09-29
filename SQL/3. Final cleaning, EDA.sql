SET SQL_SAFE_UPDATES = 0;

# listing_name can be dropped as a column as it is irrelevant to the analysis
ALTER TABLE list_c
DROP COLUMN listing_name;


# host_id and host values in general

# Check whether each host has one consistent set of host-level values. A result of 0 means every host has only one unique combination of these fields.
SELECT COUNT(*) - (SELECT COUNT(DISTINCT(host_id)) FROM list_c) FROM (
SELECT host_id, host_since, host_location, host_response_time, host_response_rate, host_acceptance_rate, host_is_superhost, host_total_listings_count, host_has_profile_pic, host_identity_verified FROM list_c
GROUP BY 1,2,3,4,5,6,7,8,9,10
) A;

# calculates each column pairing seperately for easier checking and cleaning (this was ran for each column to inspect the situation each time)
SELECT (SELECT count(DISTINCT host_id) FROM list_c) - (SELECT COUNT(*) FROM (
SELECT host_id, host_acceptance_rate FROM list_c
GROUP BY 1,2) a);



WITH temp1 AS (						 # returns the host_id with different values of x row for same host
SELECT host_id FROM 
	(
	SELECT host_id, host_acceptance_rate FROM list_c
	GROUP BY 1,2
	) A
GROUP BY host_id 
HAVING COUNT(*) > 1
)
# Examine the different values for those hosts.
SELECT host_id, host_acceptance_rate, COUNT(*) FROM list_c
WHERE host_id IN (SELECT host_id FROM temp1)
GROUP BY 1,2;

# Cleaning host-level values so that the same host has consistent values across their listings.
UPDATE list_c
SET host_location = 'New York, United States'		# one entry was brooklyn, .., .. while the other was new york, .., .. so we just generalize to New York, United States
WHERE host_id = 279024287;
				
                
# The following update was also applied to the other host-level fields that should be consistent across a host's listings:
# host_response_time, host_total_listings_count, host_response_rate, and host_acceptance_rate.

# Some host-level fields contained a small number of inconsistent values across listings. Given the limited number of affected hosts and the small
# differences between their values, the risk of standardizing them was considered acceptable.

# The most frequent non-NULL value was therefore used to make the remaining listings for each host consistent.

UPDATE list_c AS l
JOIN (		
    SELECT
        host_id,
        host_acceptance_rate
    FROM (
        SELECT
            host_id,
            host_acceptance_rate,
            ROW_NUMBER() OVER (
                PARTITION BY host_id
                ORDER BY
                    host_acceptance_rate IS NULL,
                    COUNT(*) DESC
            ) AS rn
        FROM list_c
        GROUP BY host_id, host_acceptance_rate
    ) AS ranked
    WHERE rn = 1
) AS t
    ON l.host_id = t.host_id
SET l.host_acceptance_rate = t.host_acceptance_rate;


# Creating table for all information regarding hosts with host_id as a primary key
CREATE TABLE host_info AS
SELECT host_id, host_since, host_location, host_response_time, host_response_rate, host_acceptance_rate, host_is_superhost, host_total_listings_count, host_has_profile_pic, host_identity_verified FROM list_c
GROUP BY 1,2,3,4,5,6,7,8,9,10;

ALTER TABLE host_info
ADD PRIMARY KEY (host_id);

ALTER TABLE list_c
ADD CONSTRAINT fk_host_id
FOREIGN KEY (host_id)
REFERENCES host_info(host_id);

SELECT * FROM host_info;

ALTER TABLE list_c
DROP COLUMN host_since,
DROP COLUMN host_location,
DROP COLUMN host_response_time,
DROP COLUMN host_response_rate,
DROP COLUMN host_acceptance_rate,
DROP COLUMN host_is_superhost,
DROP COLUMN host_total_listings_count,
DROP COLUMN host_has_profile_pic,
DROP COLUMN host_identity_verified;



# city, neighbourhood
SELECT city, neighbourhood, count(*), ROUND(100*count(*) / SUM(COUNT(*)) OVER (PARTITION BY city), 1) AS percentage, RANK() OVER(PARTITION BY city ORDER BY count(*) DESC) AS rnk FROM list_c
GROUP BY 1, 2;

SELECT city, count(*), ROUND(100*count(*) / SUM(COUNT(*)) OVER (), 1) AS percentage FROM list_c
GROUP BY 1
ORDER BY COUNT(*) DESC;



# room/ listing features

SELECT room_type, count(*), ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (),1) FROM list_c
GROUP BY 1;


SELECT accommodates, COUNT(*) FROM list_c
GROUP BY 1
ORDER BY COUNT(*) DESC;

SELECT bedrooms, COUNT(*) FROM list_c
GROUP BY 1
ORDER BY COUNT(*) DESC;


# only price in euros is needed

ALTER TABLE list_c
DROP COLUMN price;


# Creating a cleaned review table containing only listings that remain in list_c, then establish the foreign key relationship with the cleaned listing table.

CREATE TABLE rev_c AS
SELECT * FROM reviews
WHERE listing_id IN 
(
	SELECT listing_id FROM list_c
);

SELECT COUNT(*) FROM rev_c;
SELECT COUNT(*) FROM reviews;


ALTER TABLE rev_c
ADD CONSTRAINT fk_listing_id
FOREIGN KEY (listing_id)
REFERENCES list_c(listing_id);


# Coordinates were mapped in Tableau to check for listings outside their expected areas. The original mapping process was not retained in a
# repeatable form, so the code for this step was excluded.


# a lot of 0 values can be found in host_response_rate despite values between 0.01 and 0.1 being much lower. Why? 

SELECT count(distinct l.host_id) FROM list_c l
JOIN host_info h
	ON l.host_id = h.host_id
WHERE host_response_rate = 0;

SELECT count(*) FROM host_info;

# Around 10% of hosts have a recorded response rate of 0. While unusual, this is a plausible value and was therefore not treated
# as an invalid value.


# Host acceptance rate
# Examine why some hosts have a recorded acceptance rate of 0.
SELECT count(*) FROM list_c l
JOIN host_info h
	ON l.host_id = h.host_id
WHERE host_acceptance_rate = 0;

SELECT count(*) FROM list_c;

# Around 4% of listings have a host with an acceptance rate of 0. This is possible, but the data does not provide enough information to
# determine why the rate is 0.

SELECT listing_id, count(*) FROM rev_c
WHERE listing_id IN
(
	SELECT l.listing_id FROM list_c l
	JOIN host_info h
		ON l.host_id = h.host_id
	WHERE host_acceptance_rate = 0
)
GROUP BY 1
ORDER BY count(*) DESC;

SELECT * FROM list_c l
JOIN host_info h
	ON l.host_id = h.host_id
WHERE listing_id = 11246705;

# It is unclear why some hosts have an acceptance rate of 0 despite having reviews. The field will therefore be treated cautiously if used later
# in the analysis.



# Check the distribution of the year in which each listing received its latest review.
SELECT latest_review_date, count(*) FROM (
	SELECT l.listing_id, YEAR(MAX(r.DATE)) AS latest_review_date FROM list_c l
	LEFT JOIN rev_c r
		ON l.listing_id = r.listing_id
	GROUP BY 1) A
GROUP BY 1;



# Create a listing-level review summary for use in later analysis. This includes total reviews, first/latest review dates, and the highest
# reviewer frequency rank associated with each listing.

CREATE TABLE listing_rev_info AS 
SELECT l.listing_id, COUNT(r.listing_id) AS review_count, MIN(r.DATE) AS first_review_date, MAX(r.DATE) AS latest_review_date FROM list_c l
LEFT JOIN rev_c r
	ON l.listing_id = r.listing_id
GROUP BY 1;

# City area data used to calculate listing density.
# Area values are in km².
CREATE TABLE city_area (
    city VARCHAR(50),
    area_km2 DECIMAL(10,2)
);

INSERT INTO city_area (city, area_km2)
VALUES
('Paris', 105.40),
('New York', 789.00),
('Rome', 1287.00),
('Cape Town', 2446.40),
('Sydney', 12368.00),
('Rio de Janeiro', 1200.33),
('Istanbul', 5460.85),
('Bangkok', 1568.74),
('Mexico City', 1485.00),
('Hong Kong', 1114.57);
