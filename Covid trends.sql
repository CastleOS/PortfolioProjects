--select *
--from ['Covid Deaths$']
--order by 3,4

--select *
--from ['Covid Vaccinations$']
--order by 3,4

Select 
	Location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
from [Portfolio Project]..['Covid Deaths$']
	order by 1,2 

-- will order results by location and date

-- Looking at Total Cases vs Total Deaths

Select 
	Location, 
	date, 
	total_cases, 
	total_deaths, 
	((total_deaths/total_cases) * 100) as percent_death
from [Portfolio Project]..['Covid Deaths$']
	where location like '%states'
	order by 1,2


-- Looking at total cases vs population

Select 
	Location, 
	date, 
	total_cases, 
	population, 
	((total_cases/population) * 100) as percent_death
from [Portfolio Project]..['Covid Deaths$']
	where location like '%states' and total_cases is not null
	order by 1,2

-- What countries have the highest infection rates compared to population?

Select
	location,
	population, 
	max(total_cases) as HighestInfectionCount, 
	max((total_cases/population))*100 as PercentPopulationInfected
from [Portfolio Project]..['Covid Deaths$']
where continent is not null
group by location, population
order by 4 desc

-- Showing countries with highest death count per population

Select
	location,
	max(cast(Total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..['Covid Deaths$']
where continent is not null -- removes entire continents from list
group by location
order by 2 desc

-- Organized by Continent

Select
	location,
	max(cast(Total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..['Covid Deaths$']
	-- where location like '%states%'
	where continent is null -- removes entire continents from list
	group by location
	order by TotalDeathCount desc

-- Organize by total death count of location within a continent
Select
	continent,
	max(cast(Total_deaths as int)) as TotalDeathCount,
	location
from [Portfolio Project]..['Covid Deaths$']
	where (continent is not null) --and continent = 'South America') -- removes entire continents from list
	group by continent, location
	order by 1,2 desc

-- GLOBAL NUMBERS

Select 
	date, 
	SUM(new_cases) as TotalNewCases,
	SUM(cast(new_deaths as int)) as TotalNewDeaths,
	Sum(cast(new_deaths as int))/Sum(new_cases)* 100 as DeathPercentage 
from [Portfolio Project]..['Covid Deaths$']
	--where location like '%states'
	where continent is not null and new_cases != 0
	group by date
	order by 1,2
	
-- Look at Total Population vs Vaccinations

Select 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(Convert(bigint, vac.new_vaccinations)) 
		OVER (
			Partition by dea.location 
			Order by dea.location, dea.date
			) as RollingVaccinationCount
From [Portfolio Project]..['Covid Deaths$'] dea
Join [Portfolio Project]..['Covid Vaccinations$'] vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.Continent is not null
Order by 2,3

--Create CTE for Population vs Vaccination

With PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinationCount)
as
(
Select 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(Convert(bigint, vac.new_vaccinations)) 
		OVER (
			Partition by dea.location 
			Order by dea.location, dea.date
			) as RollingVaccinationCount
From [Portfolio Project]..['Covid Deaths$'] dea
Join [Portfolio Project]..['Covid Vaccinations$'] vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.Continent is not null
--Order by 2,3
)

Select *, (RollingVaccinationCount/population * 100)
From PopvsVac


--Temp Table
Drop Table if exists #PercentPopulationsVaccinated
Create Table #PercentPopulationsVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinationCount numeric
)

Insert into #PercentPopulationsVaccinated
Select 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(Convert(bigint, vac.new_vaccinations)) 
		OVER (
			Partition by dea.location 
			Order by dea.location, dea.date
			) as RollingVaccinationCount
From [Portfolio Project]..['Covid Deaths$'] dea
Join [Portfolio Project]..['Covid Vaccinations$'] vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.Continent is not null

Select *, (RollingVaccinationCount/population * 100)
From #PercentPopulationsVaccinated

--Creating Views to store data for later visualization

Create View PercentPopulationsVaccinated as
Select 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(Convert(bigint, vac.new_vaccinations)) 
		OVER (
			Partition by dea.location 
			Order by dea.location, dea.date
			) as RollingVaccinationCount
From [Portfolio Project]..['Covid Deaths$'] dea
Join [Portfolio Project]..['Covid Vaccinations$'] vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.Continent is not null