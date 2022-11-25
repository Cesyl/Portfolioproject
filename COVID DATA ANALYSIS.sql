---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*DATA SOURCE - https://ourworldindata.org/covid-deaths
	DATA TIMELINE - 24TH FEBRUARY 2022 TO 25TH OCTOBER 2022
	DATE OF DATA DOWNLOAD - 26TH OCTOBER 2022 10:32 AM 
*/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*AT THE END OF THIS QUERIES, THE FOLLOWING RESULTS HAVE BEEN ACHIEVED:
	1. THE TOTAL CASES OF INFECTION IN THE ENTIRE POULATION, GROUPED BY LOCATION AND CONTINENT.
	2. THE INFECTED PERCENTAGE OF THE POPULATION, GROUPED BY DATE.
	3. THE NUMBER OF CASES THAT HAVE LED TO DEATHS IN THE CONTINENTS.
	4. THE HIGHEST DEATH COUNT IN POPULATION, GROUPED BY LOCATION AND CONTINENT.
	5. THE LOCATION WITH NO DEATH FROM THE VIRUS.
	6. THE DEATH PERCENTAGE GLOBALLY.
	7. THE CONTINOUS VACCINATIONS ADMINISTERED, SUMMED BY LOCATIONS.
*/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM [dbo].[death]
ORDER BY  [date], [location]

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- COVID DEATHS AND VACCINATIONS DATA -----------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

                                                     --------------------------------------------
                                                     ----------------------- PART A (LOCATION) ||
                                                     --------------------------------------------

-- APPLICABLE DATA
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM death

-- INFECTIONS
--------------

-- Total cases in the entire population grouped by Location
SELECT location, SUM(total_cases) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY Total_cases 

--  Sum of total cases in the entire population by location
SELECT	location, 
		SUM(COALESCE(total_cases,0)) AS Total_cases, 
		SUM(population) AS population 
FROM death
WHERE continent is NOT NULL
GROUP BY location
ORDER BY total_cases

-- Infected percentage_portion (Total cases) of the population grouped by date
SELECT CONVERT (date, date) AS date, location, COALESCE(total_cases,0)AS Total_cases, population, (COALESCE(total_cases,0)/population)*100 AS Infected_percentage
FROM death
WHERE continent is NOT NULL
ORDER BY date


-- DEATHS
----------

-- Number of cases that have led to deaths
SELECT CONVERT (date, date) AS date, location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_percentage
FROM death
WHERE continent is NOT NULL
ORDER BY date

-- Highest death count in population, grouped by location
SELECT location, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY location
ORDER BY Total_deaths DESC

-- NO INFECTIONS OR DEATHS
---------------------------

-- Locations in the world with no cases in the entire population
SELECT location, SUM(total_cases) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY location, population
HAVING SUM(total_cases) IS NULL
ORDER BY population

-- Death count in population, grouped by location
SELECT location, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY location
HAVING SUM (ISNULL (CAST(total_deaths AS INT),0)) = 0
ORDER BY Total_deaths

                                                     ---------------------------------------------
                                                     ----------------------- PART B (CONTINENT) ||
                                                     ---------------------------------------------


-- APPLICABLE DATA
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM death


--  INFECTIONS
--------------

-- Total cases in the entire population grouped by Continent
SELECT Continent, SUM(total_cases) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY Continent, population
ORDER BY Total_cases 


--  Sum of total cases in the entire population by Continent
SELECT	Continent, 
		SUM(COALESCE(total_cases,0)) AS Total_cases, 
		SUM(population) AS population 
FROM death
WHERE continent is NOT NULL
GROUP BY Continent
ORDER BY total_cases


-- Infected percentage_portion (Total cases) of the Continent population grouped by date
SELECT CONVERT (date, date) AS date, Continent, COALESCE(total_cases,0)AS Total_cases, population, (COALESCE(total_cases,0)/population)*100 AS Infected_percentage
FROM death
WHERE continent is NOT NULL
ORDER BY date

-- DEATHS
---------

-- Number of cases that have led to deaths
SELECT CONVERT (date, date) AS date, continent, COALESCE(total_cases,0), COALESCE(total_deaths,0),  (total_deaths/total_cases)*100 AS Death_percentage
FROM death
WHERE continent is NOT NULL
ORDER BY date

-- Highest death count in population, grouped by location
SELECT continent, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY Total_deaths DESC

-- NO INFECTIONS OR DEATHS
--------------------------

-- Locations in the world with no cases in the entire population
SELECT continent, SUM(COALESCE(total_cases,0)) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY continent, population
HAVING SUM(total_cases) IS NULL
ORDER BY population

-- Death count in population, grouped by location
SELECT continent, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY continent
HAVING SUM (ISNULL (CAST(total_deaths AS INT),0)) = 0
ORDER BY Total_deaths


													 ------------------------------------------
                                                     ----------------------- PART C (GLOBAL) ||
                                                     ------------------------------------------

-- APPLICABLE DATA
SELECT date, total_cases, new_cases, total_deaths, population
FROM death

-- Death Percentage Globally
SELECT	CONVERT(date,date) AS date, 
		SUM(COALESCE(new_cases,0)) AS new_global_cases, 
		SUM(CAST(COALESCE(new_deaths,0) AS INT)) AS new_global_deaths,
		(SUM(new_cases))/SUM(CAST(new_deaths AS INT))AS Death_percentage
FROM death
WHERE continent is NOT NULL
GROUP BY date
ORDER BY date

-- Total Death Percentage Globally
SELECT	SUM(COALESCE(new_cases,0)) AS new_global_cases, 
		SUM(CAST(COALESCE(new_deaths,0) AS INT)) AS new_global_deaths,
		(SUM(new_cases))/SUM(CAST(new_deaths AS INT))AS Death_percentage
FROM death
WHERE continent is NOT NULL

/*-- Total Death Percentage Globally
SELECT	SUM(COALESCE(new_cases,0)) AS new_global_cases, 
		SUM(CAST(COALESCE(new_deaths,0) AS INT)) AS new_global_deaths,
		(SUM(new_cases))/SUM(CAST(new_deaths AS INT))AS Death_percentage,
		(SUM(CAST(new_deaths AS INT))/(SUM(new_cases))) *100 AS Death_percentage
FROM death
WHERE continent is NOT NULL*/


-- Calculating Rolling Vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
		SUM (CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_vaccinations
FROM death d JOIN vaccine v 
ON d.date = v.date AND d.location = v.location
WHERE d.continent is NOT NULL 
ORDER BY 2,3

-- USING COMMON TABLE EXPRESSION (CTE)
WITH vaccinated_population (Continent, Location, Date, Population, New_vaccinations, Rolling_vaccinations )
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
		SUM (CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_vaccinations
FROM death d JOIN vaccine v 
ON d.date = v.date AND d.location = v.location
WHERE d.continent is NOT NULL 
)
SELECT *, (Rolling_vaccinations/Population)*100 AS Overall_vaccinations 
FROM vaccinated_population

													 --------------------------------------------
                                                     -- CREATING VIEWS TO DOCUMENT DATA ABOVE ---
                                                     --------------------------------------------


-- Vaccinated Population
CREATE VIEW vaccinated_population AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
		SUM (CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_vaccinations
FROM death d JOIN vaccine v 
ON d.date = v.date AND d.location = v.location
WHERE d.continent is NOT NULL 

-- Total cases in the entire population grouped by Location
CREATE VIEW cases_in_population AS
SELECT location, SUM(total_cases) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY location, population

--  Sum of total cases in the entire population by location
CREATE VIEW summed_cases_in_population AS
SELECT	location, 
		SUM(COALESCE(total_cases,0)) AS Total_cases, 
		SUM(population) AS population 
FROM death
WHERE continent is NOT NULL
GROUP BY location

-- Infected percentage_portion (Total cases) of the population grouped by date
CREATE VIEW infected_population AS
SELECT CONVERT (date, date) AS date, location, COALESCE(total_cases,0)AS Total_cases, population, (COALESCE(total_cases,0)/population)*100 AS Infected_percentage
FROM death
WHERE continent is NOT NULL

-- Number of cases that have led to deaths
CREATE VIEW deaths AS
SELECT CONVERT (date, date) AS date, location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_percentage
FROM death
WHERE continent is NOT NULL

-- Highest death count in population, grouped by location
CREATE VIEW death_count AS
SELECT location, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY location

-- Locations in the world with no cases in the entire population
CREATE VIEW no_cases AS
SELECT location, SUM(total_cases) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY location, population
HAVING SUM(total_cases) IS NULL

-- Death count in population, grouped by location
CREATE VIEW no_deaths AS
SELECT location, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY location
HAVING SUM (ISNULL (CAST(total_deaths AS INT),0)) = 0

-- Total cases in the entire population grouped by Continent
CREATE VIEW continental_cases AS
SELECT Continent, SUM(total_cases) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY Continent, population

--  Sum of total cases in the entire population by Continent
CREATE VIEW continental_summed_cases AS
SELECT	Continent, 
		SUM(COALESCE(total_cases,0)) AS Total_cases, 
		SUM(population) AS population 
FROM death
WHERE continent is NOT NULL
GROUP BY Continent

-- Infected percentage_portion (Total cases) of the Continent population grouped by date
CREATE VIEW continental_infected_population AS
SELECT CONVERT (date, date) AS date, Continent, COALESCE(total_cases,0)AS Total_cases, population, (COALESCE(total_cases,0)/population)*100 AS Infected_percentage
FROM death
WHERE continent is NOT NULL

-- Number of cases that have led to deaths
CREATE VIEW continental_deaths AS
SELECT CONVERT (date, date) AS date, continent, COALESCE(total_cases,0) AS total_cases, COALESCE(total_deaths,0) AS total_deaths,  (total_deaths/total_cases)*100 AS Death_percentage
FROM death
WHERE continent is NOT NULL

-- Highest death count in population, grouped by location
CREATE VIEW continental_death_count AS
SELECT continent, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY continent

-- Locations in the world with no cases in the entire population
CREATE VIEW continental_no_cases AS
SELECT continent, SUM(COALESCE(total_cases,0)) AS Total_cases, population
FROM death
WHERE continent is NOT NULL
GROUP BY continent, population
HAVING SUM(total_cases) IS NULL

-- Death count in population, grouped by location
CREATE VIEW continental_no_deaths AS
SELECT continent, SUM (ISNULL (CAST(total_deaths AS INT),0)) AS Total_deaths
FROM death
WHERE continent is NOT NULL
GROUP BY continent
HAVING SUM (ISNULL (CAST(total_deaths AS INT),0)) = 0

-- Death Percentage Globally
CREATE VIEW global_death AS
SELECT	CONVERT(date,date) AS date, 
		SUM(COALESCE(new_cases,0)) AS new_global_cases, 
		SUM(CAST(COALESCE(new_deaths,0) AS INT)) AS new_global_deaths,
		(SUM(new_cases))/SUM(CAST(new_deaths AS INT))AS Death_percentage
FROM death
WHERE continent is NOT NULL
GROUP BY date

