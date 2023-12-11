-- look the datas that we have
select *
from NashvilleHousing


-- standardize date format
select SaleDate, convert (date, SaleDate) as SaleDateConverted
from NashvilleHousing

update NashvilleHousing
set SaleDate = convert (date, SaleDate)

--- or using this query 

alter table NashvilleHousing
add SaleDateConverted Date;

update NashvilleHousing
set SaleDateConverted = CONVERT (Date, SaleDate)

select *
from NashvilleHousing


-- Populate PropertyAddress data
select *
from NashvilleHousing
order by ParcelID

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from NashvilleHousing a
Join NashvilleHousing b
	On a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress = ISNULL (a.PropertyAddress, b.PropertyAddress)
From NashvilleHousing a
join NashvilleHousing b
	On a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

select *
from NashvilleHousing
where PropertyAddress is Null


-- Breaking out PropertyAddress into individual column (Address, City)
select PropertyAddress
from NashvilleHousing

select 
SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1) as Address
, SUBSTRING (PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN(PropertyAddress)) as City
from NashvilleHousing

alter table NashvilleHousing
add PropertySplitAddress Nvarchar(255);

update NashvilleHousing
set PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1)

alter table NashvilleHousing
add PropertySplitCity Nvarchar(255);

update NashvilleHousing
set PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN(PropertyAddress))

select *
from NashvilleHousing


-- Breaking out OwnerAddress into individual column (Address, City, State
select 
PARSENAME (replace (OwnerAddress, ',', '.'),3) as OwnerSplitAddress
, PARSENAME (replace (OwnerAddress, ',', '.'),2) as OwnerSplitCity
, PARSENAME (replace (OwnerAddress, ',', '.'),1) as OwnerSplitState
from NashvilleHousing

alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255);

update NashvilleHousing
set OwnerSplitAddress = PARSENAME (replace (OwnerAddress, ',', '.'),3)

alter table NashvilleHousing
add OwnerSplitCity nvarchar(255);

update NashvilleHousing
set OwnerSplitCity = PARSENAME (replace (OwnerAddress, ',', '.'),2)

alter table NashvilleHousing
add OwnerSplitState nvarchar(255);

update NashvilleHousing
set OwnerSplitState = PARSENAME (replace (OwnerAddress, ',', '.'),1)

select *
from NashvilleHousing


-- Change Y and N to Yes and No in SoldAsVacant column
select Distinct (SoldAsVacant), count(SoldAsVacant)
from NashvilleHousing
Group by SoldAsVacant

select SoldAsVacant,
CASE 
	when SoldAsVacant = 'N' then 'No'
	when SoldAsVacant = 'Y' then 'Yes'
	ELSE SoldAsVacant
end
from NashvilleHousing

update NashvilleHousing
set SoldAsVacant = CASE 
	when SoldAsVacant = 'N' then 'No'
	when SoldAsVacant = 'Y' then 'Yes'
	ELSE SoldAsVacant
end

select *
from NashvilleHousing


-- Remove duplicates
select *, Row_Number () Over (Partition by ParcelID,
											PropertyAddress,
											SaleDate,
											SalePrice,
											LegalReference
											order by
											UniqueID) 
											as row_num
From NashvilleHousing
order by ParcelID


--- using CTE
with RowNumCTE as
(
select *, Row_Number () Over (Partition by ParcelID,
											PropertyAddress,
											SaleDate,
											SalePrice,
											LegalReference
											order by
											UniqueID) 
											as row_num
From NashvilleHousing
)
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress

--- delete
with RowNumCTE as
(
select *, Row_Number () Over (Partition by ParcelID,
											PropertyAddress,
											SaleDate,
											SalePrice,
											LegalReference
											order by
											UniqueID) 
											as row_num
From NashvilleHousing
)
delete
from RowNumCTE
where row_num > 1

select *
from NashvilleHousing


-- Delete unused columns
Alter Table NashvilleHousing
Drop column PropertyAddress, SaleDate, OwnerAddress

select *
from NashvilleHousing
