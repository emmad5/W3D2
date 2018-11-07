DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS questions_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions_likes;
PRAGMA foreign_keys = ON; 

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE questions_follows (
  user_id INTEGER,
  questions_id INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (questions_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY, 
  questions_id INTEGER NOT NULL, 
  parent_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES replies(id), 
  FOREIGN KEY (questions_id) REFERENCES questions(id), 
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE questions_likes (
  id INTEGER PRIMARY KEY, 
  user_id INTEGER,
  questions_id INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (questions_id) REFERENCES questions(id) 
); 

INSERT INTO 
  users(fname, lname)
  VALUES 
  ('Mikey', 'Sanders'),
  ('Joe', 'Miller'),
  ('Liz', 'Jones');
  
INSERT INTO 
  questions(title, body, author_id)
  VALUES
    ('SQL', 'What is SQL?', (SELECT id FROM users WHERE fname = 'Mikey')),
    ('Ruby', 'What is Ruby?', (SELECT id FROM users WHERE fname = 'Joe')), 
    ('Rails', 'What is Rails?', (SELECT id FROM users WHERE fname = 'Liz')); 
    
INSERT INTO 
  replies(questions_id, parent_id, user_id, body)
  VALUES 
    (1, null, 1, 'NED NED NED'),
    (2, 1, 2, 'TOM TOM TOM'); 
    
INSERT INTO 
  questions_follows(user_id, questions_id)
  VALUES
    (1, 2),
    (2, 1); 
    
    
    
