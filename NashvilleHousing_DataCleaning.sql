-- Cleaning Data in SQL 
-- (Reference: Alex the Analyst)

SELECT * 
FROM nashville_housing
ORDER BY parcel_id

-----------------------------------------
 
-- Populate Property Address Data 

SELECT *
FROM nashville_housing 
--WHERE property_address IS NULL
ORDER BY parcel_id

SELECT a.parcel_id, a.property_address, b.parcel_id, b.property_address,
	COALESCE(a.property_address,b.property_address)
FROM nashville_housing as a 
JOIN nashville_housing as b 
	ON a.parcel_id = b.parcel_id
	AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL

UPDATE nashville_housing as a 
SET property_address = b.property_address
FROM nashville_housing as b 
WHERE a.parcel_id = b.parcel_id
	AND a.unique_id <> b.unique_id 
	AND a.property_address IS NULL
	
	
	
-----------------------------------------

-- Breaking out Address Into Individual Columns (Address, City, State)

SELECT property_address
FROM nashville_housing 
--WHERE property_address IS NULL
--ORDER BY parcel_id

SELECT split_part(property_address, ',',1) as address, 
	split_part(property_address, ',',2) as city
FROM nashville_housing 
ORDER BY parcel_id

ALTER TABLE nashville_housing 
ADD property_split_address varchar(255)

UPDATE nashville_housing 
SET property_split_address = split_part(property_address, ',',1)

ALTER TABLE nashville_housing 
ADD property_split_city varchar(255)

UPDATE nashville_housing
SET property_split_city = split_part(property_address, ',',2)


SELECT split_part(owner_address, ',', 1) as owner_split_address,
	split_part(owner_address, ',', 2) as owner_split_city,
	split_part(owner_address, ',', 3) as owner_split_state
FROM nashville_housing
ORDER BY parcel_id


ALTER TABLE nashville_housing 
ADD owner_split_address varchar(255)

UPDATE nashville_housing
SET owner_split_address = split_part(owner_address, ',', 1)

ALTER TABLE nashville_housing 
ADD owner_split_city varchar(255)

UPDATE nashville_housing
SET owner_split_city = split_part(owner_address, ',', 2)

ALTER TABLE nashville_housing 
ADD owner_split_state varchar(255)

UPDATE nashville_housing
SET owner_split_state = split_part(owner_address, ',', 3)


-----------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(sold_as_vacant), COUNT(sold_as_vacant)
FROM nashville_housing
WHERE sold_as_vacant IS NOT NULL
GROUP BY sold_as_vacant
ORDER BY 2

SELECT sold_as_vacant, 
	CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
	WHEN sold_as_vacant = 'N' THEN 'No'
	ELSE sold_as_vacant
	END
FROM nashville_housing
WHERE sold_as_vacant IS NOT NULL

UPDATE nashville_housing 
SET sold_as_vacant = CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
	WHEN sold_as_vacant = 'N' THEN 'No'
	ELSE sold_as_vacant
	END
	
-----------------------------------------

-- Delete duplicates

WITH RowNumCTE as( 
SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY parcel_id, 
		property_address, 
		sale_price, 
		sale_date, 
		legal_reference ORDER BY unique_id) as row_num
FROM nashville_housing 
--ORDER BY parcel_id
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY property_address 

-----------------------------------------

SELECT * 
FROM nashville_housing as c, nashville_housing as d
WHERE c.parcel_id = d.parcel_id
	AND c.property_address = d.property_address
	AND c.sale_price = d.sale_price
	AND c.sale_date = d.sale_date
	AND c.legal_reference = d.legal_reference
	AND c.property_address = d.property_address
	AND c.unique_id <> d.unique_id
ORDER BY c.parcel_id

DELETE FROM nashville_housing 
WHERE unique_id IN (
    SELECT d.unique_id 
    FROM nashville_housing as c, nashville_housing as d
    WHERE c.parcel_id = d.parcel_id
	AND c.property_address = d.property_address
	AND c.sale_price = d.sale_price
	AND c.sale_date = d.sale_date
	AND c.legal_reference = d.legal_reference
	AND c.property_address = d.property_address
	AND c.unique_id <> d.unique_id)
	

-----------------------------------------

-- Delete unused columns 

SELECT * 
FROM nashville_housing 
ORDER BY parcel_id

ALTER TABLE nashville_housing
DROP COLUMN owner_address,
DROP COLUMN tax_district,
DROP COLUMN property_address,
DROP COLUMN sale_date



