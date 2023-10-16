
drop view if exists CarDetails;
CREATE VIEW CarDetails AS
SELECT
    c.carID AS ID,
    CONCAT(c.make, ' ', c.model) AS "Make & Model",
    s.statusName AS Status,
    CONCAT(ct.carTypeName, ' - ', cw.carWheelName) AS "Type - Wheel",
    c.purchaseDate AS PurchaseDate,
    e.userName AS "Managed By",
    c.description AS Description
FROM Car c
JOIN Status s ON c.statusID = s.statusID
JOIN CarType ct ON c.carTypeID = ct.carTypeID
LEFT JOIN CarWheel cw ON c.carWheelID = cw.carWheelID
LEFT JOIN Employee e ON c.managedBy = e.userName;


CREATE OR REPLACE FUNCTION insert_car(
    p_make VARCHAR, 
    p_model VARCHAR, 
    p_type VARCHAR, 
    p_wheel VARCHAR, 
    p_purchasedate DATE, 
    p_description TEXT
) RETURNS text AS $$
DECLARE
    v_cartypeid INT;
    v_carwheelid INT;
   	v_statusid INT;
    v_error_message TEXT;
BEGIN
    -- 检查carType 是否合法，如果不合法抛出异常
    SELECT cartypeid INTO v_cartypeid 
    FROM cartype 
    WHERE carTypeName = p_type;

    IF v_cartypeid IS NULL THEN
        RAISE EXCEPTION 'Invalid car type provided!';
    END IF;

    -- 检查carwheelid 是否合法，如果不合法抛出异常
    SELECT carwheelid INTO v_carwheelid 
    FROM carwheel 
    WHERE carwheelname = p_wheel;

    IF v_carwheelid IS NULL THEN
        RAISE EXCEPTION 'Invalid car wheel provided!';
    END IF;
	
   	-- 获取'New Stock'的id
   	SELECT statusID INTO v_statusid 
    FROM Status 
    WHERE statusName = 'New Stock';
    -- 使用得到的cartypeid和carwheelid更新car表
   INSERT INTO Car (make, model, statusid, cartypeid, carwheelid, purchasedate, managedby, description)
    VALUES(p_make, p_model,v_statusid, v_cartypeid, v_carwheelid, p_purchasedate,null, p_description);

    RETURN 'Success';
EXCEPTION
    WHEN OTHERS then
    	GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RETURN v_error_message;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION search_car_details(search_string TEXT)
RETURNS SETOF CarDetails AS $$
BEGIN
    RETURN QUERY
    SELECT
        * 
    FROM 
        CarDetails c 
    WHERE 
        c.ID IN (
	        SELECT
	            car.carID 
	        FROM Car car
	        LEFT JOIN Status s ON car.statusID = s.statusID
	        LEFT JOIN CarType ct ON car.carTypeID = ct.carTypeID 
	        LEFT JOIN CarWheel cw ON car.carWheelID = cw.carWheelID 
	        LEFT JOIN Employee e ON car.managedBy = e.userName
	        WHERE 
	            (
	                UPPER(car.make) LIKE UPPER('%' || search_string || '%') OR
	                UPPER(car.model) LIKE UPPER('%' || search_string || '%') OR
	                UPPER(s.statusName) LIKE UPPER('%' || search_string || '%') OR
	                UPPER(ct.carTypeName) LIKE UPPER('%' || search_string || '%') OR
	                UPPER(cw.carWheelName) LIKE UPPER('%' || search_string || '%') OR
	                UPPER(CONCAT(e.firstName, ' ', e.lastName)) LIKE UPPER('%' || search_string || '%') OR
	                UPPER(car.description) LIKE UPPER('%' || search_string || '%')
	            )
	            AND car.purchaseDate >= CURRENT_DATE - INTERVAL '15 years'
        )
        ORDER BY
            c."Managed By" IS NULL DESC,
            c.PurchaseDate ASC;
END;
$$ LANGUAGE plpgsql;
