CREATE DATABASE d2c_funnel;
USE d2c_funnel;

CREATE TABLE sessions (
session_id VARCHAR(50) PRIMARY KEY,
user_id VARCHAR(50),
session_date DATE,
session_month VARCHAR(20),
channel VARCHAR(50),
campaign_type VARCHAR(50),
device VARCHAR(50),
user_type VARCHAR(50),
region VARCHAR(50),
visited_website VARCHAR(50),
visited_product VARCHAR(50),
added_to_cart VARCHAR(50),
checkout_started VARCHAR(50),
purchase_completed VARCHAR(50),
discount_applied VARCHAR(50),
order_value DECIMAL(10,2),
revenue DECIMAL(10,2)
);

TRUNCATE TABLE sessions;
ALTER TABLE sessions DROP PRIMARY KEY;
ALTER TABLE sessions ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/hp/Downloads/d2c_marketing_funnel_data.csv'
IGNORE INTO TABLE sessions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(user_id, session_id, session_date, session_month, channel, campaign_type, device, user_type, region, visited_website, visited_product, added_to_cart, checkout_started, purchase_completed, discount_applied, order_value, revenue);

SHOW WARNINGS;

SELECT * FROM sessions;
SELECT COUNT(*) FROM sessions;

-- The Core Funnel Breakdown
SELECT 
COUNT(session_id) AS total_sessions,
SUM(CASE WHEN visited_website = 'Yes' THEN 1 ELSE 0 END) AS website_visits,
SUM(CASE WHEN visited_product  = 'Yes' THEN 1 ELSE 0 END) AS product_views,
SUM(CASE WHEN added_to_cart  = 'Yes' THEN 1 ELSE 0 END) AS cart_additions,
SUM(CASE WHEN checkout_started  = 'Yes' THEN 1 ELSE 0 END) AS checkouts,
SUM(CASE WHEN purchase_completed  = 'Yes' THEN 1 ELSE 0 END) AS purchases
FROM sessions;

-- Stage to Stage Conversion Rates
WITH Funnel_Counts AS (
SELECT 
SUM(CASE WHEN visited_website = 'Yes' THEN 1 ELSE 0 END) AS website_visits,
SUM(CASE WHEN visited_product  = 'Yes' THEN 1 ELSE 0 END) AS product_views,
SUM(CASE WHEN added_to_cart  = 'Yes' THEN 1 ELSE 0 END) AS cart_additions,
SUM(CASE WHEN checkout_started  = 'Yes' THEN 1 ELSE 0 END) AS checkouts,
SUM(CASE WHEN purchase_completed  = 'Yes' THEN 1 ELSE 0 END) AS purchases
FROM sessions
)
SELECT 
website_visits,
ROUND((product_views / website_visits) * 100, 2) AS visit_to_view_pct,
ROUND((cart_additions / product_views) * 100, 2) AS visit_to_cart_pct,
ROUND((checkouts / cart_additions) * 100, 2) AS cart_to_checkout_pct,
ROUND((purchases / checkouts) * 100, 2) AS checkout_to_purchase_pct,
ROUND((purchases / website_visits) * 100, 2) AS overall_conversion_pct
FROM Funnel_Counts;

-- Cart Abandonment Rate By Segment
SELECT device, 
SUM(CASE WHEN added_to_cart = 'Yes' THEN 1 ELSE 0 END) AS total_carts,
SUM(CASE WHEN purchase_completed = 'Yes' THEN 1 ELSE 0 END) AS total_purchases,
ROUND((1 - (SUM(CASE WHEN purchase_completed = 'Yes' THEN 1 ELSE 0 END) / 
SUM(CASE WHEN added_to_cart = 'Yes' THEN 1 ELSE 0 END))) * 100, 2) AS cart_abandonment_rate
FROM sessions
WHERE added_to_cart = 'Yes'
GROUP BY device
ORDER BY cart_abandonment_rate DESC;

-- Campaign Performance
SELECT campaign_type, 
COUNT(session_id) AS total_sessions,
SUM(CASE WHEN purchase_completed = 'Yes' THEN 1 ELSE 0 END) AS total_purchases,
ROUND((SUM(CASE WHEN purchase_completed = 'Yes' THEN 1 ELSE 0 END) / 
COUNT(session_id)) * 100, 2) AS conversion_rate
FROM sessions
GROUP BY campaign_type
ORDER BY conversion_rate DESC;










