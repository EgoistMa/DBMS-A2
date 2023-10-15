#!/usr/bin/env python3
import psycopg2

#####################################################
##  Database Connection
#####################################################

'''
Connect to the database using the connection string
'''
def openConnection():
    # connection parameters - ENTER YOUR LOGIN AND PASSWORD HERE
    #userid = "y23s2c9120_tima3723"
    #passwd = "af7HKxEh"
    #myHost = "soit-db-pro-2.ucc.usyd.edu.au"

    userid = "postgres"
    passwd = "pass"
    myHost = "127.0.0.1"

    # Create a connection to the database
    conn = None
    try:
        # Parses the config file and connects using the connect string
        conn = psycopg2.connect(database=userid,
                                    user=userid,
                                    password=passwd,
                                    host=myHost)
    except psycopg2.Error as sqle:
        print("psycopg2.Error : " + sqle.pgerror)
    
    # return the connection to use
    return conn

'''
Validate employee based on username and password
'''
def checkEmployeeCredentials(userName, password):
    conn = openConnection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM employee WHERE username = %s AND password = %s", (userName, password))
    result = cur.fetchone()
    cur.close()
    conn.close()
    return result
    #return ['jswift', '111', 'James', 'Swift', '0422834091', 'jamesswift@hotmail.com', '7 Tesolin Way Westgate QLD']

def getCarsFromResult(result):
    cars = []
    for row in result:
        purchase_date = row[4]
        formatted_date = purchase_date.strftime('%d/%m/%Y')# todo check if we need do a date formating or not? & is that ok to do a software level formating?
        car = {
            "car_id": row[0],
            "makemodel": row[1],  
            "status": row[2],
            "typewheel": row[3],
            "purchasedate": formatted_date,  
            "employee": row[5],
            "description": row[6]  
        }
    cars.append(car)

'''
List all the associated cars in the database by employee
'''
def findCarsByEmployee(userName):
    conn = openConnection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM CarDetails WHERE \"Managed By\" = %s or \"Managed By\" is null order by purchasedate asc,description asc ,status desc", (userName,))
    result = cur.fetchall()
    cur.close()
    conn.close()
    print(result)
    cars = getCarsFromResult(result)

    return cars


'''
Find a list of cars based on the searchString provided as parameter
See assignment description for search specification
'''
def findCarsByCriteria(searchString): #added username for better search 
    conn = openConnection()
    cur = conn.cursor()

    query = """
            select
            * 
            from 
            cardetails c 
            where 
            c.id in (
            SELECT
                car.carid 
                FROM Car car
                LEFT JOIN Status s ON car.statusid = s.statusid
                left join cartype ct on car.cartypeid = ct.cartypeid 
                left join carwheel cw on car.carwheelid = cw.carwheelid 
                left join employee e on car.managedby = e.username
                WHERE 
                    (
                        UPPER(make) LIKE UPPER(%s) OR
                        UPPER(model) LIKE UPPER(%s) OR
                        UPPER(s.statusName) LIKE UPPER(%s) OR
                        UPPER(ct.carTypeName) LIKE UPPER(%s) OR
                        UPPER(cw.carwheelname) LIKE UPPER(%s) OR
                        UPPER(CONCAT(e.firstname, ' ', e.lastname)) LIKE UPPER(%s) OR
                        UPPER(description) LIKE UPPER(%s)
                    )
                    AND car.purchaseDate >= CURRENT_DATE - INTERVAL '15 years'
            )
            ORDER BY
                c."Managed By" IS NULL DESC,
                c.purchaseDate ASC
            ;
            """
    search_pattern = "%" + searchString + "%"  # create a pattern for the LIKE query
    cur.execute(query, (search_pattern, search_pattern, search_pattern, search_pattern, search_pattern, search_pattern, search_pattern))
    result = cur.fetchall()
    
    cur.close()
    conn.close()

    print(result)
    cars = getCarsFromResult(result)
    return cars


'''
Add a new car
'''
def addCar(make, model, type, wheel, purchasedate, description):
    conn = openConnection()
    cur = conn.cursor()

    query = """
            select insert_car(%s,%s,%s,%s,%s,%s);
            """
    
    cur.execute(query, (make, model, type, wheel, purchasedate, description))
    result = cur.fetchone()
    conn.commit()

    cur.close()
    conn.close()

    return result[0] == 'Success'


'''
Update an existing car
'''
def updateCar(carid, make, model, status, type, wheel, purchasedate, employee, description):

    return
