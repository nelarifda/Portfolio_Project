-- view all data in CovidDeaths table
select *
from CovidDeaths
where continent is not NULL
order by 3,4

-- select data that we are going to use
select location, date, total_cases, new_cases, total_deaths, population 
from CovidDeaths
where continent is not NULL
order by 1,2

-- total cases vs total deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from CovidDeaths
where continent is not NULL
order by 1,2

-- looking total cases vs total deaths in certain location
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from CovidDeaths
where location like '%states%'
and continent is not NULL
order by 1,2

-- looking total cases vs total deaths in certain location
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from CovidDeaths
where location = 'Indonesia'
and continent is not NULL
order by 1,2


-- total cases vs population
select location, date, total_cases, population, (total_cases/population)*100 as cases_percentage
from CovidDeaths
where continent is not NULL
order by 1,2

-- countries with highest infection rate compared to population
select location, population, MAX(total_cases) as highest_infection, max((total_cases/population)*100) as percent_populationinfected
from CovidDeaths
where continent is not NULL
group by location, population
order by percent_populationinfected desc

-- countries with highest death count per population
select location, population, max(cast(total_deaths as int)) as highest_death
from CovidDeaths
where continent is not NULL
group by location, population
order by highest_death desc

-- continents with the highest death count per population
select continent, max(cast(total_deaths as int)) as totaldeathcount
from CovidDeaths
where continent is not NULL
group by continent
order by totaldeathcount desc

-- location in north america continent with highest death count
select location, max(cast(total_deaths as int)) as totaldeathnorthamerica
from CovidDeaths
where continent = 'North America'
group by location
order by totaldeathnorthamerica desc

-- location in asia continent with highest total cases percentage
select location, max(total_cases) as highestcase, population, max(total_cases/population)*100 as casepercentageasia
from CovidDeaths
where continent = 'asia'
group by location, population
order by casepercentageasia desc

-- Global numbers based on date
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as death_percentage
from CovidDeaths
where continent is not NULL
group by date
order by date 

-- total population vs vaccionation
select dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths dea
Join CovidVaccinations vac
	on dea.location = vac.location
where dea.continent is not NULL
order by 1,2

-- cummulative people vaccinated
select dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as cummulative_vaccinations
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
group by dea.location, dea.date, dea.population, vac.new_vaccinations
order by 1,2

-- using CTE to calculate previous query
with CummulativePercentage (location, date, population, new_vaccinations, cummulative_vaccinations)
as
(
select dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as cummulative_vaccinations
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
group by dea.location, dea.date, dea.population, vac.new_vaccinations
--order by 1,2
)
select *, (cast(cummulative_vaccinations as float)/cast(population as float))*100
from CummulativePercentage

-- using temp table to perform calculation on partition by from previous query
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
location nvarchar(255),
date datetime, 
population numeric,
new_vaccinations numeric,
cummulative_vaccinations numeric,
)

insert into #PercentPopulationVaccinated
select dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as cummulative_vaccinations
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
group by dea.location, dea.date, dea.population, vac.new_vaccinations
order by location, date

select *, (cummulative_vaccinations/population)*100 as percentpopulationvaccinated
from #PercentPopulationVaccinated

-- creating view to store data for later visualizations
create view PercentPopulationVaccinated as
select dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as cummulative_vaccinations
from CovidDeaths dea
join CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
group by dea.location, dea.date, dea.population, vac.new_vaccinations
--order by 1,2