
CREATE OR REPLACE VIEW CarDetails AS
SELECT
    c.carID AS ID,
    CONCAT(c.make, ' ', c.model) AS "Make & Model",
    s.statusName AS Status,
    
    CASE
        WHEN cw.carWheelName IS NULL THEN ct.carTypeName
        ELSE CONCAT(ct.carTypeName, ' - ', cw.carWheelName)
    END AS "Type - Wheel", 
    
    /*CONCAT(ct.carTypeName, ' - ', cw.carWheelName) AS "Type - Wheel",*/
    c.purchaseDate AS PurchaseDate,
    /*CASE
        WHEN e.userName IS NULL THEN ''
        ELSE CONCAT(e.firstName, ' ', e.lastName)   
    END AS "Managed By", */
    case
	    when e.userName is null then '' 
	    else CONCAT(e.firstName, ' ', e.lastName)
	end as "Managed By",
    CASE
        WHEN c.description IS NULL THEN ''
        ELSE c.description   
    END AS Description, 
    --c.description AS Description,
    e.userName AS "M"
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
    v_carwheelid INT:= NULL;
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

    --IF v_carwheelid IS NULL THEN
        --RAISE EXCEPTION 'Invalid car wheel provided!';
    --END IF;
	
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
begin
	
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
    --ELSE
        --v_wheelID := ''; -- Set v_wheelID to an empty string
    END IF;
   
	--检查p_employee
	if p_employee is not null and p_employee <> '' then --当有输入值时
		--把输入值默认当作username， 如果username存在，则更新varible
		if lower(p_employee)  in (select username from employee) then
			select lower(p_employee) into v_employee;
		end if;
		--把检查输入值是否为firstname = lastname 的形式， 如果是， 获取用户username后更新varible
		if p_employee in (select CONCAT(e.firstName, ' ', e.lastName) from employee e) then
			select username into v_employee from employee e where p_employee = CONCAT(e.firstName, ' ', e.lastName);
		end if;
	
		if v_employee is null then
			return  'Invalid employee provided:' || p_employee || v_employee;
		end if;
	--默认为null
	end if;

    -- 检查description是否不为空，如果空则为null
    IF p_description IS NOT NULL AND p_description <> '' THEN
            v_description := p_description;
    END IF;
   
	update car
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

	return 'success';
EXCEPTION 
    WHEN OTHERS THEN
        RETURN 'An unexpected error occurred: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;
