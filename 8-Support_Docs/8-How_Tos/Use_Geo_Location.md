# How to use Geo Location (LINESTRING SRID 4326 & POINT SRID 4326)

We have used `LINESTRING SRID 4326` & `POINT SRID 4326` for storing geo location in the database.

## LINESTRING SRID 4326
`LINESTRING SRID 4326` is used for storing a line string of a polygon.

### Example
```sql
Table - `tpt_route`
"route_geometry" LINESTRING SRID 4326 DEFAULT NULL,
```

## POINT SRID 4326
`POINT SRID 4326` is used for storing a point of a polygon.

### Example
```sql
Table - `tpt_stop`
"stop_geometry" POINT SRID 4326 DEFAULT NULL,
```
---
Using spatial data types like POINT and LINESTRING is a smart move for a Transport Module. It allows you to perform powerful geographic calculations (like finding the distance between a student's home and a bus stop) directly within your database.

The **SRID 4326** refers to the WGS 84 coordinate system, which is the global standard used by GPS and Google Maps.

### 1. Working with the POINT Field

The location field in your tpt_pickup_points table stores a single geographic coordinate.

#### How to Insert Data
To insert data, you use the ST_GeomFromText function. Important: In MySQL 8.0+ with SRID 4326, the standard axis order is (Latitude, Longitude).

```sql
INSERT INTO tpt_pickup_points 
(shift_id, code, name, latitude, longitude, location, stop_type) 
VALUES 
(1, 'STOP_001', 'Green Valley Plaza', 28.6139, 77.2090, 
 ST_GeomFromText('POINT(28.6139 77.2090)', 4326), 'Both');
```
#### How to Select Data
Since spatial data is stored in a binary format, you need functions to make it readable.

To get the WKT (Well-Known Text) format:

```sql
SELECT name, ST_AsText(location) FROM tpt_pickup_points;
-- Result: POINT(28.6139 77.2090)
```

#### How to get Latitude and Longitude individually:
```sql
SELECT name, ST_X(location) AS lat, ST_Y(location) AS lng FROM tpt_pickup_points;
-- Result: lat = 28.6139, lng = 77.2090
```

### 2. Working with the LINESTRING Field
The route_geometry in tpt_route stores the path of the bus as a series of points connected by straight lines.

#### How to Insert Data
You provide a comma-separated list of points that define the path.

```sql
INSERT INTO tpt_route 
(code, name, shift_id, route_geometry, pickup_drop) 
VALUES 
('R_RED_01', 'Route 1 - North Side', 1, 
 ST_GeomFromText('LINESTRING(28.6139 77.2090, 28.6200 77.2100, 28.6300 77.2200)', 4326), 
 'Pickup');
```

#### How to Select Data
To get the full path for a Map API (like Google Maps):

```sql
SELECT name, ST_AsText(route_geometry) FROM tpt_route WHERE code = 'R_RED_01';
-- Result: LINESTRING(28.6139 77.2090, 28.6200 77.2100, 28.6300 77.2200)
```

#### To calculate the total length of the route (in meters):

```sql
SELECT name, ST_Distance_Sphere(ST_StartPoint(route_geometry), ST_EndPoint(route_geometry)) as straight_line_dist 
FROM tpt_route;
-- Result: straight_line_dist = 300
```

### 3. Advanced Query Examples
Here are some real-world scenarios for your School ERP:

#### A. Find the distance between two Pickup Points
If you want to know how far "Stop A" is from "Stop B" in meters:

```sql
SELECT ST_Distance_Sphere(p1.location, p2.location) AS distance_in_meters
FROM tpt_pickup_points p1, tpt_pickup_points p2
WHERE p1.code = 'STOP_001' AND p2.code = 'STOP_002';
-- Result: distance_in_meters = 300
```

#### B. Find stops near a Student’s Location
If a student lives at (28.6150, 77.2110), find all stops within 500 meters:

```sql
SELECT name, ST_Distance_Sphere(location, ST_GeomFromText('POINT(28.6150 77.2110)', 4326)) AS dist
FROM tpt_pickup_points
WHERE ST_Distance_Sphere(location, ST_GeomFromText('POINT(28.6150 77.2110)', 4326)) <= 500
ORDER BY dist ASC;
-- Result: name = 'Green Valley Plaza', dist = 300
```

#### C. Check if a stop lies on a specific Route path

```sql
SELECT r.name AS route_name, p.name AS stop_name
FROM tpt_route r
JOIN tpt_pickup_points p
WHERE ST_Contains(ST_Buffer(r.route_geometry, 0.0001), p.location); 
-- Note: ST_Buffer is used because points rarely sit "perfectly" on a line due to precision.
```

#### Pro-Tips for your ERP

Frontend Integration: When sending this data to a frontend (like Leaflet or Google Maps), your API should ideally convert the POINT and LINESTRING into GeoJSON format using ST_AsGeoJSON(location).

Performance: You have already added SPATIAL INDEX, which is excellent. This will keep your proximity queries fast even with thousands of stops.

Validation: Always ensure your coordinates are valid. Latitude must be between -90 and 90; Longitude between -180 and 180.

## how to write a query that generates the full sequence of stops for a specific route, ordered by their ordinal position

To get a clear itinerary for a specific bus route, you need to join your junction table with the pickup points table. This is essential for generating route lists for drivers or displaying the path on a student's mobile app.

### Query: Fetch Ordered Stops for a Specific Route
This query retrieves all stops for a given route_id, ordered by their sequence (ordinal), and extracts the coordinates in a format ready for your frontend.

#### Query: Fetch Ordered Stops for a Specific Route
This query retrieves all stops for a given route_id, ordered by their sequence (ordinal), and extracts the coordinates in a format ready for your frontend.

```sql
SELECT 
    jnt.ordinal,
    p.name AS stop_name,
    p.code AS stop_code,
    ST_X(p.location) AS latitude,
    ST_Y(p.location) AS longitude,
    jnt.arrival_time,
    jnt.departure_time,
    jnt.pickup_drop_fare,
    ST_AsGeoJSON(p.location) AS location_geojson
FROM 
    tpt_pickup_points_route_jnt jnt
JOIN 
    tpt_pickup_points p ON jnt.pickup_point_id = p.id
WHERE 
    jnt.route_id = 1  -- Replace with your actual Route ID
    AND jnt.is_active = 1
ORDER BY 
    jnt.ordinal ASC;
```

#### Why this query is important for your ERP:
ordinal: Ensures the bus stops are listed in the correct order (e.g., Stop 1 -> Stop 2 -> School).

ST_X & ST_Y: Directly gives you the numeric Latitude and Longitude to pass to Google Maps or Leaflet markers.

ST_AsGeoJSON: If you are building a web/mobile app, many mapping libraries prefer data in GeoJSON format.

is_active: Ensures you don't show inactive stops in your itinerary.

arrival_time & departure_time: Useful for drivers to know when to pick up or drop off students.

pickup_drop_fare: If you charge different fares for pickups vs drops.

#### Pro-Tip: Generating the Full Route Path
If you want to draw the actual road path (the LINESTRING) along with the markers for the stops, you can run a separate simple query for the route metadata:

SELECT 
    name AS route_name,
    ST_AsText(route_geometry) AS path_wkt,
    ST_AsGeoJSON(route_geometry) AS path_geojson
FROM 
    tpt_route
WHERE 
    id = 1;

#### Important Points for Implementation
When you integrate this into your backend code (Node.js, PHP, or Python):

Frontend: Use the location_geojson from the first query to place Markers.

Frontend: Use the path_geojson from the second query to draw the Polyline (the actual line of the road).

Data Integrity: Since you have latitude and longitude as separate columns in tpt_pickup_points, consider using a Database Trigger. This way, whenever someone updates the decimal columns, the POINT field updates automatically.

#### Better let' use Triger to update
This is a great practice for data integrity. By using a trigger, your backend developers don't have to worry about manually calculating the POINT field every time they save a stop. They just update the decimal latitude and longitude, and the database handles the rest.

We need two triggers: one for inserting new stops and one for updating existing ones.
**1. The Insert Trigger**
This ensures that when a new pickup point is added, the location field is populated automatically.

```sql
DELIMITER //

CREATE TRIGGER trg_pickup_points_before_insert
BEFORE INSERT ON tpt_pickup_points
FOR EACH ROW
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        SET NEW.location = ST_GeomFromText(
            CONCAT('POINT(', NEW.latitude, ' ', NEW.longitude, ')'), 
            4326
        );
    END IF;
END //

DELIMITER ;
```

2. The Update Trigger
This ensures that if a user changes the latitude or longitude of an existing stop, the spatial location field stays in sync.

```sql
DELIMITER //

CREATE TRIGGER trg_pickup_points_before_update
BEFORE UPDATE ON tpt_pickup_points
FOR EACH ROW
BEGIN
    -- Only update location if latitude or longitude has actually changed
    IF NEW.latitude <> OLD.latitude OR NEW.longitude <> OLD.longitude THEN
        IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
            SET NEW.location = ST_GeomFromText(
                CONCAT('POINT(', NEW.latitude, ' ', NEW.longitude, ')'), 
                4326
            );
        END IF;
    END IF;
END //

DELIMITER ;

```

**Why use DELIMITER //?**
In SQL, the semicolon (;) normally ends a command. Since a trigger contains multiple lines with semicolons, we use DELIMITER // to tell MySQL: "Don't stop until you see //." This allows the entire trigger block to be sent to the server as one unit.

**Benefits for your School ERP:**
Reduced Human Error: You don't have to remember to update two different formats of the same data in your application code.

Legacy Support: If you have older parts of your application that only understand decimals, they can still update the coordinates, and the "Smart" spatial features (like distance calculation) will still work perfectly.

Efficiency: The BEFORE UPDATE trigger checks if the values actually changed before doing the math, which saves processing power.

Important Note on SRID 4326 Axis Order
As we discussed, MySQL 8.0+ uses (Latitude, Longitude) for SRID 4326.

Correct: POINT(28.6139 77.2090)

Common Mistake: POINT(77.2090 28.6139) (Longitude first) If your maps appear in the middle of the ocean or Antarctica, it’s almost always because the Latitude and Longitude were swapped!

### If you want to write a Stored Procedure that calculates the total distance of a route by summing up the distances between all its sequential pickup points

Calculating the total distance of a route is essential for fuel budgeting and estimating travel times. While your tpt_route table has a route_geometry field, calculating the distance based on the actual sequence of pickup points is often more accurate for operational planning.The total distance $D$ is the sum of the distances between each consecutive pair of points:

$$D = \sum_{i=1}^{n-1} \text{dist}(P_i, P_{i+1})$$

Here is a stored procedure that iterates through the stops of a specific route in their ordinal order and calculates the cumulative distance.

```sql
DELIMITER //
DELIMITER //

CREATE PROCEDURE sp_update_route_total_distance(IN p_route_id BIGINT UNSIGNED)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE current_loc POINT;
    DECLARE prev_loc POINT DEFAULT NULL;
    DECLARE total_dist DOUBLE DEFAULT 0;
    
    -- Cursor to fetch point locations in order of the route itinerary
    DECLARE cur CURSOR FOR 
        SELECT p.location 
        FROM tpt_pickup_points_route_jnt jnt
        JOIN tpt_pickup_points p ON jnt.pickup_point_id = p.id
        WHERE jnt.route_id = p_route_id AND jnt.is_active = 1
        ORDER BY jnt.ordinal ASC;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO current_loc;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- If this is not the first stop, calculate distance from the previous stop
        IF prev_loc IS NOT NULL THEN
            -- ST_Distance_Sphere returns distance in meters
            SET total_dist = total_dist + ST_Distance_Sphere(prev_loc, current_loc);
        END IF;

        SET prev_loc = current_loc;
    END LOOP;

    CLOSE cur;

    -- Update the route table (converting meters to kilometers)
    UPDATE tpt_route 
    SET description = CONCAT('Calculated Distance: ', ROUND(total_dist / 1000, 2), ' KM')
    WHERE id = p_route_id;

    -- Optionally return the value
    SELECT ROUND(total_dist / 1000, 2) AS total_distance_km;

END //

DELIMITER ;

```

#### Key Technical Details
ST_Distance_Sphere: This is a high-performance function that treats the Earth as a perfect sphere. For school bus routes (which are relatively short), this is extremely accurate. It returns results in meters.

The Cursor: We use a cursor to "walk" through the stops one by one. This is necessary because spatial calculations need to happen between the current row and the previous row in a specific sequence.

Performance: Since you have a SPATIAL INDEX on the location field, these geometric calculations are very fast.

How to use it
Whenever a route is modified (stops added or removed), you can simply call this procedure in your backend:

```sql
CALL sp_update_route_total_distance(1);
```

#### Pro-Tip for your ERP
You can automate this even further! You could create a Trigger on the tpt_pickup_points_route_jnt table so that every time a stop is added to a route, this procedure runs automatically to keep the route distance up to date.

Would you like me to show you how to write a query that calculates the Estimated Arrival Time (ETA) for each stop based on an average bus speed?

