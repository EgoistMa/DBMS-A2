
CREATE OR REPLACE VIEW CarDetails AS
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
    p_make VARCHAR(30), 
    p_model VARCHAR(30), 
    p_type VARCHAR(10), 
    p_wheel VARCHAR(10), 
    p_purchasedate DATE, 
    p_description VARCHAR(400)
) RETURNS text AS $$
DECLARE
    v_cartypeid INT;
    v_carwheelid INT;
   	v_statusid INT;
    v_error_message VARCHAR(400);
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
    -- 更新car表
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


CREATE OR REPLACE FUNCTION update_car(
    p_carID INT,
    p_make VARCHAR(30),
    p_model VARCHAR(30),
    p_status VARCHAR(20),
    p_type VARCHAR(10),
    p_wheel VARCHAR(10),
    p_purchaseDate DATE,
    p_employee VARCHAR(20),
    p_description VARCHAR(400)
)
RETURNS VARCHAR AS $$
DECLARE
    v_statusID INT;
    v_typeID INT;
    v_wheelID INT := NULL;
    v_employee VARCHAR(20) := NULL;
   	v_description VARCHAR(400) := NULL;
BEGIN

    -- 检查statusName 是否合法，如果不合法抛出异常
    SELECT statusID INTO v_statusID FROM Status WHERE statusName = p_status;
    IF v_statusID IS NULL THEN
        RETURN 'Invalid status provided: ' || p_status;
    END IF;

    -- 检查carTypeName 是否合法，如果不合法抛出异常
    SELECT carTypeID INTO v_typeID FROM CarType WHERE carTypeName = p_type;
    IF v_typeID IS NULL THEN
        RETURN 'Invalid type provided: ' || p_type;
    END IF;
   
   -- 检查carWheelName是否不为空 且 是否合法，如果空则为null 不合法抛出异常
   	IF p_wheel IS NOT NULL AND p_wheel <> '' THEN
        SELECT carWheelID INTO v_wheelID FROM CarWheel WHERE carWheelName = p_wheel;
        IF v_wheelID IS NULL THEN
            RETURN 'Invalid wheel provided: ' || p_wheel;
        END IF;
    END IF;
	-- 检查employee是否不为空 且 是否合法，如果空则为null 不合法抛出异常
    IF p_employee IS NOT NULL AND p_employee <> '' THEN
        SELECT userName INTO v_employee FROM Employee WHERE username = p_employee;
        IF v_employee IS NULL THEN
            RETURN 'Invalid employee provided: ' || p_employee;
        END IF;
    END IF;
   -- 检查description是否不为空，如果空则为null
   IF p_description IS NOT NULL AND p_description <> '' THEN
        v_description := p_description;
   END IF;
    -- 更新car表
    UPDATE Car
    SET 
        make = p_make,
        model = p_model,
        statusID = v_statusID,
        carTypeID = v_typeID,
        carWheelID = v_wheelID,
        purchaseDate = p_purchaseDate,
        managedBy = v_employee,
        description = v_description
    WHERE carID = p_carID;

    RETURN 'Success';

EXCEPTION 
    WHEN OTHERS THEN
        RETURN 'An unexpected error occurred: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;
