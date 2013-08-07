CREATE TABLE EMPLOYEE(ID number NOT NULL,
                   NAME VARCHAR2(255),
                   SALARY NUMBER,
                   update_user_id VARCHAR2(50),
                   update_time DATE,
                   CONSTRAINT PK_EMPLOYEER PRIMARY KEY(ID)) LOGGING;