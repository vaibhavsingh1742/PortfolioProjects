-- display all rows of the table Covid Deaths ordered by country and date
SELECT 
*
FROM PortfolioProject..CovidDeaths
ORDER BY 3 , 4;

-- display all rows of the table Covid Vaccinations ordered by country and date
SELECT 
*
FROM PortfolioProject..CovidVaccinations
ORDER BY 3 , 4;

-- gives the infection percentage of every country
SELECT * 
FROM (
	SELECT country, MAX(total_cases) AS max_cases, MAX(population) AS latest_population, MAX((total_cases/population)) * 100.0 AS infection_percentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY country
) a
ORDER BY a.infection_percentage DESC;

-- gives the death percentage of the whole world
SELECT 
	SUM(new_cases) AS cases, 
	SUM(new_deaths) AS deaths, 
	(SUM(new_deaths)/IIF(SUM(new_cases) = 0, 1, SUM(new_cases))) * 100.0 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

-- using CTE, gives the number of cases each day, infection percentage and the percentage of people fully vaccinated
WITH Vacc AS 
(
	SELECT 
		dea.continent, 
		dea.country, 
		dea.date, 
		dea.population,
		SUM(CAST(dea.new_cases AS bigint)) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_cases,
		MAX(CAST(dea.total_cases AS bigint)) OVER (PARTITION BY dea.country) AS max_infected,
		MAX(CAST(vac.people_fully_vaccinated AS float)) OVER (PARTITION BY dea.country) AS full_vaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)

SELECT 
	*,
	(CAST(max_infected AS float)/population) * 100 AS infected_percentage,
	(full_vaccinations/population) * 100 AS full_vaccination_percentage
FROM Vacc
ORDER BY 2, 3;

-- using Temp Table, gives the number of cases each day, infection percentage and the percentage of people fully vaccinated
DROP TABLE IF EXISTS #VaccTable;
CREATE TABLE #VaccTable (
	Continent varchar(50),
	Country varchar(50),
	Date datetime,
	Population bigint,
	Rolling_Cases bigint,
	Max_Infected bigint,
	Full_Vaccinations float
)

INSERT INTO #VaccTable
	SELECT 
		dea.continent, 
		dea.country, 
		dea.date, 
		dea.population,
		SUM(CAST(dea.new_cases AS bigint)) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_cases,
		MAX(CAST(dea.total_cases AS bigint)) OVER (PARTITION BY dea.country) AS max_infected,
		MAX(CAST(vac.people_fully_vaccinated AS float)) OVER (PARTITION BY dea.country) AS full_vaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL


SELECT
	*,
	(CAST(Max_Infected AS float)/Population) * 100 AS Infection_Percentage,
	(Full_Vaccinations/Population) * 100 AS Full_Vaccination_Percentage
FROM #VaccTable
ORDER BY 2, 3;

-- creating a VIEW of the data
DROP VIEW IF EXISTS DeathVacTable;
GO
CREATE VIEW DeathVacTable AS
	SELECT 
		dea.continent, 
		dea.country, 
		dea.date, 
		dea.population,
		SUM(CAST(dea.new_cases AS bigint)) OVER (PARTITION BY dea.country ORDER BY dea.date) AS rolling_cases,
		MAX(CAST(dea.total_cases AS bigint)) OVER (PARTITION BY dea.country) AS max_infected,
		MAX(CAST(vac.people_fully_vaccinated AS float)) OVER (PARTITION BY dea.country) AS full_vaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
GO

SELECT * FROM DeathVacTable;
