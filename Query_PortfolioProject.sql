-- To Do: Gibt teilweise mehrere Aufzeichnungen pro Tag, wobei aber die total_deaths nur 1x pro Tag da sind
-- Exclude location = International

-- Select the Data that I want to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1, 2;

-- Getting a feel for the data set
-- Which locations
SELECT DISTINCT location
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1;
-- So apparently there are some locations that are grouped, e.g. Europe, World,...

SELECT DISTINCT location, continent
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, continent
ORDER BY location;
-- The actual continents do have NULL in the continent column, so I can exclude them this way in the following queries



-- Date of first and last recording per location
SELECT location, MIN(date) AS first_recording, MAX(date) AS last_recording
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY 1;

-- Looking at total cases vs. total deaths
-- Shows the likelyhood if dying if you contract covid in a certain country
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100.00 as death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- Sum of total cases vs total deaths and death_percentage
SELECT location, SUM(total_cases) AS sum_total_cases, SUM(total_deaths) AS sum_total_deaths, ROUND((SUM(total_deaths) / SUM(total_cases))*100.00, 2) AS total_death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY 1;

-- Looking at total cases vs population
-- Shows the cases per population
SELECT location, date, population, total_cases, (total_cases / population)*100.00 as infected_per_population
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, ROUND((MAX(total_cases) / population)*100.00, 2) as infected_per_population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC;

-- Looking at countries with highest death rate compared to population
SELECT location, population, MAX(total_deaths) AS highest_death_count, ROUND((MAX(total_deaths) / population)*100.00, 4) as deaths_per_population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 3 DESC;

-- let's break things down by continent
-- Showing continents with the highest death count per population
SELECT location, population, MAX(total_deaths) AS highest_death_count, ROUND((MAX(total_deaths) / population)*100.00, 4) as deaths_per_population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is null 
GROUP BY location, population
ORDER BY 3 DESC;

-- Global numbers
-- total_cases and total_deaths per day globally
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100.00) AS total_death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2;

-- total_cases and total_deaths globally in sum
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100.00) AS total_death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1, 2;


SELECT vac.new_vaccinations
FROM PortfolioProject.dbo.CovidVaccinations vac

-- Looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3;

-- Rolling count of vaccinations by location and date
-- USE CTE 
WITH Pop_vs_Vac (continent, location, date, population, new_vaccinations, rolling_count_vaccinations) 
AS
	(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_vaccinations
	FROM PortfolioProject.dbo.CovidDeaths dea
	JOIN PortfolioProject.dbo.CovidVaccinations vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
	WHERE dea.continent is not null
	)
SELECT *, (rolling_count_vaccinations/population)*100.00
FROM Pop_vs_Vac;

-- TEMP TABLE
DROP TABLE IF EXISTS #Percent_Population_Vaccinated
CREATE TABLE #Percent_Population_Vaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime, 
population numeric,
new_vaccinations numeric,
rolling_count_vaccinations numeric
)
INSERT INTO #Percent_Population_Vaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_vaccinations
		FROM PortfolioProject.dbo.CovidDeaths dea
		JOIN PortfolioProject.dbo.CovidVaccinations vac
			ON dea.location = vac.location 
			AND dea.date = vac.date
		WHERE dea.continent is not null;

SELECT *
FROM #Percent_Population_Vaccinated;

-- Creating View to store data for later visualizations
CREATE VIEW Percent_Population_Vaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
				   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_vaccinations
	FROM PortfolioProject.dbo.CovidDeaths dea
	JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location 
	   AND dea.date = vac.date
	WHERE dea.continent is not null;

SELECT *
FROM Percent_Population_Vaccinated;