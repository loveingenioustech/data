CREATE TABLE customer(customer_id number NOT NULL,
                   first_name VARCHAR2(50) NOT NULL,
                   last_name VARCHAR2(50) NOT NULL,
                   born_date DATE NOT NULL,
                   update_user_id VARCHAR2(50),
                   update_time DATE,
                   CONSTRAINT PK_CUSTOMER PRIMARY KEY(customer_id)) LOGGING;