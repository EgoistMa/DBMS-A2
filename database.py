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
    #userid = "y23s2c9120_unikey"
    #passwd = ""
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


'''
List all the associated cars in the database by employee
'''
def findCarsByEmployee(userName):
    conn = openConnection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM car C WHERE C.managedby = %s", (userName,))
    result = cur.fetchall()
    cur.close()
    conn.close()
    print(result)
    return [(6,'kia',1,2,'10/10/2023','jswift','desc')]
    #return [(6, 'Kia', 'Sportage', 2, 2, 3, '10/10/2023', 'jswift', 'Fusing a long, extremely athletic body with an unstoppable attitude, the redesigned Sportage is the new benchmark medium SUV.')]
    #return [(6,6,6,6,6,6,6)]
    return result


'''
Find a list of cars based on the searchString provided as parameter
See assignment description for search specification
'''
def findCarsByCriteria(searchString):

    return


'''
Add a new car
'''
def addCar(make, model, type, wheel, purchasedate, description):

    return


'''
Update an existing car
'''
def updateCar(carid, make, model, status, type, wheel, purchasedate, employee, description):

    return
