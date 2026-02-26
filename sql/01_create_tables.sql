CREATE TABLE active_energy (
    id SERIAL PRIMARY KEY,
	date DATE NOT NULL,
	value DECIMAL
	);

CREATE TABLE active_rings (
	id SERIAL PRIMARY KEY,
	date DATE NOT NULL UNIQUE,
	active_energy DECIMAL(6,2),
	active_energy_goal INTEGER,
	exercise_minutes INTEGER,
	exercise_minutes_goal INTEGER,
	stand_hours INTEGER,
	stand_hours_goal INTEGER
	);
	
CREATE TABLE exercise_time (
	id SERIAL PRIMARY KEY,
	date DATE NOT NULL,
	value INTEGER,
	start_time TIMESTAMP,
	end_time TIMESTAMP 
	);

CREATE TABLE heart_rate (
	id SERIAL PRIMARY KEY,
	date DATE NOT NULL,
	value INTEGER, 
	start_time TIMESTAMP NOT NULL
	);

CREATE TABLE steps (
	id SERIAL PRIMARY KEY, 
	date DATE NOT NULL,
	value INTEGER 
	);

CREATE TABLE workouts (
	id SERIAL PRIMARY KEY, 
	date DATE NOT NULL,
	name TEXT,
	duration DECIMAL(5,2),
	start_time DATE NOT NULL,
	end_time DATE NOT NULL 
	);
	
CREATE TABLE sleep (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    bedtime TIMESTAMP,
    wake_time TIMESTAMP,
    time_in_bed INTERVAL,
    awake_time INTERVAL,
    sessions INTEGER,
    total_sleep INTERVAL,
    efficiency DECIMAL(5,1),
    quality INTERVAL,
    deep_sleep INTERVAL,
    heart_rate_sleep DECIMAL(5,1),
    heart_rate_wake DECIMAL(5,1)
);

CREATE TABLE forest_productivity (
	id SERIAL PRIMARY KEY, 
	start_time TIMESTAMP NOT NULL,
	end_time TIMESTAMP NOT NULL, 
	tag VARCHAR(200)
);

CREATE TABLE other_metrics (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    mood DECIMAL(2,1) CHECK (mood >= 1 AND mood <= 5),  
    weather_sunny BOOLEAN,
    social_media_hours INTERVAL,  
    hrv INTEGER,
    offline_communication BOOLEAN,
    alcohol BOOLEAN,
    smoking BOOLEAN,
    journal BOOLEAN,
    meditation BOOLEAN
);

CREATE INDEX idx_active_energy_date ON active_energy(date);
CREATE INDEX idx_heart_rate_date ON heart_rate(date);
CREATE INDEX idx_workouts_date ON workouts(date);
CREATE INDEX idx_forest_start ON forest_productivity(start_time);
CREATE INDEX idx_forest_tag ON forest_productivity(tag);
CREATE INDEX idx_steps_date ON steps(date);
CREATE INDEX idx_other_metrics_date ON other_metrics(date),
CREATE INDEX idx_daily_summary_date ON daily_summary(date);
CREATE INDEX idx_daily_summary_mood ON daily_summary(mood)
	
