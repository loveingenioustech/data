CREATE TABLE book( isbn VARCHAR2(50) NOT NULL,
                   name VARCHAR2(50) NOT NULL,
                   publish_date DATE NOT NULL,
                   update_user_id VARCHAR2(50),
                   update_time DATE,
                   CONSTRAINT PK_BOOK PRIMARY KEY(isbn)) LOGGING;