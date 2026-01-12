USE laptop_data;
SET SQL_SAFE_UPDATES = 0;
-- 1. Create a backup of original data 
CREATE TABLE laptopdata_uncleaned_staging AS
SELECT * FROM laptopdata_uncleaned;

-- Change name of a Unnamed column and to index
ALTER TABLE laptopdata_uncleaned_staging
RENAME COLUMN `Unnamed: 0` to `Index`;

-- 2. Check no. of rows
Select count(*)
FROM laptopdata_uncleaned_staging

-- 3. Check memory consumption 
SELECT DATA_LENGTH/1024 FROM INFORMATION_SCHEMA.tables
WHERE TABLE_SCHEMA = 'laptop_data'
AND Table_name = 'laptopdata_uncleaned_staging2' 

-- 4. DROP NULL VALUES
DELETE FROM laptopdata_uncleaned_staging 
WHERE company is null and TypeName is null and Inches is null and ScreenResolution is null
and `Cpu` is null and Ram is null and `Memory` is null and Gpu is null and Opsys is null
and Weight is null and Price is null 

-- 5. DROP DUPLICATES
CREATE TABLE `laptopdata_uncleaned_staging2` (    -- Created a 2nd staging table to delete duplicates using row_number()
  `Index` int DEFAULT NULL,
  `Company` text,
  `TypeName` text,
  `Inches` double DEFAULT NULL,
  `ScreenResolution` text,
  `Cpu` text,
  `Ram` text,
  `Memory` text,
  `Gpu` text,
  `OpSys` text,
  `Weight` text,
  `Price` double DEFAULT NULL,
  Row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO laptopdata_uncleaned_staging2
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY company,TypeName,Inches,ScreenResolution,`Cpu`,Ram,`Memory`,Gpu,Opsys,Weight,Price) AS row_num
       FROM laptopdata_uncleaned_staging;


DELETE FROM laptopdata_uncleaned_staging2  -- Deleted all the duplicate rows
WHERE Row_num>1;

ALTER TABLE laptopdata_uncleaned_staging2 -- Dropped non-important row_num column
DROP COLUMN Row_num;

-- 6. Cleaning RAM column --> Change col data-type
UPDATE laptopdata_uncleaned_staging2
SET Ram = replace(Ram,'GB','')

ALTER TABLE laptopdata_uncleaned_staging2
MODIFY COLUMN Ram INT;

-- 7. Cleaning Weight -> Change col type
UPDATE laptopdata_uncleaned_staging2
SET weight = replace(Weight,'kg','')

UPDATE laptopdata_uncleaned_staging2
SET weight = NULL 
WHERE weight NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

ALTER TABLE laptopdata_uncleaned_staging2
MODIFY Weight float

-- 8. ROUND Price col and change to integer
UPDATE laptopdata_uncleaned_staging2
SET Price = ROUND(Price)

ALTER TABLE laptopdata_uncleaned_staging2
MODIFY COLUMN Price INT;

-- 10. Change the Opsys Column
UPDATE laptopdata_uncleaned_staging2
SET OpSys = CASE 
				WHEN Opsys LIKE '%windows%' THEN 'Windows'
                WHEN Opsys LIKE '%Linux%' THEN 'Linux'
                WHEN Opsys LIKE '%chrome%' THEN 'ChromeOS'
                WHEN Opsys LIKE '%mac%' THEN 'macOS'
                WHEN Opsys = 'No OS' THEN 'No OS'
                ELSE 'Other'
			END
-- 11. Adding two colums for Gpu name and Gpu brand and dropping Gpu
ALTER TABLE laptopdata_uncleaned_staging2
ADD COLUMN Gpu_brand VARCHAR(255) AFTER Gpu,
ADD COLUMN Gpu_name VARCHAR(255) AFTER Gpu_brand;

UPDATE laptopdata_uncleaned_staging2 
SET Gpu_brand = SUBSTRING_INDEX(Gpu,' ',1)

UPDATE laptopdata_uncleaned_staging2 
SET Gpu_name = Replace(Gpu,Gpu_brand,'')


ALTER TABLE laptopdata_uncleaned_staging2 
DROP COLUMN Gpu

-- 12. Adding two columns for cpu_brand, cpu_name and cpu_speed and cpu column
ALTER TABLE laptopdata_uncleaned_staging2
ADD COLUMN cpu_brand VARCHAR(255) AFTER cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_name

UPDATE laptopdata_uncleaned_staging2 -- Inserted values in cpu_brand column using Cpu column
SET cpu_brand = SUBSTRING_INDEX(Cpu,' ',1)


UPDATE laptopdata_uncleaned_staging2 -- Inserted values in cpu_speed column using Cpu column
SET cpu_speed =  Replace(SUBSTRING_INDEX(`Cpu`,' ',-1),'GHz','')

UPDATE laptopdata_uncleaned_staging2 -- Inserted values in cpu_name column using Cpu column
SET cpu_name = Replace(Replace(Replace(cpu,cpu_brand,''),cpu_speed,''),'GHz','')

ALTER TABLE laptopdata_uncleaned_staging2 --  Dropped Cpu column
DROP COLUMN Cpu;

UPDATE laptopdata_uncleaned_staging2 -- This is more precise 
SET cpu_name =  SUBSTRING_INDEX(TRIM(cpu_name),' ',2)


-- 13.Adding 3 columns for Resolution width,Resolution height and Touchscreen
ALTER TABLE laptopdata_uncleaned_staging2
ADD COLUMN ResolutionWidth INTEGER AFTER ScreenResolution,
ADD COLUMN ResolutionHeight INTEGER AFTER ResolutionWidth,
ADD COLUMN Touchscreen  INTEGER AFTER ResolutionHeight


UPDATE laptopdata_uncleaned_staging2  -- 	Updated ResolutionWidth column using ScreenResolution Column
SET ResolutionWidth =  SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1);

UPDATE laptopdata_uncleaned_staging2  -- Updated ResolutionHeight column using ScreenResolution Column
SET ResolutionHeight =  SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1);

UPDATE laptopdata_uncleaned_staging2   -- Update Touchscreen column with the help of screenResolution column that whether it is touchcsreen or not
SET Touchscreen = CASE 
					  WHEN ScreenResolution LIKE '%Touchscreen%' THEN 1 ELSE 0
				  END;
ALTER TABLE laptopdata_uncleaned_staging2  -- Dropped column ScreenResolution
DROP COLUMN ScreenResolution

-- 14. Adding 3 columns for Memory type,Primary_storage and Secondary_storage which are derived from Memory column 
ALTER TABLE laptopdata_uncleaned_staging2
ADD COLUMN Memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN Primary_storage INTEGER AFTER Memory_type,
ADD COLUMN Secondary_storage INTEGER AFTER Primary_storage

UPDATE laptopdata_uncleaned_staging2  -- Updated Memory type 
SET Memory_type =  CASE 
                       WHEN Memory LIKE '%+%' THEN 'Hybrid'
                       WHEN Memory LIKE '%HDD%'  THEN 'HDD'
                       WHEN Memory LIKE '%SSD%'  THEN 'SSD'
                       WHEN Memory LIKE '%Flash Storage%'  THEN 'Flash storage'
                       WHEN Memory LIKE '%Hybrid%'  THEN 'Hybrid'
                       ELSE NULL
					END
                    
UPDATE laptopdata_uncleaned_staging2 -- Extracting Primary_storage from memory column
SET Primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+')

UPDATE laptopdata_uncleaned_staging2 -- Extracting Secondary storage from memory column
SET Secondary_storage = CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0
                        END

UPDATE laptopdata_uncleaned_staging2 -- Converting TB to GB 
SET Primary_storage = CASE WHEN Primary_storage<=2 THEN Primary_storage * 1024 ELSE Primary_storage END 

UPDATE laptopdata_uncleaned_staging2 -- Converting TB to GB
SET Secondary_storage = CASE WHEN Secondary_storage<=2 THEN Secondary_storage * 1024 ELSE Secondary_storage END 

ALTER TABLE laptopdata_uncleaned_staging2  -- Dropping Memory Column
DROP COLUMN Memory

ALTER TABLE laptopdata_uncleaned_staging2 -- Dropping Gpu_name
DROP COLUMN Gpu_name;