CREATE TABLE event(id number NOT NULL,
                   title VARCHAR2(50) NOT NULL,
                   title# VARCHAR2(50) NOT NULL,
                   start_date DATE NOT NULL,
                   update_user_id VARCHAR2(50),
                   update_time DATE,
                   CONSTRAINT PK_EVENT PRIMARY KEY(id)) LOGGING;