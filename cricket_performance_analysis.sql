use stats;
select* from players;
select* from match_type;
select* from performance;

select* from performance 
where player_id = 8 and format_id = 3;

delete from performance 
where player_id = 2 and format_id = 1 and runs = 101;

delete from performance 
where perf_id is null;

insert into performance( Perf_id ,Player_id , format_id , opponent , Innings_number , Runs , Balls_faced , Wickets , Overs_bowled , Runs_conceded)
values( 529 , 2 , 3 ,'ENG' , 1 , 101 , 58 , 'NA' , 'NA' ,'NA')  ;

set sql_safe_updates = 0;
update performance
set 
runs = 101 where runs = 1014;

-- Total runs of each player 
create view Total_runs as 
select p.name , m.format , sum(cast(replace(perf.runs , '*','') as unsigned)) as Total_runs
from players p
join performance perf
on p.player_id = perf.player_id
join match_type m
on m.format_id = perf.format_id
where perf.runs != 'NA'
group by p.name , m.format
order by
Total_runs DESC;

-- Batting Avg of each player across formats
create view Batting_Avg as 
select p.name , m.format , round(sum(cast(replace(perf.runs , '*' , '') as unsigned))*1.0
								/Nullif(count(perf.runs)-count(case when perf.runs like '%*' then 1 end),0),2) as Batting_avg
from players p
join performance perf
on p.player_id = perf.player_id
join match_type m
on m.format_id = perf.format_id
where perf.runs != 'NA'
group by 
p.name , m.format
order by 
Batting_avg ;

-- Strike Rate of Players accross formats
create view Strike_Rate as 
select p.name , m.format , round(sum(cast(replace(perf.runs ,'*','') as unsigned))*100/ sum(perf.balls_faced),2) as Strike_rate
from players p
join performance perf
on p.player_id = perf.player_id
join match_type m
on m.format_id = perf.format_id
where perf.runs != 'NA'
group by 
p.name , m.format
order by
Strike_rate DESC;

-- Fastest Strike rate in a match
create view Fastest_SR as 
select p.name , m.format , round(max(cast(replace(perf.runs , '*' , '') as unsigned )*100/perf.balls_faced),2) as Fastest_Sr
from players p
join performance perf
on p.player_id = perf.player_id
join match_type m
on m.format_id = perf.format_id
where perf.runs != 'NA' and perf.balls_faced >=10
group by p.name , m.format
order by 
Fastest_sr DESC;

-- Best Score against each opponent in each format
create view Best_Score_Match as 
with Best_score as ( select p.name , m.format , perf.opponent, perf.runs,
					 row_number() over
                     (partition by p.name , m.format , perf.opponent
					order by cast(replace(perf.runs , '*','') as unsigned) desc ) as rn
                    from performance perf
                    join players p
                    on p.player_id = perf.player_id
                    join match_type m
                    on m.format_id = perf.format_id
                    where perf.runs != 'NA'
                    )
select name , format , opponent,runs as highest_score
from Best_score
where rn =1
order by 
name , opponent , format;

-- Most number of 50s
create view Fifties as 
select p.name , m.format , count(*) as fifties
from performance perf
join players p
on perf.player_id = p.player_id
join match_type m
on perf.format_id = m.format_id
where perf.runs != 'NA'
and cast(replace(perf.runs,'*','') as unsigned) >=50 
and cast(replace(perf.runs,'*','') as unsigned)<100
group by 
p.name , m.format
order by
fifties desc;

-- Number of centuries
create view Hundreds as 
select p.name , m.format , count(*) as Century_count
from performance perf
join players p
on perf.player_id = p.player_id
join match_type m
on perf.format_id = m.format_id
where perf.runs != 'NA'
and
cast(replace(perf.runs,'*','') as unsigned) >=100
group by 
p.name , m.format
order by
Century_count desc;

-- Percentage of fifty plus scores
create view Fifty_plus_percentage as 
select p.name , count(perf.innings_number) as innings_played , m.format , round(sum(case 
										when cast(replace(perf.runs,'*','')as unsigned) >=50 then 1
                                        else 0
                                        end)*100/count(perf.innings_number),2) as fifty_percentage
from performance perf
join players p
on perf.player_id = p.player_id
join match_type m
on perf.format_id = m.format_id
where perf.runs!='NA'
group by 
p.name ,  m.format
order by 
fifty_percentage DESC;

-- Number of notouts
create view Not_outs as 
select p.name , m.format , count(case when perf.runs like'%*' then 1 end)  as not_outs
from performance perf
join players p
on p.player_id = perf.player_id
join match_type m
on m.format_id = perf.format_id
where perf.runs != 'NA'
group by
p.name , m.format 
order by
not_outs DESC;

-- Best Bowling Figures per match
create view Bowling_Figures as 
select p.name , m.format , max(perf.wickets) as Best_figures
from performance perf
join players p
on p.player_id = perf.player_id
join match_type m
on m.format_id = perf.format_id
where perf.Wickets != 'NA'
group by 
p.name , m.format
order by
best_figures DESC;

-- Dismissal percentage 
create view Dismissal_Percentage as 
SELECT 
    p.name,
    m.format,
    ROUND(COUNT(CASE
                WHEN perf.runs NOT LIKE '%*' THEN 1 END) * 100 / COUNT(innings_number), 2) AS Dismissal_percentage
FROM
    performance perf
        JOIN
    players p ON p.player_id = perf.player_id
        JOIN
    match_type m ON m.format_id = perf.format_id
WHERE
    perf.runs != 'NA'
GROUP BY p.name , m.format 
ORDER BY Dismissal_percentage;

								
-- Total Wickets across formats
create view Total_Wickets as 
select p.name , m.format , sum(perf.Wickets) as Total_wickets
from players p
join performance perf
on p.player_id = perf.player_id
join match_type m
on m.format_id = perf.format_id
where perf.Wickets != 'NA'
group by 
p.name , m.format
order by
Total_wickets DESC;

-- Bowling Average across formats
create view Bowling_Avg as 
select p.name , m.format , round(sum(perf.runs_conceded)*1.0/sum(perf.Wickets),2) as Bowling_Avg
from performance perf
join players p 
on perf.player_id = p.player_id
join match_type m
on m.format_id = perf.format_id
where Perf.Wickets != 'NA'
group by
p.name , m.format
order by
Bowling_Avg ;

-- Economy Rate Across Formats
create view Economy as 
select p.name , m.format , round(sum(perf.runs_conceded)*1.0/sum(overs_bowled),2) as Economy
from performance perf
join players p 
on perf.player_id = p.player_id
join match_type m
on m.format_id = perf.format_id
where Perf.overs_bowled != 'NA'
group by
p.name , m.format
order by
Economy ;

-- Consistency of each batsman--
create view Consistency as 
with playerscores as ( 
						select p.name , m.format , cast(replace(perf.runs , '*' , '') as unsigned ) as Total_runs
                        from performance perf 
                        join players p
                        on perf.player_id = p.player_id
                        join match_type m
                        on m.format_id = perf.format_id
                        where perf.runs != 'NA'),
 
Consistency as (	
					select name , format ,
                    round(avg(Total_runs),2) as AVG_runs,
                    round(STDDEV(Total_runs),2) as Consistence
                    from playerscores
                    group by 
                    name , format
)
select*, round(AVG_runs/nullif(Consistence ,0),2) as Consistency_index
from Consistency
order by Consistency_index DESC;

-- 50 to 100 conversion rate --
create view Conversion_Rate as 
with Fifties as ( select p.name,	
					m.format , count(perf.runs) as Fifty_plus
                    from performance perf
                    join players p
                    on perf.player_id = p.player_id
                    join match_type m
                    on m.format_id = perf.format_id
                    where perf.runs != 'NA' and cast(replace(perf.runs , '*' ,'') as unsigned)>=50
                    group by 
                    p.name , m.format ),
                    
Centuries as ( select p.name , m.format , count(perf.runs) as Hundreds
                    from performance perf
                    join players p
                    on perf.player_id = p.player_id
                    join match_type m
                    on m.format_id = perf.format_id
                    where perf.runs != 'NA' and cast(replace(perf.runs , '*' ,'') as unsigned)>=100
                    group by 
                    p.name , m.format )   
                    
select 	f.name , 
		f.format , 
		f.Fifty_plus , 
		c.Hundreds ,
		round(Hundreds*100/Nullif(Fifty_plus ,0),2) as Conversion_Rate
		from Fifties f
		left join Centuries c
		on f.name = c.name and f.format = c.format
		order by Conversion_Rate DESC;
        
        
-- Top 3 scores of Batsmen
create view Top_Three_scores as 
with Scores as ( select
				 p.name , 
                 m.format , 
                 perf.runs,
                 perf.opponent,
                 row_number() over(partition by p.name , m.format 
				 order by cast(replace(perf.runs , '*' , '') as unsigned)Desc) as Top_Score
                 from performance perf
                 join players p
                 on perf.player_id = p.player_id
                 join match_type m
                 on m.format_id = perf.format_id
                 where perf.runs != 'NA'
                 )
select name , format , runs , opponent
from Scores
where Top_score <=3
order by name , format , Top_score;
	


			
				




