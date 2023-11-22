/*

Cleaning Data in SQL

*/

--------------------------------------------------------------------------------------

-- Standardize Date Format

/*
We dont want to see the time of the SaleDate,
Reformat the SaleDate to be only the date
*/

Select SaleDate
From [Portfolio Project]..NashvilleHousing

Select SaleDateConverted
From [Portfolio Project]..NashvilleHousing

Alter Table NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = Convert(Date, SaleDate)
---------------------------------------------------------------------------------------------

-- Populate Propery Address Data

Select * 
From [Portfolio Project]..NashvilleHousing
--Where PropertyAddress is NULL
Order by ParcelID

/* 
The ParcelID can be used to populate the PropertyAddress
Start with a self JOIN statement where if ParcelIDs match
but UniqueIDs are different, the Property Address will be
the same for both
*/

Select 
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.propertyaddress, b.propertyaddress)
From [Portfolio Project]..NashvilleHousing a 
Join [Portfolio Project]..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

/*
Now we can create our table update 
*/

Update a
Set PropertyAddress = ISNULL(a.propertyaddress, b.propertyaddress)
From [Portfolio Project]..NashvilleHousing a 
Join [Portfolio Project]..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

--------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress
From [Portfolio Project]..NashvilleHousing

Select
SUBSTRING (PropertyAddress, 1, charindex(',', PropertyAddress)-1) as Address,
SUBSTRING (PropertyAddress, charindex(',', PropertyAddress)+1, LEN(PropertyAddress)) as Address
From [Portfolio Project]..NashvilleHousing

/*
Above: The '-1' in the charindex will remove the ',' from the 
return results since the charindex is looking for a position
*/

/*
Add two new columns and update them to include information from above SELECT statement
*/

Alter Table NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, charindex(',', PropertyAddress)-1)

Alter Table NashvilleHousing
Add PropertySplitCity Date;

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, charindex(',', PropertyAddress)+1, LEN(PropertyAddress))

Select PropertySplitaddress, PropertySplitcity
from NashvilleHousing

-- There is an easier way to perform splitting an address...

Select
PARSENAME(Replace(OwnerAddress, ',', '.'), 3),
-- ParseName will only parse at '.', so the ',' need to be converted to '.'
PARSENAME(Replace(OwnerAddress, ',', '.'), 2),
PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
From [Portfolio Project]..NashvilleHousing



Alter Table NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)

Alter Table NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)

Alter Table NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

Select * 
From [Portfolio Project]..NashvilleHousing

--------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" in field

Select Distinct(SoldAsVacant), count(SoldAsVacant)
from [Portfolio Project]..NashvilleHousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 Else SoldAsVacant
	 END
From [Portfolio Project]..NashvilleHousing
	
Update NashvilleHousing
Set SoldAsVacant = 
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 Else SoldAsVacant
	 END

--------------------------------------------------------------------------------------

-- Remove Duplicates

/* write out CTE */

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
				
From [Portfolio Project]..NashvilleHousing
)

--had to run a delete statement to remove all row_num > 1
--then switched delete statement back to Select statement
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

--------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From [Portfolio Project]..NashvilleHousing

Alter Table [Portfolio Project]..NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress

Alter Table [Portfolio Project]..NashvilleHousing
Drop Column SaleDate
