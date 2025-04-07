use capstone_project_sql;
select * from amazon limit10;

# set the datatypes using alter table. (CATEGORY--VARCHAR(),  NUMERICAL----DECIMAL(10,2))

SELECT COUNT(*) AS row_count FROM amazon;          # 1000 rows
SELECT COUNT(*) AS column_count 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'amazon';                        #  17 columns

-------------------------------------   DATA_CLEANING-----------------------------------------------
# 1. Changed the Data types 

# 2. Check for Missing Values in Entire Dataset

SELECT COUNT(*) AS null_count
FROM amazon
WHERE InvoiceId IS NULL OR branch IS NULL OR City IS NULL 
OR customer_type IS NULL OR gender IS NULL OR product_line IS NULL 
OR Unit_price IS NULL OR Quantity IS NULL OR `Tax_5%` IS NULL OR Total IS NULL OR purchase_Date IS NULL
OR sale_Time IS NULL OR Payment_mode IS NULL OR cogs IS NULL OR gross_margin_percentage IS NULL
OR gross_income IS NULL OR Rating IS NULL;

# 3. CHECKING DUPLICATES

SELECT InvoiceID, Branch, City, Customer_type, Gender, Product_line, Unit_price, 
       Quantity, `Tax_5%`, Total, Purchase_Date, sale_Time, Payment_mode, 
       cogs, gross_margin_percentage, gross_income, Rating, COUNT(*) AS duplicate_count
FROM amazon 
GROUP BY InvoiceID, Branch, City, Customer_type, Gender, Product_line, Unit_price, 
         Quantity, `Tax_5%`, Total, Purchase_Date, sale_Time, Payment_mode, 
         cogs, gross_margin_percentage, gross_income, Rating
HAVING COUNT(*) > 1;

----------------------------------------------------------- Feature Engineering:----------------------------------------------
------------- EXTRACTION OF MONTH NAME, DAY NAME, TIME OF DAY FROM DATE & TIME COLUMNS ---------------------------------------

/*Feature Engineering: This will help us generate some new columns from existing ones.


2.1  Add a new column named timeofday to give insight of sales in the Morning, Afternoon and Evening. 
     This will help answer the question on which part of the day most sales are made.

2.2  Add a new column named dayname that contains the extracted days of the week on which the given transaction took place 
     (Mon, Tue, Wed, Thur, Fri). This will help answer the question on which week of the day each branch is busiest.

2.3  Add a new column named monthname that contains the extracted months of the year on which the given transaction took place
     (Jan, Feb, Mar). Help determine which month of the year has the most sales and profit.
*/
# CREATING TIMEOFDAY COLUMN

ALTER TABLE amazon ADD timeofday varchar(20);

SET SQL_SAFE_UPDATES = 0;       # to update or delete rows without restrictions (disabled the safe mode)

UPDATE amazon
SET timeofday = 
    CASE 
        WHEN HOUR(sale_time) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN HOUR(sale_time) BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Night'
    END;
   
SELECT DISTINCT timeofday from amazon;   

#  Adding a new column named dayname that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri, Sat, Sun). 
 
ALTER table amazon ADD dayname VARCHAR(10);

UPDATE amazon 
SET dayname = DAYNAME(purchase_date);

SELECT DISTINCT dayname from amazon;


# Add a new column named monthname that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar).

ALTER table amazon ADD monthname VARCHAR(10);

UPDATE amazon 
SET monthname = monthname(purchase_date);

SELECT DISTINCT monthname from amazon;

SET SQL_SAFE_UPDATES = 1;

-------------------------------------------------------   EDA   ------------------------------------------------------
#3. Exploratory Data Analysis (EDA): Exploratory data analysis is done to answer the listed questions and aims of this project.

#1. What is the count of distinct cities in the dataset?

SELECT COUNT(DISTINCT City) AS distinct_city_count FROM amazon;   # 3

select distinct city  from amazon;   # Yangon, Mandalay, Naypyitaw

#2. For each branch, what is the corresponding city?
select branch, city from amazon group by 1, 2 order by branch asc;  # or
select distinct branch, city from amazon order by branch asc;
/* Result:
A	Yangon
B	Mandalay
C	Naypyitaw
*/

#3. What is the count of distinct product lines in the dataset?
select count(distinct(product_line)) from amazon;    # 6
select distinct product_line from amazon;
/* 
Health and beauty
Electronic accessories
Home and lifestyle
Sports and travel
Food and beverages
Fashion accessories
*/
#4. Which payment method occurs most frequently?
select distinct payment_mode from amazon; # Ewallet, Cash, Credit card

select distinct payment_mode, count(payment_mode) from amazon group by 1  order by 2 desc;  # Ewallet
/*
Ewallet	    345
Cash	    344
Credit card	311
*/

#5. Which product line has the highest sales?  # Electronic accessories	  971
#   Sales = Total Quantity Sold

# CALLING VIEW 
select * from product_sales order by total_sales desc;

/*
Product_line              total_sales
Electronic accessories	  971
Food and beverages	      952
Sports and travel	      920
Home and lifestyle	      911
Fashion accessories	      902
Health and beauty	      854
*/

#6. How much revenue is generated each month?

/*
Which One is Better?
✅ For investors & tax reports → Use Gross Revenue
✅ For business insights & profit analysis → Use Net Revenue

Most businesses and e-commerce platforms focus on Net Revenue because it represents actual earnings after taxes.
*/

SELECT monthname(Purchase_Date) AS month, SUM(cogs) AS net_revenue, sum(quantity) as sales
FROM amazon GROUP BY 1  ORDER BY 1, 2, 3 desc;

/*
January	      110754.16  / 1965
March	      104243.34  / 1891
February       92589.88  / 1654
*/

SELECT SUM(cogs) AS Net_Revenue FROM amazon;
 #307587.38
SELECT SUM(Total) AS Gross_Revenue FROM amazon;
 #322967.43
 
#7. In which month did the cost of goods sold reach its peak?
# As per above result January month the cost of goods sold reach its peak that is ----- 110754.16

#8 Which product line generated the highest revenue?  # Food and beverages	       53471.28
# created view of product revenue

# CALLING VIEW
select * from product_revenue order by 2 desc;

/*product_line           net_revenue
Food and beverages	       53471.28
Sports and travel	       52497.93
Electronic accessories	   51750.03
Fashion accessories        51719.90
Home and lifestyle	       51297.06
Health and beauty	       46851.18
*/

#9. In which city was the highest revenue recorded?          #  Naypyitaw	105303.53
SELECT city, SUM(cogs) AS net_revenue_per_city FROM amazon
GROUP BY 1 ORDER BY 2 desc;
/*
city        net_revenue_per_city
Naypyitaw	105303.53
Yangon	    101143.21
Mandalay	101140.64
*/
#10. Which product line incurred the highest Value Added Tax?   # Food and beverages	        2673.68
select product_line, sum(`tax_5%`) as VAT from amazon
group by 1
order by 2 desc;
/*product_line               VAT
Food and beverages	        2673.68
Sports and travel	        2625.07
Electronic accessories  	2587.61
Fashion accessories	        2586.13
Home and lifestyle	        2564.90
Health and beauty       	2342.66
*/

# 11. For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
# created a view for product product_sales_category
 
select * from product_sales_category order by total_sales desc;
SELECT AVG(total_sales) AS overall_avg FROM Product_sales;          # 918.3333

/*product_line         total_sales    sales_category(918.33 average sales)
Electronic accessories	    971	      Good
Food and beverages	        952	      Good
Sports and travel	        920	      Good
Home and lifestyle	        911	       Bad
Fashion accessories	        902	       Bad
Health and beauty	        854	       Bad
*/

#11.  (REVENUE) For each product line, add a column indicating "Good" if its revenue is above average, otherwise "Bad." 

# view for product line revenue category

## calling view product revenue category
select * from product_revenue_category order by net_revenue desc;
 SELECT AVG(net_revenue) AS revenue_avg FROM product_revenue;       #51264.563333

/*product_line       net_revenue       revenue_category(avg= 51264.563333)
Health and beauty	     46851.18	    Bad
Home and lifestyle	     51297.06    	Good
Fashion accessories	     51719.90	    Good
Electronic accessories	 51750.03   	Good
Sports and travel	     52497.93	    Good
Food and beverages	     53471.28	    Good
*/

#12. Identify the branch that exceeded the average number of products sold.

# finding averarage of products
  SELECT AVG(total_quantity) AS overall_avg
    FROM (SELECT Branch, SUM(Quantity) AS total_quantity FROM amazon GROUP BY Branch) AS subquery;            #overall_avg = 1836.6667
    
WITH branch_sales AS 
    (SELECT City, Branch, SUM(Quantity) AS total_quantity FROM amazon GROUP BY City, Branch),
    avg_sales AS (SELECT AVG(total_quantity) AS overall_avg FROM branch_sales)
SELECT b.City, b.Branch,b.total_quantity AS total_sales, 
       CASE 
           WHEN b.total_quantity > (SELECT overall_avg FROM avg_sales) THEN 'More' ELSE 'Not More'
       END AS sales_excees_average
FROM branch_sales b
ORDER BY b.total_quantity DESC;
    
  #overall_avg = 1836.6667    

/*city    branch      average    sales_exceeds_average
Yangon  	A	       1859 	 More
Naypyitaw	C	       1831      Not More
Mandalay	B	       1820	     Not More
*/ 

#13. Which product line is most frequently associated with each gender?
# Female	Fashion accessories(28988) -- transactions of 	96  with   530 sales 
#  Male	    Health and beauty -- tranctions of   88  with   511  sales 

SELECT Gender, Product_line, COUNT(Product_line) AS transaction_count, sum(Quantity) as sales, sum(cogs)  FROM amazon
GROUP BY Gender, Product_line
ORDER BY sales DESC;

/* gender     product_line     transaction_count  sales
Female	Fashion accessories    	96                 530 
Female	Food and beverages	    90                 514
Female	Sports and travel	    88                 511
Female	Electronic accessories	84                 498
Female	Home and lifestyle	    79                 496
Female	Health and beauty	    64                 488
Male	Health and beauty	    88                 483
Male	Electronic accessories	86                 438
Male	Food and beverages	    84                 424
Male	Fashion accessories	    82                 413
Male	Home and lifestyle  	81                 372
Male	Sports and travel   	78                 343
*/
#14. Calculate the average rating for each product line.

SELECT Product_line, 
       ROUND(AVG(Rating), 2) AS average_rating
FROM amazon
GROUP BY Product_line
ORDER BY average_rating DESC;

/*product_line           average_rating
Food and beverages	         7.11
Fashion accessories	         7.03
Health and beauty	         7.00
Electronic accessories	     6.92
Sports and travel          	 6.92
Home and lifestyle	         6.84
*/
#15. Count the sales occurrences for each time of day on every weekday.----------------- to this created a stored procedure also.


# 'saturday' was the highest sales with 919 quantity 53,448 revenue and 'afternoon' was the highest sales with 2946 quantity, 1,64,255.77 revenue
#  Monday  was the lowest sales with 638 quantity, 36,094 revenue and morning  was the lowest sales with 1038 quantity, 58856.01 revenue

#  CALLING VIEW
select dayname, transaction_count, daily_sales from sales_by_time_of_day  order by daily_sales desc;
select timeofday, transaction_count, timeofday_sales from sales_by_time_of_day  order by timeofday_sales desc;
select sum(total_sales) from sales_by_time_of_day;

 
 # creatED a stored procedure  to filter a day of week and time of a day SALES
  
call get_sales_day_time_filter('SATURDAY', NULL);
call get_sales_day_time_filter('tuesday', 'morning'); 
call get_sales_day_time_filter(NULL, 'AFTERNOON');
 

 #16.   Identify the customer type contributing the highest revenue.   #  Member        	156403.28
 SELECT Customer_type, SUM(cogs) AS net_revenue
FROM amazon GROUP BY 1 ORDER BY 2 DESC;
/*
customer_type    net_revenue
Member        	156403.28
Normal      	151184.10    
*/

#17. Determine the city with the highest VAT percentage.  #  Naypyitaw	5265.33
SELECT City, SUM(`Tax_5%`) AS total_vat_collected FROM amazon
GROUP BY City ORDER BY total_vat_collected DESC;
/*
Naypyitaw	5265.33
Yangon	    5057.36
Mandalay	5057.36
*/

#18. Identify the customer type with the highest VAT payments.   # Member	7820.53
SELECT customer_type, SUM(`Tax_5%`) AS total_vat_paid
FROM amazon GROUP BY 1 ORDER BY 2 DESC;
/*
Member	7820.53
Normal	7559.52
*/

#19. What is the count of distinct customer types in the dataset?         # 2 types
SELECT COUNT(DISTINCT Customer_type) AS distinct_customer_types       
FROM amazon;     
   
#20. What is the count of distinct payment methods in the dataset?
SELECT COUNT(DISTINCT Payment_mode) AS distinct_payment_methods          # 3 modes
FROM amazon;
select distinct payment_mode from amazon;                                # Ewallet, Cash, Credit card

#21. Which customer type occurs most frequently?
#22. Identify the customer type with the highest purchase frequency.
# Member	501,  Normal	499

# member type has highest purchase frequency with 501 transactions.
SELECT Customer_type, COUNT(*) AS occurrence_count
FROM amazon GROUP BY 1 ORDER BY 2 DESC;                                                     #Member = 501, Normal = 499

#23. Determine the predominant gender among customers.
# Females are dominant customers
SELECT Gender, COUNT(*) AS gender_count, sum(cogs) as GenderRevenue, sum(quantity) as GenderSales FROM amazon
 GROUP BY Gender ORDER BY 2 DESC;
 /*  Gender  Tx     Revenue      sales
    Female	 501	159888.50	  2869
     Male	499	    147698.88	  2641

#24 Examine the distribution of genders within each branch.
SELECT Branch, city,  Gender, COUNT(*) AS gender_count FROM amazon
GROUP BY Branch, city, Gender ORDER BY 1, 3 DESC;
/*
A	Yangon  	Male	179
A	Yangon	    Female	161
B	Mandalay	Male	170
B	Mandalay	Female	162
C	Naypyitaw	Female	178
C	Naypyitaw	Male	150
*/
#25.  Identify the time of day when customers provide the most ratings.        # Afternoon	528
SELECT timeofday, COUNT(Rating) AS rating_count FROM amazon
GROUP BY timeofday ORDER BY rating_count DESC;

/*  
Afternoon	528
Evening	    281
Morning	    191
*/

#26. Determine the time of day with the highest customer ratings for each branch.   # afternoon
WITH ratings_per_branch AS (
    SELECT Branch, timeofday, COUNT(Rating) AS rating_count,
           RANK() OVER (PARTITION BY Branch ORDER BY COUNT(Rating) DESC) AS rnk
    FROM amazon
    GROUP BY Branch, timeofday
)
SELECT Branch, timeofday, rating_count
FROM ratings_per_branch
WHERE rnk = 1;
/*
A	Afternoon	185
B	Afternoon	162
C	Afternoon	181
*/
#27 Identify the day of the week with the highest average ratings         # Monday with 7.1536

SELECT dayname, AVG(Rating) AS avg_rating
FROM amazon
GROUP BY dayname
ORDER BY avg_rating DESC;
/*
Monday	7.153600
Friday	7.076259
Sunday	7.011278
Tuesday	7.003165
Saturday	6.901829
Thursday	6.889855
Wednesday	6.805594
*/

#28. Determine the day of the week with the highest average ratings for each branch.
WITH avg_ratings AS (
    SELECT Branch, city, dayname, AVG(Rating) AS avg_rating,
           RANK() OVER (PARTITION BY Branch ORDER BY AVG(Rating) DESC) AS rnk
    FROM amazon
    GROUP BY Branch, city, dayname
)
SELECT Branch,city, dayname, avg_rating
FROM avg_ratings WHERE rnk = 1;
/*
A	Yangon	    Friday	7.312000
B	Mandalay	Monday	7.335897
C	Naypyitaw	Friday	7.278947
*/

----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------




# CALLING VIEW

select dayname, transaction_count, daily_revenue from revenue_by_time_of_day  order by daily_revenue desc;
select timeofday, transaction_count, timeofday_revenue from revenue_by_time_of_day  order by timeofday_revenue desc;
select sum(total_revenue) from revenue_by_time_of_day;



# 5TH QUESTION 
#  created view of product sales
CREATE VIEW product_sales AS
SELECT Product_line, SUM(Quantity) AS total_sales
FROM amazon
GROUP BY 1 ORDER BY 2;

# 8TH QUESTION

CREATE VIEW product_revenue AS
SELECT Product_line, SUM(cogs) AS net_revenue
FROM amazon
GROUP BY 1  order by 2;


#  11TH QUESTION VIEW

CREATE VIEW product_sales_category AS 
WITH avg_sales AS (
    SELECT AVG(total_sales) AS overall_avg FROM Product_sales
)
SELECT p.product_line, 
       p.total_sales,
       CASE 
           WHEN p.total_sales > (SELECT overall_avg FROM avg_sales) THEN 'Good'
           ELSE 'Bad'
       END AS sales_category
FROM product_sales p;

#  11TH QUESTION    REVENUE

CREATE VIEW product_revenue_category AS 
WITH avg_revenue AS (                                                   # cte creates with temporary result set
    SELECT AVG(net_revenue) AS revenue_avg FROM product_revenue
)
SELECT p.Product_line, p.net_revenue,
       CASE                                                                                       # case expression: series of conditional statements 
           WHEN p.net_revenue > (SELECT revenue_avg FROM avg_revenue) THEN 'Good'                    # and creates temporary col as revenue_category
           ELSE 'Bad'
       END AS revenue_category
FROM product_revenue p;


#         15 TH QUESTION  :   SALES

CREATE VIEW sales_by_time_of_day AS
WITH sales_data AS (
    SELECT dayname, timeofday, COUNT(*) AS transaction_count, SUM(Quantity) AS total_sales FROM amazon
    GROUP BY dayname, timeofday
)
SELECT dayname, timeofday, transaction_count, total_sales,
    SUM(total_sales) OVER (PARTITION BY dayname) AS daily_sales,
    SUM(total_sales) OVER (PARTITION BY timeofday) AS timeofday_sales
FROM sales_data;



# 15th question_ revenue

CREATE VIEW revenue_by_time_of_day AS
WITH revenue_data AS (
    SELECT dayname, timeofday, COUNT(*) AS transaction_count, SUM(cogs) AS total_revenue FROM amazon
    GROUP BY dayname, timeofday
)
SELECT dayname, timeofday, transaction_count, total_revenue,
    SUM(total_revenue) OVER (PARTITION BY dayname) AS daily_revenue,
    SUM(total_revenue) OVER (PARTITION BY timeofday) AS timeofday_revenue
FROM revenue_data;


# STORED PROCEDURE  SALES

DELIMITER $$

CREATE PROCEDURE get_sales_day_time_filter(
    IN day_filter VARCHAR(10), 
    IN time_filter VARCHAR(20)
)
BEGIN
    WITH sales_data AS (
        SELECT dayname, timeofday, COUNT(*) AS transaction_count, SUM(Quantity) AS total_sales FROM amazon
        WHERE (dayname = day_filter OR day_filter IS NULL)
          AND (timeofday = time_filter OR time_filter IS NULL)
        GROUP BY dayname, timeofday
    )
    SELECT dayname, timeofday, transaction_count,total_sales,
        SUM(total_sales) OVER (PARTITION BY dayname) AS daily_sales,
        SUM(total_sales) OVER (PARTITION BY timeofday) AS timeofday_sales
    FROM sales_data;
    
END $$
DELIMITER ;


 # creating a stored procedure  to filter a day of week and time of a day REVENUE
  
DELIMITER $$

CREATE PROCEDURE get_REVENUE_day_time_filter(
    IN day_filter VARCHAR(10), 
    IN time_filter VARCHAR(20)
)
BEGIN
    WITH REVENUE_data AS (
        SELECT dayname, timeofday, COUNT(*) AS transaction_count, SUM(COGS) AS total_REVENUE FROM amazon
        WHERE (dayname = day_filter OR day_filter IS NULL)
          AND (timeofday = time_filter OR time_filter IS NULL)
        GROUP BY dayname, timeofday
    )
    SELECT dayname, timeofday, transaction_count,total_REVENUE,
        SUM(total_REVENUE) OVER (PARTITION BY dayname) AS daily_REVENUE,
        SUM(total_REVENUE) OVER (PARTITION BY timeofday) AS timeofday_REVENUE
    FROM REVENUE_data;
    
END $$
DELIMITER ;

