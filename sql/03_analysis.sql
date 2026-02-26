--- базовая статистика

SELECT 
    COUNT(*) as days_count,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(EXTRACT(EPOCH FROM total_sleep)/3600), 1) as avg_sleep_hours,
    ROUND(AVG(efficiency), 1) as avg_sleep_efficiency,
    ROUND(AVG(daily_steps), 0) as avg_steps,
    ROUND(AVG(total_focus_hours), 1) as avg_focus_hours,
    ROUND(AVG(all_rings_closed)*100, 1) as rings_closed_percent
FROM daily_summary
;
--- мин. и макс. значения

SELECT 
    MIN(mood) as min_mood, MAX(mood) as max_mood,
    ROUND(MIN(EXTRACT(EPOCH FROM total_sleep)/3600), 2) as min_sleep, 
    ROUND(MAX(EXTRACT(EPOCH FROM total_sleep)/3600), 2) as max_sleep,
    MIN(daily_steps) as min_steps, 
    MAX(daily_steps) as max_steps
FROM daily_summary;

--- сводная по настроению

SELECT mood, COUNT(*) as days
FROM daily_summary
GROUP BY mood
ORDER BY mood;

--- корреляции между метриками

SELECT 
    -- настроение
    ROUND(CORR(mood, EXTRACT(EPOCH FROM total_sleep)/3600)::numeric, 3) as mood_sleep,
    ROUND(CORR(mood, daily_steps)::numeric, 3) as mood_steps,
    ROUND(CORR(mood, efficiency)::numeric, 3) as mood_efficiency,
    ROUND(CORR(mood, total_focus_hours)::numeric, 3) as mood_focus,
    ROUND(CORR(mood, hrv)::numeric, 3) as mood_hrv,
    ROUND(CORR(mood, all_rings_closed)::numeric, 3) as mood_rings,
    ROUND(CORR(mood, active_energy)::numeric, 3) as mood_active_energy,
    
    -- продуктивность
    ROUND(CORR(total_focus_hours, daily_steps)::numeric, 3) as focus_steps,
    ROUND(CORR(total_focus_hours, EXTRACT(EPOCH FROM total_sleep)/3600)::numeric, 3) as focus_sleep,
    ROUND(CORR(total_focus_hours, efficiency)::numeric, 3) as focus_efficiency,
    ROUND(CORR(total_focus_hours, hrv)::numeric, 3) as focus_hrv,
    ROUND(CORR(total_focus_hours, all_rings_closed)::numeric, 3) as focus_rings,
    ROUND(CORR(total_focus_hours, active_energy)::numeric, 3) as focus_active_energy,
    
    -- сон
    ROUND(CORR(EXTRACT(EPOCH FROM total_sleep)/3600, daily_steps)::numeric, 3) as sleep_steps,
    ROUND(CORR(EXTRACT(EPOCH FROM total_sleep)/3600, efficiency)::numeric, 3) as sleep_efficiency,
    ROUND(CORR(EXTRACT(EPOCH FROM total_sleep)/3600, hrv)::numeric, 3) as sleep_hrv,
    
    -- ВСР
    ROUND(CORR(hrv, daily_steps)::numeric, 3) as hrv_steps,
    ROUND(CORR(hrv, efficiency)::numeric, 3) as hrv_efficiency,
    ROUND(CORR(hrv, all_rings_closed)::numeric, 3) as hrv_rings,
    ROUND(CORR(hrv, active_energy)::numeric, 3) as hrv_active_energy
    
FROM daily_summary;


--- по дням неделям

SELECT 
    EXTRACT(DOW FROM date) as day_num,
    TO_CHAR(date, 'Day') as day_name,
    COUNT(*) as days,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(EXTRACT(EPOCH FROM total_sleep)/3600), 1) as avg_sleep,
     ROUND(AVG(efficiency), 1) as avg_efficiency,
    ROUND(AVG(daily_steps), 0) as avg_steps,
    ROUND(AVG(total_focus_hours), 1) as avg_focus,
    ROUND(AVG(all_rings_closed)*100, 1) as rings_pct
FROM daily_summary
GROUP BY day_num, day_name
ORDER BY day_num;

--- по месяцам
    
SELECT 
    EXTRACT(MONTH FROM date) as month,
    TO_CHAR(date, 'YYYY-MM') as month_name,
    COUNT(*) as days,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(total_focus_hours), 1) as avg_focus,
    ROUND(AVG(daily_steps), 0) as avg_steps
FROM daily_summary
WHERE  TO_CHAR(date, 'YYYY-MM') <> '2026-02' -- слишком мало данных
GROUP BY month, month_name
ORDER BY month_name;

--- взаимосвязь сна и продуктивности

SELECT 
    CASE 
        WHEN EXTRACT(EPOCH FROM total_sleep)/3600 < 6 THEN 'Меньше 6ч'
        WHEN EXTRACT(EPOCH FROM total_sleep)/3600 BETWEEN 6 AND 7 THEN '6-7ч'
        WHEN EXTRACT(EPOCH FROM total_sleep)/3600 BETWEEN 7 AND 8 THEN '7-8ч'
        WHEN EXTRACT(EPOCH FROM total_sleep)/3600 BETWEEN 8 AND 9 THEN '8-9ч'
        ELSE 'Больше 9ч'
    END as sleep_category,
    COUNT(*) as days,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(total_focus_hours), 1) as avg_focus,
    ROUND(AVG(daily_steps), 0) as avg_steps
FROM daily_summary
GROUP BY sleep_category
ORDER BY days DESC;

--- топ 10 лучших дней


SELECT 
    date,
    mood,
    total_focus_hours,
    daily_steps,
    all_rings_closed
FROM daily_summary
ORDER BY mood DESC, total_focus_hours DESC
LIMIT 10;

--- топ 10 худщих дней

SELECT 
    date,
    mood,
    total_focus_hours,
    daily_steps,
    all_rings_closed
FROM daily_summary
ORDER BY mood ASC, total_focus_hours ASC
LIMIT 10;

--- анализ выбросов

WITH stats AS (
    SELECT 
        AVG(mood) as avg_mood,
        STDDEV(mood) as stddev_mood,
         AVG(efficiency) as avg_efficiency,
        AVG(total_focus_hours) as avg_focus,
        STDDEV(total_focus_hours) as stddev_focus
    FROM daily_summary
)
SELECT 
    d.date,
    d.mood,
      d.efficiency,
    d.total_focus_hours,
    d.daily_steps,
    CASE 
        WHEN d.mood < (s.avg_mood - 2*s.stddev_mood) THEN 'Очень плохой день'
        WHEN d.mood > (s.avg_mood + 2*s.stddev_mood) THEN 'Очень хороший день'
        ELSE 'Нормальный'
    END as day_type
FROM daily_summary d
CROSS JOIN stats s
WHERE d.mood < (s.avg_mood - 2*s.stddev_mood) 
   OR d.mood > (s.avg_mood + 2*s.stddev_mood)
ORDER BY d.mood;

--- скользящее среднее настроения за 7 дней

SELECT 
    date,
    mood,
    ROUND(AVG(mood) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) as mood_7d
FROM daily_summary
ORDER BY date;


-- Влияние на вариабельность пульса 
SELECT 
    w.name,
    COUNT(*) as cnt,
    ROUND(AVG(w.duration), 1) as avg_duration,
    ROUND(AVG(ds_next.efficiency), 1) as avg_efficiency_next_day,
    ROUND(AVG(ds_next.hrv), 0) as avg_hrv_next_day,
    ROUND(AVG(ds_next.hrv) - AVG(ds_day.hrv), 1) as hrv_change,
    ROUND(AVG(ds_next.mood), 2) as avg_mood_next_day
FROM workouts w
LEFT JOIN daily_summary ds_day ON w.date = ds_day.date
LEFT JOIN daily_summary ds_next ON w.date + INTERVAL '1 day' = ds_next.date
WHERE ds_day.hrv IS NOT NULL AND ds_next.hrv IS NOT NULL
GROUP BY w.name
HAVING COUNT(*) > 2  -- исключить редкие тренировки
ORDER BY hrv_change DESC;

--- влияние вредных привычек на показатели

WITH habits AS (
    SELECT 
        date,
        alcohol,
        smoking,
        mood,
        LEAD(mood) OVER (ORDER BY date) as next_mood,
        LEAD(mood) OVER (ORDER BY date) - mood AS mood_effect,
        hrv,
        LEAD(hrv) OVER (ORDER BY date) as next_hrv,
        LEAD(hrv) OVER (ORDER BY date) - hrv AS hrv_effect
    FROM other_metrics
    WHERE alcohol OR smoking
)
SELECT * FROM habits;

-- Влияние эффективности сна на продуктивность

SELECT 
    CASE 
        WHEN efficiency < 70 THEN 'Низкая (<70%)'
        WHEN efficiency BETWEEN 70 AND 85 THEN 'Средняя (70-85%)'
        WHEN efficiency BETWEEN 85 AND 95 THEN 'Хорошая (85-95%)'
        ELSE 'Отличная (>95%)'
    END as efficiency_category,
    COUNT(*) as days,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(total_focus_hours), 1) as avg_focus,
    ROUND(AVG(daily_steps), 0) as avg_steps
FROM daily_summary
GROUP BY efficiency_category
ORDER BY avg_focus DESC;



--- сравнение дней без медитации и дней после медитации


WITH meditation_lag AS (
    SELECT 
        date,
        LAG(meditation) OVER (ORDER BY date) as meditation_yesterday,
        mood,
        hrv,
        total_focus_hours,
        efficiency
    FROM daily_summary
)
SELECT 
    CASE WHEN meditation_yesterday THEN 'meditation day after' ELSE 'no meditation' END,
    COUNT(*) as days,
    ROUND(AVG(hrv), 0) as avg_hrv,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(efficiency), 1) as avg_efficiency
FROM meditation_lag
WHERE meditation_yesterday IS NOT NULL
GROUP BY meditation_yesterday;

--- влияние дневника на метрики

WITH journal_lag AS (
    SELECT 
        date,
        LAG(journal) OVER (ORDER BY date) as journal_yesterday,
        mood,
        hrv,
        total_focus_hours,
        efficiency
    FROM daily_summary
)
SELECT 
    CASE WHEN journal_yesterday THEN 'journal day after' 
         ELSE 'no journal' END as day_type,
    COUNT(*) as days,
    ROUND(AVG(hrv), 0) as avg_hrv,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(total_focus_hours), 1) as avg_focus,
    ROUND(AVG(efficiency), 1) as avg_efficiency
FROM journal_lag
WHERE journal_yesterday IS NOT NULL
GROUP BY journal_yesterday
ORDER BY avg_mood DESC;

--- влияние соц. сетей

SELECT 
    CASE 
        WHEN social_media_hours < INTERVAL '1 hour' THEN '<1h'
        WHEN social_media_hours < INTERVAL '3 hours' THEN '1-3h'
        ELSE '>3h'
    END as social_category,
    COUNT(*) as days,
    ROUND(AVG(hrv), 0) as avg_hrv,
    ROUND(AVG(mood), 2) as avg_mood,
    ROUND(AVG(total_focus_hours), 1) as avg_focus,
    ROUND(AVG(efficiency), 1) as avg_efficiency
FROM daily_summary
WHERE social_media_hours IS NOT NULL
GROUP BY social_category
ORDER BY avg_focus DESC;

