SELECT *
FROM PortfolioProject.dbo.Housing;

-- Standardize SaleDate
-- SELECT SaleDate, CONVERT(Date, SaleDate)
-- FROM PortfolioProject.dbo.Housing;

ALTER TABLE PortfolioProject.dbo.Housing
ADD SaleDateConverted Date;

UPDATE PortfolioProject.dbo.Housing
SET SaleDateConverted = CONVERT(Date, SaleDate);

SELECT SaleDateConverted
from PortfolioProject.dbo.Housing;

-----------------------------------
-- Populate Property Address Data
SELECT *
FROM PortfolioProject.dbo.Housing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID;


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Housing a
JOIN PortfolioProject.dbo.Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Testing to see if it succesfully worked for all of the PropertyAdresses
SELECT *
FROM PortfolioProject.dbo.Housing
WHERE PropertyAddress IS NULL;


----------------------------------
-- Separating Address Info into individual columns (Address, City, State)
-- SELECT PropertyAddress
-- FROM PortfolioProject.dbo.Housing;
SELECT 
	SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.Housing;

ALTER TABLE PortfolioProject.dbo.Housing
ADD PropertySplitAddress VARCHAR(255),
	PropertySplitCity VARCHAR(255);

UPDATE PortfolioProject.dbo.Housing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));

-- Test to make sure everything worked out
SELECT PropertySplitAddress, PropertySplitCity, PropertyAddress
FROM PortfolioProject.dbo.Housing;

---------------------------------------
-- OwnerAddress
SELECT OwnerAddress
FROM PortfolioProject.dbo.Housing;

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.Housing;

-- Address
ALTER TABLE PortfolioProject.dbo.Housing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSpliCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(10);

UPDATE PortfolioProject.dbo.Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Make sure everything looks okay
SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject.dbo.Housing;

-----------------------------------------------
-- Change Y and N to Yes and No in column "SoldAsVacant"
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject.dbo.Housing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM PortfolioProject.dbo.Housing;

UPDATE PortfolioProject.dbo.Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END;

------------------------------------------------
-- Remove Duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID, 
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY UniqueID
					) row_num
FROM PortfolioProject.dbo.Housing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1;

------------------------------------------------
-- Delete unused columns
ALTER TABLE PortfolioProject.dbo.Housing 
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict;

ALTER TABLE PortfolioProject.dbo.Housing
DROP COLUMN SaleDate;
