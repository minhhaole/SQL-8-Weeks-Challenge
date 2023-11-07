/* Clean Data */ 

-- customer_orders table: clean exclusions and extras columns

UPDATE customer_orders
SET
	exclusions = CASE
		WHEN exclusions = ' ' THEN NULL
		ELSE exclusions 
	END,
	extras = CASE
		WHEN extras = ' ' THEN NULL 
        ELSE extras 
	END;

SELECT * FROM pizza_runner.customer_orders;

--  runner_orders table: clean pickup_time, distance, duration and cancellation. then alter data type

UPDATE runner_orders
SET
	pickup_time = CASE
		WHEN pickup_time = ' ' THEN NULL
        ELSE pickup_time 
	END,
    distance = CASE
		WHEN distance = '' THEN NULL
        WHEN distance LIKE '%km' THEN REPLACE(distance, 'km', '')
        ELSE distance
	END,
  duration = CASE
		WHEN duration LIKE '%minutes' THEN REPLACE(duration, 'minutes', '')
		WHEN duration LIKE '%minute' THEN REPLACE(duration, 'minute', '')
		WHEN duration LIKE '%mins' THEN REPLACE(duration, 'mins', '') 
		ELSE duration
  END,
	cancellation = CASE
		WHEN cancellation = '' THEN NULL
        ELSE cancellation 
    END;

ALTER TABLE runner_orders
MODIFY COLUMN pickup_time DATETIME,
MODIFY COLUMN distance FLOAT,
MODIFY COLUMN duration INT; 

SELECT * FROM pizza_runner.runner_orders;