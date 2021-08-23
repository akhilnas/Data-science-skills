/*
	Cleaning Data of Nashville Housing Dataset

*/

-- Data Inspection
SELECT *
FROM Nashville_Housing..NashvilleHousing

SELECT TOP 100 *
FROM Nashville_Housing..NashvilleHousing

-- Date format correction in SaleDate Column

SELECT SaleDate
FROM Nashville_Housing..NashvilleHousing

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM Nashville_Housing..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDate_Correct DATE

UPDATE NashvilleHousing
SET SaleDate_Correct = CONVERT(Date, SaleDate)

SELECT SaleDate_Correct
FROM Nashville_Housing..NashvilleHousing

-- Populate Property Address

SELECT *
FROM Nashville_Housing..NashvilleHousing
WHERE PropertyAddress IS NULL

/* Each Property may have multiple transactiosn between owners. The Parcel ID denotes the ID of the property whiel the uniqueID is the ID of the transaction.

Idea: ParcelID values can be matched with Property Address values using the transactional history in the dataset.
*/

SELECT *
FROM Nashville_Housing..NashvilleHousing
WHERE ParcelID IS NULL

/* There is no NULL value for ParcelID */

-- Visulaize Property Address that is null but the same ParcelID in another transaction has a Property Address associated

SELECT MAIN.ParcelID, MAIN.PropertyAddress, TEMP.ParcelID, TEMP.PropertyAddress
FROM Nashville_Housing..NashvilleHousing MAIN
JOIN Nashville_Housing..NashvilleHousing TEMP
	ON MAIN.ParcelID = TEMP.ParcelID
	AND MAIN.[UniqueID ] <> TEMP.[UniqueID ]
WHERE MAIN.PropertyAddress IS NULL

-- Updating NULL entries with the matched Property Address values

UPDATE MAIN
SET PropertyAddress = ISNULL(MAIN.PropertyAddress, TEMP.PropertyAddress)
FROM Nashville_Housing..NashvilleHousing MAIN
JOIN Nashville_Housing..NashvilleHousing TEMP
	ON MAIN.ParcelID = TEMP.ParcelID
	AND MAIN.[UniqueID ] <> TEMP.[UniqueID ]
WHERE MAIN.PropertyAddress IS NULL

-- Check

SELECT *
FROM Nashville_Housing..NashvilleHousing
WHERE ParcelID IS NULL

-- Breaking Address Field into three columns of Address, City and State

SELECT PropertyAddress
FROM Nashville_Housing..NashvilleHousing

-- Selecting Address, City from PropertyAddress Field (Delimiter - ',')

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
FROM Nashville_Housing..NashvilleHousing

-- Updating Table with entries LocalAddress and City

ALTER TABLE Nashville_Housing..NashvilleHousing
ADD AddressLocal Nvarchar(255)

UPDATE Nashville_Housing..NashvilleHousing
SET AddressLocal = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE Nashville_Housing..NashvilleHousing
ADD City Nvarchar(255)

UPDATE Nashville_Housing..NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM Nashville_Housing..NashvilleHousing

-- Correcting OwnerAddress Field

SELECT OwnerAddress
FROM Nashville_Housing..NashvilleHousing

-- Splitting Owner Address Field into Local Address of Owner, City and State Fields

/* Replace replaces the ',' with the '.' in all such occurances in the column OwnerAddress
PARSENAME returns the string and delimits and the '.'. Also PARSENAME reads from backwards so the 
second argument is the order of the word being split off
*/

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Nashville_Housing..NashvilleHousing

-- Updating Table with entries LocalAddressOwner and CityOwner and StateOwner

ALTER TABLE Nashville_Housing..NashvilleHousing
ADD AddressLocalOwner Nvarchar(255)

UPDATE Nashville_Housing..NashvilleHousing
SET AddressLocalOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE Nashville_Housing..NashvilleHousing
ADD CityOwner Nvarchar(255)

UPDATE Nashville_Housing..NashvilleHousing
SET CityOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE Nashville_Housing..NashvilleHousing
ADD StateOwner Nvarchar(255)

UPDATE Nashville_Housing..NashvilleHousing
SET StateOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- View of Updated Table
SELECT *
FROM Nashville_Housing..NashvilleHousing

-- Data Consistency Check in the SoldAsVacant Field

-- SoldAsVacant Field Entries Summary
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville_Housing..NashvilleHousing
GROUP BY SoldAsVacant

-- Changing to Standard Consistency 'Y' and 'N' to Yes and No as they are the popular entries

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM Nashville_Housing..NashvilleHousing

UPDATE Nashville_Housing..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

-- Check
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville_Housing..NashvilleHousing
GROUP BY SoldAsVacant;

-- Remove Duplicate Entries

/* Creating New Column that denotes if an data entry is comign for the first time or not.
The Criteria for the split is mentioned in the PARTITION OVER Command
*/

-- Create CTE for selecting out the duplicate Entries
WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,	
				 LegalReference
				ORDER BY UniqueID ) AS "Row Number"					
FROM Nashville_Housing..NashvilleHousing

)

-- Display the Duplicate Entries
SELECT *
FROM RowNumCTE
WHERE "Row Number" >1

-- Display Duplicate Entries Along WITH Original Entries

WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,	
				 LegalReference
				ORDER BY UniqueID ) AS "Row Number"					
FROM Nashville_Housing..NashvilleHousing

)

SELECT MAIN.ParcelID, MAIN.PropertyAddress, MAIN.SalePrice, MAIN.LegalReference, TEMP.ParcelID, TEMP.PropertyAddress,
TEMP.SalePrice, TEMP.LegalReference
FROM RowNumCTE MAIN
JOIN RowNumCTE TEMP
	ON MAIN.ParcelID = TEMP.ParcelID
	AND MAIN."Row Number" <> TEMP."Row Number"


-- Deleting the Duplicate Entries

WITH RowNumCTE AS
(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY LegalReference
				ORDER BY UniqueID ) AS "Row Number"					
FROM Nashville_Housing..NashvilleHousing

)
DELETE
FROM RowNumCTE
WHERE row_num >1