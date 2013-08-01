CREATE TABLE event(id number NOT NULL,
                   title VARCHAR2(50) NOT NULL,
                   start_date DATE NOT NULL,
                   CONSTRAINT PK_EVENT PRIMARY KEY(id)) LOGGING;