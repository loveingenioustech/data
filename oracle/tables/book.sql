/*
CREATE TABLE book( isbn VARCHAR2(50) NOT NULL,
                   name VARCHAR2(50) NOT NULL,
                   publish_date DATE NOT NULL,
                   update_user_id VARCHAR2(50),
                   update_time DATE,
                   CONSTRAINT PK_BOOK PRIMARY KEY(isbn)) LOGGING;
*/
CREATE TABLE book( book_id number NOT NULL,
                   catalog VARCHAR2(50) NOT NULL,
                   title VARCHAR2(50) NOT NULL,
                   author VARCHAR2(50),
                   copyright number,
                   binding VARCHAR2(50),
                   CONSTRAINT PK_BOOK PRIMARY KEY(book_id)) LOGGING; 