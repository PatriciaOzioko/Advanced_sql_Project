--Project Title: Exploring the Heart of Airbnb: A Data Journey Through Listings, Hosts, and Neighborhoods in Athens.
--Project Title Explaination- This is a SQL project is based on the Airbnb_athens dataset. Ii is focused on the exploration
--and a deep dive into the data that powers the platform. I split the dataset in two, one is called AirBnB-listings_Athens and the other is called Apartment

--(A)  Retriveing the names and prices of all listings
--This will help lay the foundation for understanding the dataset and the information available for each listing.
SELECT Ai.price, Ap.name
FROM dbo.AirBnB_listings_Athens$ AS Ai
JOIN dbo.Apartment$ AS Ap 
ON Ai.host_id = Ap.host_id


--(B) Filtering and Sorting names and prices of listing in the Goudi area.
-- I narrowed down my focus to a specific neighborhood (Goudi), to extract valuable insights through data manipulation.
SELECT Ai.price, Ap.name
FROM dbo.AirBnB_listings_Athens$ AS Ai
JOIN dbo.Apartment$ AS Ap 
ON Ai.host_id = Ap.host_id
WHERE neighbourhood = 'Goudi'
ORDER BY price desc

--(C) Finding the Average price of all listings
-- This helped me understand the overall pricing trend in the dataset.
SELECT AVG(price) AS AveragePrice
FROM dbo.AirBnB_listings_Athens$

--(D) Finding the Hosts and the number of reviews they have got
-- Connecting hosts with their total number of reviews sheds light on host performance, including those who haven't received reviews�this is a valuable metric for both hosts and potential guests.
SELECT host_id, host_name, COALESCE(COUNT(number_of_reviews), 0) AS TotalReviews
FROM dbo.AirBnB_listings_Athens$
GROUP BY host_id, host_name;

-- It appears that some hosts have multiple Host_id. This may be because they have multiple listings and each listing has its own review
-- To check the total Reviews per host
SELECT host_name, COALESCE(COUNT(number_of_reviews), 0) AS TotalHostReviews
FROM dbo.AirBnB_listings_Athens$
GROUP BY host_name;

--(E) Finding the Host with the highest Average Price for their listings
-- I used CTE to find the highest Average Price
WITH HostAvgPriceCTE AS (
    SELECT
        host_id,
		host_name,
        AVG(price) AS AvgPrice
    FROM
        dbo.AirBnB_listings_Athens$
    GROUP BY
        host_id, host_name
)

SELECT
    Ai.host_id,
    Ai.host_name,
    COALESCE(AvgPrice, 0) AS AveragePrice
FROM
    dbo.AirBnB_listings_Athens$ Ai
LEFT JOIN
    HostAvgPriceCTE ON Ai.host_id = HostAvgPriceCTE.host_id
ORDER BY
    AvgPrice DESC;


--(F) Find the listings with prices higher than the average price of all listings between 2013 to 2022
--Comparing listing prices to the average price gives insight into individual listing competitiveness and positioning.
SELECT DISTINCT Ap.name AS listing_name, Ai.host_id, Ai.host_name, Ai.last_review
FROM dbo.AirBnB_listings_Athens$ Ai
JOIN dbo.Apartment$ Ap ON Ai.host_id = Ap.host_id
WHERE price > (SELECT AVG(price) FROM dbo.AirBnB_listings_Athens$)
	 AND Ai.id IN (
        SELECT DISTINCT id
        FROM dbo.AirBnB_listings_Athens$
        WHERE last_review BETWEEN '2013-01-01' AND '2022-12-31'
    );


--(G) Rank the hosts based on the number of listings they have in each neighborhood
--Ranking hosts based on the number of listings in each neighborhood provided a deeper understanding of host distribution and popularity in different areas.
WITH HostListingsCount AS (
    SELECT
        host_id,
        neighbourhood,
        COUNT(*) AS ListingsCount,
        DENSE_RANK() OVER (PARTITION BY neighbourhood ORDER BY COUNT(*) DESC) AS NeighbourhoodRank
    FROM
        dbo.AirBnB_listings_Athens$
    GROUP BY
        host_id, neighbourhood
)

SELECT
    host_id,
    neighbourhood,
    ListingsCount,
    NeighbourhoodRank
FROM
    HostListingsCount;


-- (H) Creating a temporary table that contains the hosts' names and the total number of reviews they received.  
-- I will query this table to find hosts with more than 100 reviews
CREATE TABLE #TempHostReviews (
    host_id INT,
    host_name VARCHAR(255),
    TotalReviews INT
);

INSERT INTO #TempHostReviews (host_id, host_name, TotalReviews)
SELECT
    host_id,
    host_name,
    COUNT(*) AS TotalReviews
FROM
    dbo.AirBnB_listings_Athens$
GROUP BY
    host_id, host_name;

-- Querying the temporary table
SELECT *
FROM
    #TempHostReviews
WHERE
    TotalReviews > 100;


--(I) Creating a view that combines information about the listing and the host. 
--Constructing a view combining listing and host information helped simplify complex queries and facilitate easier analysis.
CREATE VIEW ListingsAndHosts AS
SELECT
    Ai.id,
    Ap.name,
    Ai.host_id,
    Ai.host_name,
    Ai.price
FROM
    dbo.AirBnB_listings_Athens$ Ai
JOIN
    dbo.Apartment$ Ap ON Ai.host_id = Ap.host_id;

-- Query the view --Using this view to find the top 10 hosts with the most listings
SELECT TOP 10
    host_id,
    host_name,
    COUNT(DISTINCT id) AS TotalListings
FROM
    ListingsAndHosts
GROUP BY
    host_id, host_name
ORDER BY
    TotalListings DESC;


--(J) Calculating the percentage of listings in each neighborhood relative to the total number of listings.
--Calculating the percentage of listings in each neighborhood group offered a broader perspective on the distribution of listings across different areas.
SELECT
    neighbourhood,
    COUNT(*) AS TotalListings,
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dbo.AirBnB_listings_Athens$)) AS Percentage
FROM
    dbo.AirBnB_listings_Athens$
GROUP BY neighbourhood
ORDER BY TotalListings DESC;

--(K) Determining the average number of reviews per month for listings that have been reviewed in the last twelve months.
--This should give a temporal perspective on listing activity.
SELECT
    AVG(reviews_per_month) AS AvgReviewsPerMonth
FROM
   dbo.AirBnB_listings_Athens$
WHERE
    last_review >= DATEADD(MONTH, -12, GETDATE());
-- This shows that no review has been done in the past 12 months, i want to modify my query to confirm this
-- Count of reviews per month for the last twelve months
SELECT
    YEAR(last_review) AS ReviewYear,
    MONTH(last_review) AS ReviewMonth,
    COUNT(*) AS ReviewCount
FROM
    dbo.AirBnB_listings_Athens$
WHERE
    last_review >= DATEADD(MONTH, -12, GETDATE())
GROUP BY
    YEAR(last_review), MONTH(last_review)
ORDER BY
    ReviewYear, ReviewMonth;
--Further checks show that the last review was done 19 months ago. A prospective Customer will find this information valuable.


--(L) Finding the listings with missing values in the "license" column and provide a count.
-- This can prompt further investigation into data quality and completeness
SELECT
    COUNT(*) AS MissingLicenseCount
FROM
    dbo.AirBnB_listings_Athens$
WHERE
    license IS NULL;


--Recommendations
-- (1) Host Insights: Αλεξιος and Markos highest average prices. Other Hosts can learn from thse 2 to help them optimize their pricing strategy.
--(2) Neighborhood Trends: Commercial Triangle-Plaka, Neos Kosmos and Koukaki-Makrygianni neigbourhood has the highest number of listings. This can help guide potential guests in their search.

--(3) Temporal Analysis: It is strange that the last review on any listing in Athens was made 19 months ago. It will be wrong to assume that no activity happened in this period. Temporal patterns and seasonality may be a factor but i believe inadequate data is to blame
--(4) Data Quality: Investigating listings with missing values in the "license" column shows that 3702 listings had no recorded licence. This shows that the is incomplete and data quality improvements are necessary.
