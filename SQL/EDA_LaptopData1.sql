USE laptop_data
SET SQL_SAFE_UPDATES =  0
-- EDA Begins..
Select * from laptopdata_uncleaned_staging2;

-- 1. Head, Tail and Sample
Select * from laptopdata_uncleaned_staging2   -- Head
ORDER BY `Index` LIMIT 5;

Select * from laptopdata_uncleaned_staging2   -- Tail
ORDER BY  `Index` DESC LIMIT 5;

Select * from laptopdata_uncleaned_staging2   -- Sample
ORDER BY RAND()  LIMIT 5;

-- 2. For Numerical Columns -> Univariate analysis
      -- For Price Column -> 8 number Summary
WITH ranking AS ( SELECT *,
                         ROW_NUMBER() OVER(ORDER BY Price) AS rnk,
                         COUNT(*) OVER() AS cnt
                         FROM laptopdata_uncleaned_staging2
                         )
SELECT MAX(cnt) AS Count,  -- 1243
       MIN(Price) AS Min,  -- 9271
       MAX(Price) AS Max,  -- 324955
       AVG(Price) AS Mean,  -- 60551.82230
       stddev(Price) AS Std, -- 37375.33183787402
       MAX(CASE WHEN rnk = FLOOR(0.25 * cnt) THEN Price END) AS 'Q1', -- 32448
       MAX(CASE WHEN rnk = FLOOR(0.5 * cnt) THEN Price END) AS 'Median', -- 52694
       MAX(CASE WHEN rnk = FLOOR(0.75 * cnt) THEN Price END) AS 'Q3' -- 79654
FROM ranking;  

--  Missing Values
SELECT COUNT(Price)  -- 0 Null values found
       FROM laptopdata_uncleaned_staging2
       WHERE price is null;

-- Outlier detection of Price Column 
WITH ranking AS ( SELECT *,
                         ROW_NUMBER() OVER(ORDER BY Price) AS rnk,
                         COUNT(*) OVER() AS cnt
                         FROM laptopdata_uncleaned_staging2
                         ),
summary as ( SELECT * ,
             MAX(CASE WHEN rnk = FLOOR(0.25 * cnt) THEN Price END) OVER() AS 'Q1', -- 32448
			 MAX(CASE WHEN rnk = FLOOR(0.5 * cnt) THEN Price END) OVER() AS 'Median', -- 52694
			 MAX(CASE WHEN rnk = FLOOR(0.75 * cnt) THEN Price END) OVER()  AS 'Q3' -- 79654
FROM ranking)
 

SELECT * FROM summary
WHERE Price < Q1 - 1.5*(Q3 - Q1) OR Price > Q3 + 1.5*(Q3 - Q1)

-- Vertical Histogram

select buckets, REPEAT('*' , COUNT(*)/5) from (SELECT Price,
CASE   WHEN Price Between 0 and 25000 THEN '0-25K'
	   WHEN Price Between 25001 and 50000 THEN '25-50K'
	   WHEN Price Between 50001 and 75000 THEN '50-75K' 
	   WHEN Price Between 75001 and 100000 THEN '75K-100K' 
       ELSE '>100K' 
END AS 'buckets'
FROM laptopdata_uncleaned_staging2)t
GROUP BY buckets;

-- 3. For Categorical  columns -> Value counts  -- Univariate analysis
SELECT Company,count(company) AS No_of_laptops
FROM laptopdata_uncleaned_staging2
GROUP BY Company

   -- Missing Values
   SELECT Company    -- Company column has 0 null values
   FROM laptopdata_uncleaned_staging2
   WHERE Company is null;
-- 4. Bi-Variate analysis
     -- Numerical-Numerical column -> Cpu_speed and price scatterplot
      SELECT cpu_speed, Price   -- You can visulaise this in excel or python using scatterplot
      FROM laptopdata_uncleaned_staging2;
    -- Correlation of Cpu_speed and price 
      SELECT (
               count(*) * sum(price * cpu_speed)
				- (SUM(Price)) * (SUM(cpu_speed))
             )
             / 
             SQRT(
                  (COUNT(*) * SUM(Price * Price) - POWER(SUM(Price),2)) * 
                  (COUNT(*) * SUM(cpu_speed * cpu_speed) - POWER(SUM(cpu_speed),2))
             
             ) AS Correlation
      
      FROM laptopdata_uncleaned_staging2
      WHERE Price is not null  and cpu_speed is not null;

	-- Categorical and Categorical column
      -- Contigencty table of Company and touchscreen column
      SELECT Company,
             SUM(CASE WHEN Touchscreen = 1 THEN 1 ELSE 0 END) AS Touchscreen_yes,
             SUM(CASE WHEN Touchscreen = 0 THEN 1 ELSE 0 END) AS Touchscreen_No
	FROM laptopdata_uncleaned_staging2
    GROUP BY Company;
    
    -- Contigency table Company and cpu_brand
    SELECT Company,
             SUM(CASE WHEN Touchscreen = 'Intel' THEN 1 ELSE 0 END) AS Intel,
             SUM(CASE WHEN Touchscreen = 'AMD' THEN 1 ELSE 0 END) AS AMD,
             SUM(CASE WHEN Touchscreen = 'Samsung' THEN 1 ELSE 0 END) AS Smasung
	FROM laptopdata_uncleaned_staging2
    GROUP BY Company;
    
    -- Numerical - Categorical
       -- Compare distribution across categories
SELECT Company,
       MIN(Price) AS Minimum_price,
       MAX(Price) AS Maximum_price,
       AVG(Price) AS Average_price,
       STDDEV(Price)  AS std
FROM 
laptopdata_uncleaned_staging2 
WHERE Company is not null
GROUP BY Company

-- 5. Dealing with missing value
      -- There are no missing values in the data but if there are missing values in the dataset
        -- 1. you can impute with the mean value of the complete column of that column
        -- 2. you can impute value with mean value of that correspnding category
        -- 3. You can drop the missing values
        -- 4. You can take the combination of two columns and then impute them
      
-- 6.Feature Engineering
    -- Creating a new column ppi using resolution width,height and inches 
     ALTER TABLE laptopdata_uncleaned_staging2 
     ADD COLUMN ppi INT
     
     UPDATE laptopdata_uncleaned_staging2   -- Ppi calculaation and updation 
     SET ppi = SQRT(ResolutionWidth * ResolutionWidth + ResolutionHeight * ResolutionHeight)/Inches
     
     ALTER TABLE laptopdata_uncleaned_staging2 
     ADD COLUMN screen_size VARCHAR(255)
	
    UPDATE laptopdata_uncleaned_staging2
    SET screen_size = CASE 
                           WHEN Inches<14.0 THEN 'Small Screen'
                           WHEN Inches>14.0 AND Inches<17.0 THEN 'Medium Screen'
                           ELSE 'Large Screen '
					  END

-- 7. One-hot-encoding
SELECT gpu_brand,
                  CASE WHEN gpu_brand = 'Intel' THEN 1 ELSE 0 END AS Intel,
                  CASE WHEN gpu_brand = 'Amd' THEN 1 ELSE 0 END AS Amd,
                  CASE WHEN gpu_brand = 'Nvidia' THEN 1 ELSE 0 END AS Nvidia,
                  CASE WHEN gpu_brand = 'Arm' THEN 1 ELSE 0 END AS Arm
FROM laptopdata_uncleaned_staging2