-- 1. How many olympics games have been held?
select count (distinct Games) as total_olympics_games
from athlete_events


-- 2. List down all olympics games held so far
select distinct Year, Season, City
from athlete_events
order by Year


-- 3. Mention the total no of nations who participated in each olympics game?
select Games, count (distinct NOC) as total_countries
from athlete_events
group by Games
order by Games


-- 4. Which year saw the highest and lowest no of countries participating in olympics?
with totalcountries_cte
as
(
select Games, count (distinct NOC) as total_countries
from athlete_events
group by Games
)
select distinct
      concat(first_value(Games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(Games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from totalcountries_cte


-- 5. Which nation has participated in all of the olympic game?
with totalgames_cte as
(
select count (distinct Games) as total_olympics_games
from athlete_events
),
totalparticipated_cte as
(
select noc_regions.region as Countries, count (distinct athlete_events.Games) as total_participated
from athlete_events
join noc_regions
	on athlete_events.NOC = noc_regions.NOC
group by noc_regions.region
)
select Countries, total_participated
from totalparticipated_cte
join totalgames_cte
	on totalparticipated_cte.total_participated = totalgames_cte.total_olympics_games 


-- 6. Identify the sport which was played in all summer olympics
with nogames_cte
as
(
select COUNT(distinct Games) as No_of_games
from athlete_events
where Games LIKE '%Summer%'
Group by Season
),
summersport_cte
as
(
select Sport, Season, COUNT (distinct Games) as total_games
from athlete_events
where Season = 'Summer'
group by Sport, Season
)
select Sport, total_games
from summersport_cte
join nogames_cte
	on summersport_cte.total_games = nogames_cte.No_of_games


-- 7. Which sports were just played only once in the olympics?
with sports_cte
as
(
select Sport, COUNT (distinct Games) as total_played
from athlete_events
group by Sport
),
games_cte
as
(
select distinct (Games) as Games_played, Sport
from athlete_events
group by Games, Sport
)
select sports_cte.Sport, total_played, Games_played
from sports_cte
join games_cte
	on sports_cte.Sport = games_cte.Sport
where total_played = '1'
order by Games_played

-- 8. Fetch the total no of sports played in each olympic game
select Games, count (distinct Sport) as no_sports
from athlete_events
group by Games
order by no_sports desc


-- 9. Fetch details of the oldest athletes to win a gold medal
--- name, sex, age, team, games, city, event, medals
with gold_cte
as
(
select Name, Sex, Age, Team, Games, City, Event, Medal
from athlete_events
where Medal = 'Gold'
and Age <> 'NA'
group by Name, Sex, Age, Team, Games, City, Event, Medal
),
ranking
as 
(
select *, rank() over(order by age desc) as rnk
from gold_cte
where medal='Gold'
)
select *
from ranking
where rnk = 1


-- 10. Find the ratio of male and female athletes participated in all olympic games
with data_cte
as
(select Sex, count (Sex) as cous, ROW_NUMBER () over (order by sex) as rownum
from athlete_events
group by Sex
),
min_cte
as
(
select *
from data_cte
where rownum = 1
),
max_cte
as
(
select *
from data_cte
where rownum = 2
)
select concat( '1:',round(cast(max_cte.cous as decimal)/min_cte.cous, 2)) as Ratio 
from max_cte, min_cte


-- 11. Fetch the top 5 athletes who have won the most gold medals
with medals_cte as
(select Name, Team, COUNT (Medal) as total_gold
from athlete_events
where Medal = 'Gold'
group by Name, Team
--order by total_gold desc
),
rking_cte as
(
select *, dense_rank() over(order by total_gold desc) as rnk
from medals_cte
)
select Name, Team, total_gold
from rking_cte
where rnk <= 5

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)
with a1 as
(
select Name, Team, COUNT (Medal) as total_medals
from athlete_events
where Medal in ('Gold', 'Silver', 'Bronze')
Group by Name, Team
--order by total_medals desc
),
a2 as
(
select *, dense_rank() over(order by total_medals desc) as rkn
from a1
)
select Name, Team, total_medals
from a2
where rkn <= 5


-- 13. Fetch the top 5 most successful countries in olympics
with b1 as
(select distinct b4.region, Count (b3.Medal) as tot_medals
from athlete_events as b3
join noc_regions as b4
	on b3.NOC = b4.NOC
where b3.Medal in ('Gold', 'Silver', 'Bronze')
group by b4.region
--order by tot_medals desc
), 
b2 as
(select *, rank() over(order by tot_medals desc) as rnk
from b1
)
select region, tot_medals, rnk
from b2
where rnk <= 5


-- 14. List down total gold, silver, bronze medals won by each country
select region as Country , [Gold] as Gold, [Silver] as Silver, [Bronze] as Bronze
from
	(select c3.region, Medal
	from athlete_events c2
	join noc_regions c3
		on c2.NOC = c3.NOC
	where Medal <> 'NA'
	) as c1
PIVOT
	(count (Medal)
	for Medal in ([Gold], [Silver], [Bronze])
	) as pvt
order by Gold desc

---- or using this query

SELECT region as Country,
COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold_medal,
COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver_medal,
COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze_medal
FROM athlete_events as a
JOIN noc_regions as n 
	ON a.NOC = n.NOC
GROUP BY region
order by Gold_medal desc


-- 15. List down total gold, silver, bronze medals won by each country corresponding to each olympic games
select Games, region as Country , [Gold] as Gold, [Silver] as Silver, [Bronze] as Bronze
from
	(select Games, c3.region, Medal
	from athlete_events c2
	join noc_regions c3
		on c2.NOC = c3.NOC
	where Medal <> 'NA'
	) as c1
PIVOT
	(count (Medal)
	for Medal in ([Gold], [Silver], [Bronze])
	) as pvt
order by Games

---- or using this query

with cte as
(
select t1.NOC, t1.games, t2.region, t1.medal 
from athlete_events as t1 
join noc_regions as t2 
	on t1.NOC=t2.NOC
)
select games, region as Country,
sum(case when medal='Gold' then 1 else 0 end) as gold,
sum(case when medal='Silver' then 1 else 0 end) as silver,
sum(case when medal='Bronze' then 1 else 0 end) as bronze
from cte 
group by Games, region
order by Games, region

---- or using this query

SELECT Games, region,
COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold_medal,
COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver_medal,
COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze_medal
FROM athlete_events as a
JOIN noc_regions as n 
	ON a.NOC = n.NOC
GROUP BY games, region
order by Games, region


-- 16. Identify which country won the most gold, most silver, and most bronze medals in each olympic games
with dcte as
(
select Games, region,
count(CASE WHEN medal = 'Gold' THEN medal END) as Gold_medal,
count(CASE WHEN medal = 'Silver' THEN medal END) as Silver_medal,
count(CASE WHEN medal = 'Bronze' THEN medal END) as Bronze_medal
FROM athlete_events as a
JOIN noc_regions as n 
	ON a.NOC = n.NOC
group by Games, region
)
select distinct Games,
concat (first_value (region) over (partition by Games order by Gold_medal desc)
, '-'
, first_value (Gold_medal) over (partition by Games order by Gold_medal desc)) as Max_gold
, concat (first_value (region) over (partition by Games order by Silver_medal desc)
, '-'
, first_value (Silver_medal) over (partition by Games order by Silver_medal desc)) as Max_silver
, concat (first_value (region) over (partition by Games order by Bronze_medal desc)
, '-'
, first_value (Bronze_medal) over (partition by Games order by Bronze_medal desc)) as Max_bronze
from dcte
order by Games


-- 17. Identify which country won the most gold, most silver, most bronze, and the most medals in each olympic games
with dcte as
(
select Games, region,
count(CASE WHEN medal = 'Gold' THEN medal END) as Gold_medal,
count(CASE WHEN medal = 'Silver' THEN medal END) as Silver_medal,
count(CASE WHEN medal = 'Bronze' THEN medal END) as Bronze_medal,
count (Medal) as total_medals
FROM athlete_events as a
JOIN noc_regions as n 
	ON a.NOC = n.NOC
where Medal <> 'NA'
group by Games, region
)
select distinct Games,
concat (first_value (region) over (partition by Games order by Gold_medal desc)
, '-'
, first_value (Gold_medal) over (partition by Games order by Gold_medal desc)) as Max_gold
, concat (first_value (region) over (partition by Games order by Silver_medal desc)
, '-'
, first_value (Silver_medal) over (partition by Games order by Silver_medal desc)) as Max_silver
, concat (first_value (region) over (partition by Games order by Bronze_medal desc)
, '-'
, first_value (Bronze_medal) over (partition by Games order by Bronze_medal desc)) as Max_bronze
, concat (first_value (region) over (partition by Games order by total_medals desc)
, '-'
, first_value (total_medals) over (partition by Games order by total_medals desc)) as Max_medals
from dcte
order by Games


-- 18. Which countries have never won gold medal but have won silver/bronze medals?
with ecte as
(
select region as Country,
count(CASE WHEN medal = 'Gold' THEN medal END) as Gold_medal,
count(CASE WHEN medal = 'Silver' THEN medal END) as Silver_medal,
count(CASE WHEN medal = 'Bronze' THEN medal END) as Bronze_medal
FROM athlete_events as a
JOIN noc_regions as n 
	ON a.NOC = n.NOC
where Medal <> 'NA'
group by region
)
select *
from ecte
Where Gold_medal = 0 
order by Silver_medal desc, Bronze_medal desc


-- 19. In which sport/event, Indonesia has won highest medals
with f1 as
(select Sport, Event, Count (Medal) as total_medals
from athlete_events
where Team = 'Indonesia'
and Medal <> 'NA'
Group by Sport, Event
),
f2 as
(select *, rank() over(order by total_medals desc) as rnk
from f1
)
select Sport, Event, total_medals
from f2
where rnk = 1


-- 20. Break down all olympic games where Indonesia won medal for Badminton and how many medals in each olympic games
select Team, Sport, Games, Count(Medal) as total_medals
from athlete_events
where Team = 'Indonesia'
and Medal <> 'NA'
and Sport = 'Badminton'
Group by Team, Sport, Games
