select *
from dbo.CovidDeath$
order by 3,4
-- ordery by column 3 and column 4

--select *
--from dbo.CovidVaccinations$
--order by 3,4

-- Select all data that we are going to be using later
Select location,date,total_cases,new_cases,total_deaths,population
from PortfolioProject..CovidDeath$
order by 1,2


--Looking at the total case Vs Total Deaths
--Show the likelihood of dying if you get Covid in Canada
Select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
from PortfolioProject..CovidDeath$
where location like '%Canada'
order by 1,2

--Looking at the total case Vs Population
-- The percentage of Canandian caught Covid by now
Select location,date,total_cases,population,(total_cases/population)*100 AS CasePercentagePerPopulation
from PortfolioProject..CovidDeath$
where location like '%Canada' 
and (total_cases/population)*100 >= 1
order by 1,2


--What country has the highest CasePercentage?
Select location,max(total_cases) As HighestTotalCase, 
population,Max((total_cases/population))*100 AS CasePercentagePerPopulation
from PortfolioProject..CovidDeath$
where continent is Not NULL
group by location,population
--Having location like '%Canada'
order by CasePercentagePerPopulation DESC


--Showing the countries with the highest death Count per population
Select location,population,
Max(cast(total_deaths as int)) as HighestDeathCount,
(Max(cast(total_deaths as int))/population)*100 As DeathPerPopulation
from PortfolioProject..CovidDeath$
where continent is Not NULL
group by location,population
order by DeathPerPopulation DESC


--let's break down to continent
Select location,population,
Max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeath$
where continent is NULL
group by location,population
--filter out the high income middle income
Having location NOT like '%income' 
order by HighestDeathCount DESC

--Showing the continents with the highest death count per population

--Global Numbers
Select sum(new_cases) as TotalCase,sum(cast(new_deaths as int)) as TotalDeath,
(sum(cast(new_deaths as int))/sum(new_cases))*100 As DeathPercentageGlobal
from PortfolioProject..CovidDeath$
--where location like '%Canada'
where continent is not null
--Group by Date
order by 1,2


--Look at the vaccination table and death table
--Looking at total population Vs vaccination
--By each country
select Death.continent,Death.location,--Death.Date,
max(Death.population) As TotalPopu,
Max(Vacci.total_vaccinations) As TotalVacci,
Max(Vacci.total_vaccinations)/max(Death.population)*100 As VacciPerPopulation
from [dbo].[CovidDeath$] As Death join
[dbo].[CovidVaccinations$] As Vacci
on Death.location = Vacci.location
and Death.date = Vacci.date
where Death.continent is NOT NULL
group by Death.continent,Death.location
Having Max(Vacci.total_vaccinations) is NOT NULL and max(Death.population) is NOT NULL
order by 5 DESC



-- Use of Partition by to rolling count the vaccination numbers
select Death.continent,Death.location,Death.date,Death.population,Vacci.new_vaccinations,
Sum(CAST(Vacci.new_vaccinations as bigint)) 
Over (partition by death.location Order by death.location, Death.date) As RollingPeopleVaccinated
from [dbo].[CovidDeath$] As Death join
[dbo].[CovidVaccinations$] As Vacci
on Death.location = Vacci.location
and Death.date = Vacci.date
where Death.continent is not null and death.location like '%Canada'
order by 2,3


--Use CTE to see how Canada's vaccinated rate change follow by time
With CTE_PopVsVac(Cotinent, location, Date, Population, New_vaccination, RollingPeoploeVaccinated)
as(
select Death.continent, Death.location, Death.date, Death.population, Vacci.new_vaccinations,
Sum(CAST(Vacci.new_vaccinations as bigint)) 
Over (partition by death.location Order by death.location, Death.date) As RollingPeopleVaccinated
from [dbo].[CovidDeath$] As Death join
[dbo].[CovidVaccinations$] As Vacci
on Death.location = Vacci.location
and Death.date = Vacci.date
where Death.continent is not null and death.location like '%Canada'
--order by 2,3
)
select *,RollingPeoploeVaccinated/Population*100 As PerOfPeopleVaccinated
from CTE_PopVsVac
order by 1,2,3


-- Use temp table to see how Canada's vaccinated rate change follow by time
DROP table if exists #temp_PopulationVsVacci
Create TABLE #temp_PopulationVsVacci
(continent nvarchar(255),
location nvarchar(255),
date Datetime,
population numeric,
new_vaccinations numeric,
RollingPeoploeVaccinated numeric
)

insert into #temp_PopulationVsVacci 
select Death.continent,Death.location,Death.date,Death.population,Vacci.new_vaccinations,
Sum(CAST(Vacci.new_vaccinations as bigint)) 
Over (partition by death.location Order by death.location, Death.date) As RollingPeopleVaccinated
from [dbo].[CovidDeath$] As Death join
[dbo].[CovidVaccinations$] As Vacci
on Death.location = Vacci.location
and Death.date = Vacci.date
where Death.continent is not null and death.location like '%Canada'
--order by 2,3

select *,RollingPeoploeVaccinated/Population*100 As PerOfPeopleVaccinated
from #temp_PopulationVsVacci
order by PerOfPeopleVaccinated
GO


--Creating view to store data for later visulizations
Create View PerOfPeopleVaccinated As
select Death.continent,Death.location,Death.date,Death.population,Vacci.new_vaccinations,
Sum(CAST(Vacci.new_vaccinations as bigint)) 
Over (partition by death.location Order by death.location, Death.date) As RollingPeopleVaccinated
from [dbo].[CovidDeath$] As Death join
[dbo].[CovidVaccinations$] As Vacci
on Death.location = Vacci.location
and Death.date = Vacci.date
where Death.continent is not null and death.location like '%Canada'
--order by 2,3

--Now we can use PerOfPeopleVaccinated for later use
--For example later graph
select *
from PerOfPeopleVaccinated
GO



--Another View that can be use to show how death rate change by time
--DeathRate = totalDeath/totalCase
Create view DeathPerCaseCanada AS
Select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPerCase
from PortfolioProject..CovidDeath$
where location like '%Canada'
--order by 1,2

select *
from DeathPerCaseCanada
GO

--Next View: Percentage of Canadian caught coivd by now
-- The TotalCase/TotalPopulation Rate
create view CasePerPopCanada AS
Select location,date,total_cases,population,(total_cases/population)*100 AS CasePercentagePerPopulation
from PortfolioProject..CovidDeath$
where location like '%Canada' 
--and (total_cases/population)*100 >= 1
--order by 1,2

select *
from CasePerPopCanada