CREATE TABLE daily_summary AS
SELECT 
    o.date,
    o.mood,
    s.total_sleep,
    s.efficiency,
    steps.daily_steps,
    ar.active_energy,
    o.journal,
	o.social_media_hours,
	o.offline_communication,
	o.meditation,
    o.hrv,
    ROUND(fp.hours, 1) AS total_focus_hours,
    fp.sessions_count,
    CASE 
    	WHEN ar.active_energy >= ar.active_energy_goal
    	AND ar.exercise_minutes >= ar.exercise_minutes_goal
    	AND ar.stand_hours >= ar.stand_hours_goal
    	THEN 1 ELSE 0
    END AS all_rings_closed   
FROM other_metrics o
LEFT JOIN sleep s ON o.date = s.date
LEFT JOIN (
    SELECT date, SUM(value) AS daily_steps
    FROM steps
    GROUP BY date
) steps ON o.date = steps.date
LEFT JOIN active_rings ar ON o.date = ar.date
LEFT JOIN (
    SELECT 
        start_time::date AS date,
        SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600) AS hours,
        COUNT(*) AS sessions_count
    FROM forest_productivity
    GROUP BY start_time::date
) fp ON o.date = fp.date
ORDER BY o.date;


SELECT *
FROM daily_summary