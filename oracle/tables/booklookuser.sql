CREATE TABLE booklookuser( user_id number NOT NULL,
                   username VARCHAR2(50) NOT NULL,
                   password VARCHAR2(50) NOT NULL,
                   usertype VARCHAR2(50),
                   CONSTRAINT PK_BOOKLOOKUSER PRIMARY KEY(user_id)) LOGGING; 