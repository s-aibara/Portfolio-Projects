
--Covid 19 Data Exploration (Reference: Alex the Analyst)
--Skills Used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views 

SELECT * 
FROM covid_deaths
WHERE continent is not null
ORDER BY 3,4

--Select * 
--From covid_vaccinations
--order by 3,4

-- Select Data that we are going to be using intially. 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent is not null
ORDER BY 1,2

-- Total Cases vs. Total Deaths
-- Shows the likelihood of dying if you contract covid in your country.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM covid_deaths
WHERE location = 'United States'
ORDER BY 1,2

-- Total Cases vs. Population
-- Shows the percentage of the population that contracted Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as percent_pop_infected
FROM covid_deaths
--WHERE location = 'United States'
ORDER BY 1,2

-- Total Cases by Country
-- Comparing the total number of Covid cases between countries.

SELECT location, MAX(total_cases) as total_cases_count
FROM covid_deaths
WHERE continent is not null
GROUP BY location
ORDER BY total_cases_count DESC nulls last

-- Countries with Highest Infection Rate compared to Population
-- What percentage of the popuation has contracted covid?

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as percent_pop_infected
FROM covid_deaths
--WHERE location = 'United States'
GROUP BY location, population
ORDER BY percent_pop_infected DESC NULLS LAST


-- Showing Countries with Highest Death Count 

SELECT location, MAX(total_deaths) as total_death_count 
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST

-- Showing countries with Highest Number of ICU Patients 

SELECT location, MAX(icu_patients) as icu_patient_count 
FROM covid_deaths
WHERE continent is not null
GROUP BY location
ORDER BY icu_patient_count DESC NULLS LAST

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count

SELECT continent, MAX(total_deaths) as total_death_count 
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC NULLS LAST

-- Showing continents with the highest infection rate 

SELECT continent, MAX((total_cases/population))*100 as percent_pop_infected
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent is not null
GROUP BY continent
ORDER BY percent_pop_infected DESC NULLS LAST


-- GLOBAL NUMBERS 

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as global_death_percentage
FROM covid_deaths 
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2 

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, 
	dea.date) as rolling_people_vacc
FROM covid_deaths as dea
JOIN covid_vaccinations as vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Use CTE to perform calculation on Partition By in previous query

WITH pop_vs_vac as
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



-- Use Temp Table to perform calculation on Partition By in previous query

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



-- Creating Views to store data for later visualizations

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


