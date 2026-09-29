SET SQL_SAFE_UPDATES = 0;
DESCRIBE reviews;
    
#DROP TABLE IF EXISTS listings;			# normally kept as a comment so the tables don't get messed up if I run the whole script by mikstake 

CREATE TABLE listings 
    (
    listing_id	INT,
    listing_name	VARCHAR(500),
    host_id	INT,
    host_since	DATE,
    host_location	VARCHAR(500),
    host_response_time	VARCHAR(500),
    host_response_rate	FLOAT,
    host_acceptance_rate	FLOAT,
    host_is_superhost	VARCHAR(10),
    host_total_listings_count	INT,
    host_has_profile_pic	VARCHAR(10),
    host_identity_verified	VARCHAR(10),
    neighbourhood	VARCHAR(100),
    district	VARCHAR(100),
    city	VARCHAR(100),
    latitude	DECIMAL(12,9),
    longitude	DECIMAL(12,9),
    property_type	VARCHAR(100),
    room_type	VARCHAR(100),
    accommodates	INT,
    bedrooms	INT,
    amenities	LONGTEXT,		# initially loaded as longtext because some rows are broken and not in proper JSON format.
    price	FLOAT,
    minimum_nights	INT,
    maximum_nights	INT,
    review_scores_rating	FLOAT,
    review_scores_accuracy	INT,
    review_scores_cleanliness	INT,
    review_scores_checkin	INT,
    review_scores_communication	INT,
    review_scores_location	INT,
    review_scores_value	INT,
    instant_bookable	VARCHAR(10)
    );
    

ALTER TABLE listings
ADD PRIMARY KEY (listing_id);

 
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews
	(
	listing_id INT,
	review_id BIGINT,
	date DATE,
	reviewer_id BIGINT
	);
    

ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_listing
FOREIGN KEY (listing_id)
REFERENCES listings(listing_id);

    
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/Juan/Desktop/DA project downloads/2. P2/Airbnb data/listings.csv'
INTO TABLE listings
CHARACTER SET LATIN1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    @listing_id,
    @listing_name,
    @host_id,
    @host_since,
    @host_location,
    @host_response_time,
    @host_response_rate,
    @host_acceptance_rate,
    @host_is_superhost,
    @host_total_listings_count,
    @host_has_profile_pic,
    @host_identity_verified,
    @neighbourhood,
    @district,
    @city,
    @latitude,
    @longitude,
    @property_type,
    @room_type,
    @accommodates,
    @bedrooms,
    @amenities,
    @price,
    @minimum_nights,
    @maximum_nights,
    @review_scores_rating,
    @review_scores_accuracy,
    @review_scores_cleanliness,
    @review_scores_checkin,
    @review_scores_communication,
    @review_scores_location,
    @review_scores_value,
    @instant_bookable
)
SET
    listing_id = NULLIF(@listing_id, ''),
    listing_name = NULLIF(@listing_name, ''),
    host_id = NULLIF(@host_id, ''),
    host_since = NULLIF(@host_since, ''),
    host_location = NULLIF(@host_location, ''),
    host_response_time = NULLIF(@host_response_time, ''),
    host_response_rate = NULLIF(@host_response_rate, ''),
    host_acceptance_rate = NULLIF(@host_acceptance_rate, ''),
    host_is_superhost = NULLIF(@host_is_superhost, ''),
    host_total_listings_count = NULLIF(@host_total_listings_count, ''),
    host_has_profile_pic = NULLIF(@host_has_profile_pic, ''),
    host_identity_verified = NULLIF(@host_identity_verified, ''),
    neighbourhood = NULLIF(@neighbourhood, ''),
    district = NULLIF(@district, ''),
    city = NULLIF(@city, ''),
    latitude = NULLIF(@latitude, ''),
    longitude = NULLIF(@longitude, ''),
    property_type = NULLIF(@property_type, ''),
    room_type = NULLIF(@room_type, ''),
    accommodates = NULLIF(@accommodates, ''),
    bedrooms = NULLIF(@bedrooms, ''),
    amenities = NULLIF(@amenities, ''),
    price = NULLIF(@price, ''),
    minimum_nights = NULLIF(@minimum_nights, ''),
    maximum_nights = NULLIF(@maximum_nights, ''),
    review_scores_rating = NULLIF(@review_scores_rating, ''),
    review_scores_accuracy = NULLIF(@review_scores_accuracy, ''),
    review_scores_cleanliness = NULLIF(@review_scores_cleanliness, ''),
    review_scores_checkin = NULLIF(@review_scores_checkin, ''),
    review_scores_communication = NULLIF(@review_scores_communication, ''),
    review_scores_location = NULLIF(@review_scores_location, ''),
    review_scores_value = NULLIF(@review_scores_value, ''),
    instant_bookable = NULLIF(@instant_bookable, '');


LOAD DATA LOCAL INFILE 'C:/Users/Juan/Desktop/DA project downloads/2. P2/Airbnb data/reviews.csv'
INTO TABLE reviews
CHARACTER SET LATIN1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;



# Initial EDA

SELECT COUNT(*) FROM listings;

SELECT COUNT(*) FROM reviews;

# exploring listing review counts

SELECT l.listing_id, COUNT(*) FROM listings l
RIGHT JOIN reviews r
	ON r.listing_id = l.listing_id
GROUP BY 1
ORDER BY 2 DESC;


SELECT city, COUNT(*) FROM listings
GROUP BY 1;

SELECT COUNT(*) - COUNT(DISTINCT(listing_id)) FROM listings;	# duplicate check

SELECT host_id, COUNT(*) FROM listings
GROUP BY 1
ORDER BY 2 DESC;

SELECT count(*) FROM listings
WHERE JSON_VALID(amenities) = 0;

SELECT price FROM listings
ORDER BY 1 DESC;

SELECT review_scores_value, COUNT(*) FROM listings
GROUP BY 1
ORDER BY 1;



# checking if I could discard some categories with low appearance frequency or group them together in broader areas

SELECT COUNT(*) FROM
(
SELECT host_location, COUNT(*) AS N FROM listings
GROUP BY 1
ORDER BY 2 DESC
) TEMP
WHERE N > 480;

SELECT instant_bookable, COUNT(*) AS N FROM listings
GROUP BY 1
ORDER BY 1 DESC;