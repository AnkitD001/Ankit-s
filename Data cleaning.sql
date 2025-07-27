-- Data Cleaning--
DROP DATABASE world_layoffs;
-- now import the database and the tables world_layoffs from your device--
select *
from layoffs;
-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Take a look at null values/blank values
-- 4. Remove unncecessary columns and rows--

create table layoffs_staging
like layoffs;

-- Data insertion in layoffs_staging from layoffs--
insert layoffs_staging
select *
from layoffs;

select *
from layoffs_staging;

-- We are checking presence of any duplicate in the data of layoffs_staging combining the value in the columns (company,industry, total_laid_off,percentage_laid_off ,`date`)--
-- If the value in row_num is > 1 , then there is duplicates--
-- The code below partitions the table by company,industry, total_laid_off,percentage_laid_off ,`date`). It then takes each unique combination of company,industry, total_laid_off,percentage_laid_off ,`date` and gives it a row_number mark --
select *,
row_number() over(
partition by company, industry, total_laid_off , percentage_laid_off , `date`) AS row_num 
from layoffs_staging ;

-- The code below partitions the table by company,industry. It then takes each unique combination of company,industry and gives it a row_number mark --
-- If any company-industry combination is there in the table more than once it will get row_num mark 2,3, etc... as many marks are there --
-- if it is 3 , it means there are three company-industry combination like 'Desktop Metal-other' which is present thrice in the table--
select *,
row_number() over(
partition by company, industry) AS row_num 
from layoffs_staging ;

-- The code snippet below is finding out duplicates --
with duplicate_cte as
(
select *,
row_number() over(
partition by company, industry, total_laid_off , percentage_laid_off , `date`) AS row_num 
from layoffs_staging
)
select *
from duplicate_cte
where row_num >1 ;

select * 
from layoffs_staging
where company = 'Oda';

-- Oda came as duplicates even though it's different records/rows are not exactly same when we look into the value of columns 'percentage_laid_off' and 'funds_raised_millions'.--
-- It is because we created the duplicate_cte by partitioning with (company, industry, total_laid_off , percentage_laid_off , `date`) and we did not include location,stage,country,funds_raised_millions--
-- So to find out proper duplicates(i.e. duplicate w.r.t value in each of the 10 columns) we include all columns in the table--

with duplicate_cte as
(
select *,
row_number() over(
partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num 
from layoffs_staging
)
select *
from duplicate_cte
where row_num >1 ;

select *
from layoffs_staging
where company = 'Casper';

-- The companies which come as output from line 56 to 65 are the only ones with row_num > 1 and are the duplicates. --
-- Exact same item with exactly same "company,location,industry,total_laid_off,percentage _laid_off,date,stage,country,funds_raised_millions" are present in the table and the second such row has been assigned row_num as 2--

-- We need to delete the rows with row_num > 1. Deleting is easier in microsoft sql server, where we can delete data by simply mentioning the "delete from duplicate_cte where row_num > 1"--
-- The above is not possible in MySQL--
-- We are going to create a table layoffs_staging2 which is exact replica of layoffs_staging and we will delete from it the columns with row_num = 2--
-- below is a copied create statement which is created by right clicking on the layoffs_staging table and then clicking on copy_to_clipboard and clicking on create statement--

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT    -- column added by us--
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *
from layoffs_staging2;  -- This is an empty table and we are going to insert data into it from layoffs_staging--

-- Data insertion into layoffs_staging2 from  layoffs_staging--
Insert into layoffs_staging2
select *,
row_number() over(
partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num 
from layoffs_staging;

-- the o/p of the code below are the duplicates-- 
select *
from layoffs_staging2 where row_num > 1;

-- deleting from layoffs_staging2 where row_num >1--
delete 
from layoffs_staging2 where row_num > 1;

-- all rows with row_num > 1 is deleted --
select *
from layoffs_staging2;

-- so that is how we deleted data from layoffs_staging2 where row_num > 1. If it were microsoft sql server we could have done it directy from the CTE statement using delete--

-- Standardizing Data--
-- finding issues in your data and fixing it--

-- 1. Trimming off spaces in company names --
select company,TRIM(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

select company,TRIM(company)
from layoffs_staging2;

select distinct industry
from layoffs_staging2
order by 1;

-- in the industry there are different industries like crypto, Crypto Currency, CryptoCurrency. All these 3 types of industries are practically same and will create problem during EDA if we don't standardize these 3--
-- Below we find out all which have Crypto in their industy name--
select *
from layoffs_staging2
where industry like 'Crypto%';

-- We will standardize all to Crypto industry--
update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

select distinct industry
from layoffs_staging2
order by 1;

select *
from layoffs_staging2;

select distinct country
from layoffs_staging2
order by 1;
-- after running the above code from 152 to 154 we saw United States is present twice. Once with '.' in the end and once without it --

select distinct country , TRIM(Trailing '.' from country)
from layoffs_staging2
order by 1;
-- By running the above code from 157 to 159, we are demonstrating we can trim the trailing '.' from United States --

update layoffs_staging2
set country = TRIM(trailing '.' from country)
where country like 'United States%';
-- By running the above code from 162 to 164, we are updating the country column for United states and getting rid of the trailing '.' where country is United states--
-- Now when we run the below code and select distinct country United states will come once only without '.' at end --

select distinct country 
from layoffs_staging2
order by 1;

-- In our table, date column is in 'text' format. Later when we do visualization we would need the date column in 'date' format. We will make that change now--

select `date`,
str_to_date(`date`,'%m/%d/%Y')
from layoffs_staging2;
-- The code above from 174 to 176 shows how the date column will look like if we convert the current date format which is actually in text like '%m/%d/%Y' to a proper date format--
-- the current date is case sensitive and %m/%d/%Y is how it should be written--
-- we do the update below--
update layoffs_staging2
SET `date` = str_to_date(`date`,'%m/%d/%Y');

select `date`
from layoffs_staging2;

-- If we tried the below code where we convert date column which is in text type to a date column which will be in our desired date format before doing the 'str_to_date' conversion it would have given us error--

Alter table layoffs_staging2
modify column `date` DATE;

-- we run the below query from 192 to 195 to check where total_laid_off and percentage_laid_off are both null. We might discard these rows and we will take a look at these later--
select *
from layoffs_staging2
where total_laid_off is null
AND percentage_laid_off is null;

-- in the code below from 198 to 201 we are checking where industry is null or industry in ''--
select * 
from layoffs_staging2
where industry is null
or industry = '';

-- for the output of the code above from 198 to 201, where industry is Null or ' ' we will chcek if there is any other rows of the same company and location with the industry  not Null or not ''--
-- If there is same company and same location with industry Not null or Not ' ' , we will update the industry column with the value of the industry of such non-empty rows--
-- Let's check the example of 'Airbnb'--

select *
from layoffs_staging2
where company like 'Airbnb';

-- As you can see from the output of the above code for Airbnb, in one row industry is present as Travel. In the other rpw also the industry should be Travel.--
-- The reason we want to do this is becuase if we are going to find out how much is Travel industry is affected by layoffs, we want both the rows to appear--

select *
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
    AND t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

-- The above query from 214 to 220 finds out for which companies and location we have a blank cell in industry and another row which is  non blank for industry--
-- Below we are checking specifically the industry columns side by side --

select t1.industry,t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
    AND t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

-- Now we will update the blank industry cells to null and then with industry cell values from non-empty rows where company and location is same--

update layoffs_staging2
set industry = null
where industry = '';

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

-- Run the below query and you will see the industry is updated for both Airbnb rows. The same is true for the other two companies as well--
select *
from layoffs_staging2
where company like 'Airbnb';

select *
from layoffs_staging2
where industry is null or industry = '';
-- from the query above from 251 to 253 we can see Bally's Interactive is the only company where industry is Null. Since it does not have any other instance with same company and location  with industry not null, it is left as it is--
-- But we have solved for companies where industry is null for one instance , but is present for another instance--

select *
from layoffs_staging2;

-- Data cleaning is complete for null values since we can't fill anything in funds_raised_millions , total_laid_off , percentage_laid_off with the available data since we don't know total number of employees anywhere--

-- we will be deleting every row which has both total_laid_off and percentage_laid_off as null--

select *
from layoffs_staging2
where total_laid_off IS null
AND percentage_laid_off IS NULL;


Delete
from layoffs_staging2
where total_laid_off IS null
AND percentage_laid_off IS NULL;

-- We don't need the row_num column anymore, so let's drop it--

Alter table layoffs_staging2
drop column row_num;

select *
from layoffs_staging2;

-- Exploratory Data Analysis --
-- Checking the layoff data from different perspectives(industry,company,country)--

select *
from layoffs_staging2;

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

select *
from layoffs_staging2
where percentage_laid_off = 1 
order by total_laid_off desc;

select *
from layoffs_staging2
where percentage_laid_off = 1 
order by funds_raised_millions desc;

select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by sum(total_laid_off) desc;

select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by sum(total_laid_off) desc;

select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by sum(total_laid_off) desc;


select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by company desc;

select `date`, sum(total_laid_off)
from layoffs_staging2
group by `date`
order by `date` desc;

select Year(`date`), sum(total_laid_off)
from layoffs_staging2
group by Year(`date`)
order by Year(`date`) desc;

select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

select *
from layoffs_staging2;

select distinct substring(`date`,6,2) as month
from layoffs_staging2
order by 1 desc;

-- sql does not allow using select clause alias in where clause--
select sum(total_laid_off) , substring(`date`,6,2) as `month`
from layoffs_staging2
where substring(`date`,6,2) is not null
group by month
order by 2 asc;


select sum(total_laid_off) , substring(`date`,1,7) as `year-month`
from layoffs_staging2
where substring(`date`,1,7) is not null
group by `year-month`
order by 2 asc;

-- we are finding sum of total laid off on a year-month basis. Then we are arranging the results in ascending order of year-month--
with Rolling_total_year_monthwise as 
(
select sum(total_laid_off) as total_off , substring(`date`,1,7) as `year-month`
from layoffs_staging2
where substring(`date`,1,7) is not null
group by `year-month`
order by 2 asc
)
select `year-month`, sum(total_off) over (order by `year-month`) as rolling_total , total_off
from Rolling_total_year_monthwise;


with Rolling_total_yearwise as 
(
select sum(total_laid_off) as total_off , substring(`date`,1,4) as `year`
from layoffs_staging2
where substring(`date`,1,4) is not null
group by `year`
order by 2 asc
)
select `year`, sum(total_off) over (order by `year`) as rolling_total_yearwise , total_off
from Rolling_total_yearwise;




select company, substring(`date`,1,4) as `year`, sum(total_laid_off)
from layoffs_staging2
group by company, `year`
order by company asc;


select * 
from layoffs_staging2
where company like 'Amount';

-- since we are using a clause like sum(total_laid_off) is not null, which is an aggregate function, we have to use having clause and not where clause. Since where is used on non-aggregated columns -- 
select company, substring(`date`,1,4) as `year`, sum(total_laid_off)
from layoffs_staging2
group by company, `year`
having sum(total_laid_off) is not null
order by 1 desc;

with Company_year(company, years, total_laid_off) as
(
	select company, year(`date`), sum(total_laid_off)
	from layoffs_staging2
	group by company, year(`date`)
)
select *, dense_rank() over (partition by years order by total_laid_off desc)
from Company_year
where years is not null
and total_laid_off is not null;


with Company_year(company, years, total_laid_off) as
(
	select company, year(`date`), sum(total_laid_off)
	from layoffs_staging2
	group by company, year(`date`)
)
select *, dense_rank() over (partition by years order by total_laid_off desc) as ranking
from Company_year
where years is not null
and total_laid_off is not null
order by years asc;

with Company_year(company, years, total_laid_off) as
(
	select company, year(`date`), sum(total_laid_off)
	from layoffs_staging2
	group by company, year(`date`)
)
select *, dense_rank() over (partition by years order by total_laid_off desc) as ranking
from Company_year
where years is not null
and total_laid_off is not null
order by ranking asc;

with Company_year(company, years, total_laid_off) as
(
	select company, year(`date`), sum(total_laid_off)
	from layoffs_staging2
	group by company, year(`date`)
),
company_year_rank as
(
select *, dense_rank() over (partition by years order by total_laid_off desc) as ranking
from Company_year
where years is not null
and total_laid_off is not null
)
select *
from company_year_rank
where ranking <=5;















