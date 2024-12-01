CREATE DATABASE IF NOT EXISTS Amazon;	# Creating a database Amazon if it doesn't exist

CREATE TABLE Sales (	# Creating table Sales with required columns by avoiding null values
	invoice_id VARCHAR(30) NOT NULL,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    VAT FLOAT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_percentage FLOAT NOT NULL,
    gross_income DECIMAL(10,2) NOT NULL,
    rating FLOAT NOT NULL
);

# adding columns timeofday, dayname, monthname
ALTER TABLE Sales
ADD COLUMN timeOfDay VARCHAR(55) NOT NULL,
ADD COLUMN dayName VARCHAR(30) NOT NULL,
ADD COLUMN MonthName VARCHAR(30) NOT NULL;

UPDATE Sales
SET timeOfDay = CASE
	WHEN time < "12:00:00" THEN "Morning"
    WHEN time < "16:00:00" THEN "AfterNoon"
    ELSE "Evening"
END
WHERE timeofday IS NOT NULL;

select * from sales;

# 1. What is the count of distinct cities in the dataset?
SELECT 
	COUNT(DISTINCT city) AS count_of_distinct_cities	#using count and distinct to count the unique cities from the dataset
FROM sales;

# 2. For each branch, what is the corresponding city?
SELECT
	DISTINCT branch,	#using distinct to find the distinct branches followed by the corresponding city
    city 
FROM sales;	

# 3. What is the count of distinct product lines in the dataset?
SELECT
	COUNT(DISTINCT product_line) 	# usng count and distinct for counting the unique product lines in the dataset
FROM sales; 

# 4. Which payment method occurs most frequently?
SELECT
	payment_method AS most_occuring_payment_method,
    count(payment_method) as frequency_of_occurance		#using the count function for counting the occurance of a method
FROM sales
GROUP BY payment_method		#using aggregate function for grouping the result in to required categories 
ORDER BY frequency_of_occurance DESC	# applying descending order for highest listing first
LIMIT 1;	#limiting the result by 1 to get the desired output

# 5. Which product line has the highest sales?
SELECT 
	product_line AS product_line_with_highest_sales,
    SUM(total) AS total_sales 	#using SUM to perform aggregate function for total sales by productline
FROM Sales
GROUP BY product_line_with_highest_sales
ORDER BY total_sales DESC	#obtaining result in descending order
LIMIT 1;	#limiting the result for highest sales

# 6. How much revenue is generated each month?
SELECT 
	MONTHNAME(date) AS month, 	#extracting month names from dataset
    SUM(total) AS revenue 	#calculating total revenue
FROM sales
GROUP BY month;		#using month aggregation for monthly sales revenue

# 7. In which month did the cost of goods sold reach its peak?
WITH month_cog AS (		#creating CTE
	SELECT MONTHNAME(date) AS month, AVG(cogs/quantity) AS cog FROM sales	# Obtaining cost of goods monthly
	GROUP BY month
	ORDER BY cog DESC
)
SELECT month FROM month_cog
LIMIT 1;

# 8. Which product line generated the highest revenue?
WITH product_line_revenue AS (	#creating CTE
	SELECT product_line, SUM(total) AS revenue FROM sales	#sum of total by product_line
	GROUP BY product_line
	ORDER BY revenue DESC
)
SELECT product_line FROM product_line_revenue
LIMIT 1;

# 9. In which city was the highest revenue recorded?
WITH city_revenue AS (	#creating CTE
	SELECT city, SUM(total) AS revenue FROM sales	#sum of total by city
	GROUP BY city
	ORDER BY revenue DESC
)
SELECT city FROM city_revenue
LIMIT 1;

# 10. Which product line incurred the highest Value Added Tax?
WITH product_line_htax AS (	# creating CTE 
	SELECT product_line, MAX(vat) AS highest_tax FROM sales	#max of tax by product_line
	GROUP BY product_line
	ORDER BY highest_tax DESC
)
SELECT product_line FROM product_line_htax
LIMIT 1;

# 11. For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
WITH average_sales AS (	# CTE for average sales
	SELECT AVG(total) AS sales_average FROM sales
), product_line_average AS (	#CTE for product_line total average
	SELECT product_line, AVG(total) AS p_average FROM sales
    GROUP BY product_line
)
SELECT product_line, 
	if(p_average > (SELECT sales_average FROM average_sales), "Good", "Bad") #using if for categorising in to good or bad
    AS category 
FROM product_line_average;

# 12. Identify the branch that exceeded the average number of products sold.
WITH branch_sales AS (	#CTE for branch wise average quantity sold
	SELECT branch, COUNT(quantity) AS products_sold FROM sales
	GROUP BY branch
),
average_sales AS (	#CTE for average products sold
	SELECT AVG(products_sold) AS average FROM branch_sales
)
SELECT b.branch AS branch_that_exceeded_the_average_number_of_products_sold FROM branch_sales b
where b.products_sold > (SELECT average FROM average_sales);	#comparing averages from both CTE's 

# 13. Which product line is most frequently associated with each gender?
WITH female_count AS (	#CTE for Female count
	SELECT product_line, COUNT(gender) AS female FROM sales
    WHERE gender = "Female"
    GROUP BY product_line
), male_count AS (	#CTE for Male count
	SELECT product_line, COUNT(gender) AS male FROM sales
    WHERE gender = "Male"
    GROUP BY product_line
)
SELECT f.product_line, f.female, m.male FROM female_count f #Comparing Female and Male by product_line
INNER JOIN male_count m 
ON f.product_line = m.product_line;


# 14. Calculate the average rating for each product line.
SELECT product_line, AVG(rating) AS average_rating FROM sales
GROUP BY product_line;	#Used aggregate function and grouped by product_line for average rating

# 15. Count the sales occurrences for each time of day on every weekday.
SELECT
	COUNT(invoice_id) AS sales_frequency, 	#counting sales
    if(time<"12:00:00", "Morning", (if(time<"16:00:00", "After_Noon", "Evening"))) as time_of_day,	#categorising time into Morning, After_Noon, Evening
    dayname(date) AS week_day	#obtaining day name from date
FROM sales
GROUP BY time_of_day, week_day
order by week_day,time_of_day;

# 16. Identify the customer type contributing the highest revenue.
SELECT customer_type AS customer_type_with_highest_revenue, SUM(total) AS revenue FROM Sales
GROUP BY customer_type
ORDER BY revenue DESC
LIMIT 1;

# 17. Determine the city with the highest VAT percentage.
#From the given data VAT is the total tax on the total order quantity, therefore tax percentage for 1 unit must be calculated
WITH tax AS (
	SELECT city, ((Vat/quantity)/unit_price)*100 AS P_VAT FROM sales
)
SELECT city, MAX(P_VAT) AS MAX_P_VAT FROM tax	#Now finding the maximum vat percentage by city
GROUP BY city
ORDER BY MAX_P_VAT DESC
LIMIT 1;

# 18. Identify the customer type with the highest VAT payments.
SELECT customer_type, MAX(vat) AS M_VAT FROM sales
GROUP BY customer_type
ORDER BY M_VAT DESC
LIMIT 1;

# 19. What is the count of distinct customer types in the dataset?
SELECT COUNT(DISTINCT customer_type) AS customer_types FROM sales;

#20. What is the count of distinct payment methods in the dataset?
SELECT COUNT(DISTINCT payment_method) AS payment_methods FROM sales;
 
 #21. Which customer type occurs most frequently?
 SELECT DISTINCT customer_type, COUNT(customer_type) AS frequency FROM sales
 GROUP BY customer_type
 ORDER BY frequency DESC;
 
 #22. Identify the customer type with the highest purchase frequency.
 SELECT DISTINCT customer_type, COUNT(customer_type) AS frequency FROM sales
 GROUP BY customer_type
 ORDER BY frequency DESC
 LIMIT 1;
 
 #23. Determine the predominant gender among customers.
 SELECT gender, COUNT(gender) AS frequency FROM sales
 GROUP BY gender
 ORDER BY frequency DESC
 LIMIT 1;
 
 #24. Examine the distribution of genders within each branch.
WITH female_count AS (
	SELECT branch, COUNT(gender) AS Female FROM sales
	WHERE gender = "Female"
	GROUP BY branch
 ), male_count AS (
	SELECT branch, COUNT(gender) AS Male FROM sales
	WHERE gender = "Male"
	GROUP BY branch
 )
 SELECT f.branch, f.Female, m.Male FROM female_count f
 INNER JOIN male_count m
 ON f.branch = m.branch;
 
 # 25. Identify the time of day when customers provide the most ratings.
 WITH time_data AS (
	SELECT rating, if(time<"12:00:00", "Morning", (if(time<"16:00:00", "After_Noon", "Evening"))) AS time FROM sales
)
SELECT count(rating) AS rating_frequency, time FROM time_data
GROUP BY time
ORDER BY rating_frequency DESC
LIMIT 1;

# 26. Determine the time of day with the highest customer ratings for each branch.
 WITH time_data AS (
	SELECT branch, if(time<"12:00:00", "Morning", (if(time<"16:00:00", "After_Noon", "Evening"))) AS time, rating FROM sales
), branch_frequency AS (
	SELECT branch, time, count(rating) AS rating_frequency FROM time_data
	GROUP BY branch, time
	ORDER BY branch,rating_frequency
)
SELECT branch, time, rating_frequency FROM branch_frequency bf1
WHERE rating_frequency = (
	SELECT MAX(rating_frequency)
    FROM branch_frequency bf2
    WHERE bf1.branch = bf2.branch
    ); 
    
# 27. Identify the day of the week with the highest average ratings.
SELECT dayname(date) AS day, COUNT(rating) AS rating_frequency FROM sales
GROUP BY day
ORDER BY rating_frequency DESC
LIMIT 1;
 
# 28. Determine the day of the week with the highest average ratings for each branch.
WITH branch_frequency AS (
	SELECT dayname(date) AS day, branch, COUNT(rating) AS rating_frequency FROM sales s1
	GROUP BY day, branch
	ORDER BY rating_frequency DESC
)
SELECT branch, day, rating_frequency FROM branch_frequency b1
HAVING rating_frequency = (
	SELECT MAX(rating_frequency) FROM branch_frequency b2
    WHERE b1.branch = b2.branch
	)
ORDER BY branch;