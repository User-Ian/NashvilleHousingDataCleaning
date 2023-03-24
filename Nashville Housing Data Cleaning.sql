-- start by importing the data using the Table Import Wizard
-- rename the UniqueID column name
-- view the table structure and records available
select * from nashdata;

-- no records available. Faulty MySQL Workbench table import wizard. Import data using load data infile
load data 
	local 
	infile 'F:/Data Analysis/Nashville Housing Data Analysis/Nashville Housing Data for Data Cleaning.csv'
	INTO TABLE nashdata
    fields terminated by ','
    enclosed by '"'
    lines terminated by '\n'
    ignore 1 rows
;

-- error when trying to import data via load data infile
show global VARIABLES like 'local_infile';
set global local_infile = true;
 
-- change date format to remove irrelevant "hh:mm:ss"
SELECT SaleDate -- , convert(SaleDate, date)
from nashdata
;

alter table nashdata
add saledateconv date
;

UPDATE nashdata
SET saledate = CONVERT(saledate, date)
;

alter table nashdata
drop column saledate
;

alter table nashdata
rename column saledateconv to SaleDate
;

SELECT * from nashdata;

-- populate property address data
SELECT *
from nashdata
order by parcelid
-- where PropertyAddress = ''
;

select nash1.parcelid, nash1.PropertyAddress, nash2.parcelid, nash2.PropertyAddress
from nashdata nash1
join nashdata nash2
on nash1.ParcelID = nash2.ParcelID 
where nash1.PropertyAddress = '' and nash2.PropertyAddress <> ''
;

select * 
from nashdata 
where propertyaddress = '';

	-- create a temporary table to hold the parcelid and propertyaddress of the properties with similar parcelid as those with missing propertyaddress
drop table if exists tempt;
create temporary table tempt
as 
select nash2.parcelid, nash2.PropertyAddress
			from nashdata nash1
			join nashdata nash2
			on nash1.ParcelID = nash2.ParcelID 
			where nash1.PropertyAddress = '' and nash2.PropertyAddress <> '';

select * from tempt;

update nashdata
set propertyaddress = (
	SELECT propertyaddress
    from tempt
    where nashdata.ParcelID=tempt.propertyaddress)
where propertyaddress = '';

-- splitting the propertyaddress and owneraddress into individual columns i.e., Address, City, State
SELECT * from nashdata;

select
		parcelid,
		left(propertyaddress, locate(',',propertyaddress)-1) as address,
		right(propertyaddress, (length(propertyaddress)-locate(',',propertyaddress))) as town
		from nashdata
;

	-- create columns for the new data
alter table nashdata
add column (
address varchar(255),
town varchar(255));

	-- split the propertyaddress
update nashdata 
	set address = left(propertyaddress,locate(',',propertyaddress)-1), 
    town = right(propertyaddress,(length(propertyaddress)-locate(',',propertyaddress)))
;

	-- delete the propertyaddress column now that we have a cleaner separated address
alter table nashdata
drop PropertyAddress;

	-- change the case of the two new columns for consistency
alter table nashdata
rename column address to Address,
rename column town to Town;

-- split owneraddress into individual columns i.e., ResidentAddress, ResidentTown, ResidentState
	-- create the new columns
select * from nashdata;

alter table nashdata
	add column (
	ResidentAddress VARCHAR(255),
	ResidentTown VARCHAR(255),
	ResidentState VARCHAR(255)
	)
;

	-- return the split columns
SELECT 
    SUBSTRING_INDEX(owneraddress, ',', 1) AS ResidentAddress,
    SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2),
            ',',
            - 1) AS ResidentTown,
    SUBSTRING_INDEX(owneraddress, ',', - 1) AS ResidentState
FROM
    nashdata
;

	-- insert the split data into the respective columns
UPDATE nashdata 
SET 
    ResidentAddress = SUBSTRING_INDEX(owneraddress, ',', 1),
    ResidentTown = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2),',',-1),
    ResidentState = SUBSTRING_INDEX(owneraddress, ',', - 1)
;

	-- delete the redundant owneraddress column
alter table nashdata
drop column owneraddress;

-- change y to yes and n to no in the soldasvacant column
select distinct SoldAsVacant, count(SoldAsVacant)
	from nashdata
    group by SoldAsVacant
;
	-- changing one at a time
update nashdata
	set soldasvacant = 'Yes'
    where soldasvacant = 'Y'
;

	-- change multiple at once
update nashdata
	set soldasvacant = 
    case 
		when soldasvacant = 'Y' then 'Yes'
        when soldasvacant = 'N' then 'No'
        else soldasvacant
	end
;

-- remove duplicates
select uniqueid, count(UniqueID) as countid
	from nashdata
    group by uniqueid
    order by countid desc
;

	-- no duplicates

--  replace all the blanks with null
select * from nashdata;

update nashdata
	set	parcelid = CASE when parcelid = '' then null else parcelid end,
		landuse = CASE when landuse = '' then null else landuse end,
        address = CASE when address = '' then null else address end,
        town = CASE when town = '' then null else town end,
       -- saledate = CASE when saledate = '' then null else saledate end,
        saleprice = CASE when saleprice = '' then null else saleprice end,
        legalreference = CASE when legalreference = '' then null else legalreference end,
        soldasvacant = CASE when soldasvacant = '' then null else soldasvacant end,
        ownername = CASE when ownername = '' then null else ownername end,
        residentaddress = CASE when residentaddress = '' then null else residentaddress end,
        residenttown = CASE when residenttown = '' then null else residenttown end,
        residentstate = CASE when residentstate = '' then null else residentstate end,
        acreage = CASE when acreage = '' then null else acreage end,
        taxdistrict = CASE when taxdistrict = '' then null else taxdistrict end,
        landvalue = CASE when landvalue = '' then null else landvalue end,
        buildingvalue = CASE when buildingvalue = '' then null else buildingvalue end,
        totalvalue = CASE when totalvalue = '' then null else totalvalue end,
        yearbuilt = CASE when yearbuilt = '' then null else yearbuilt end,
        bedrooms = CASE when bedrooms = '' then null else bedrooms end,
        fullbath = CASE when fullbath = '' then null else fullbath end,
        halfbath = CASE when halfbath = '' then null else halfbath end
;
		