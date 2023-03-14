SELECT * 
FROM covid_deaths
WHERE continent is not null
ORDER BY 3,4

--Select * 
--From covid_vaccinations
--order by 3,4

-- Select Data that we are going to be using.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM covid_deaths
WHERE location = 'United States'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as percent_pop_infected
FROM covid_deaths
--WHERE location = 'United States'
ORDER BY 1,2

--Comparing total number of cases between countries

SELECT location, MAX(total_cases) as total_cases_count
FROM covid_deaths
WHERE continent is not null
GROUP BY location
ORDER BY total_cases_count DESC nulls last

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as percent_pop_infected
FROM covid_deaths
--WHERE location = 'United States'
GROUP BY location, population
ORDER BY percent_pop_infected DESC NULLS LAST


-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) as total_death_count 
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST

-- Looking at countries with highest number of icu patients 

SELECT location, MAX(icu_patients) as icu_patient_count 
FROM covid_deaths
WHERE continent is not null
GROUP BY location
ORDER BY icu_patient_count DESC NULLS LAST

-- Let's break things down by continent

-- Showing continents with the highest death count per population

SELECT continent, MAX(total_deaths) as total_death_count 
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC NULLS LAST

-- GLOBAL NUMBERS 

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM covid_deaths
--WHERE location = 'United States' 
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2 

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, 
	dea.date) as rolling_people_vacc
FROM covid_deaths as dea
JOIN covid_vaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- USE CTE

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vacc) 
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, 
	dea.date) as rolling_people_vacc
FROM covid_deaths as dea
JOIN covid_vaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null)
--ORDER BY 2,3

SELECT *, (rolling_people_vacc/population)*100 as rolling_perc_vacc
FROM pop_vs_vac

-- TEMP TABLE

CREATE TABLE percent_population_vaccinated
(
continent varchar(255),
location varchar(255),
date date,
population numeric,
new_vaccinations numeric,
rolling_people_vacc numeric
)

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, 
	dea.date) as rolling_people_vacc
FROM covid_deaths as dea
JOIN covid_vaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (rolling_people_vacc/population)*100 as rolling_perc_vacc
FROM percent_population_vaccinated

-- Creating View to store data for later visualizations

CREATE VIEW percent_population_vaxed as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, 
	dea.date) as rolling_people_vacc
FROM covid_deaths as dea
JOIN covid_vaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

CREATE VIEW global_numbers as 
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM covid_deaths
--WHERE location = 'United States' 
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2 


