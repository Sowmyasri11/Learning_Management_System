

USE LMSDATABASE;

CREATE DATABASE LMSDATABASE;

USE LMSDATABASE;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'lms')
BEGIN
    EXEC('CREATE SCHEMA lms');
END

--Create table Users with attributes user_id , name, email, role, created_at
CREATE TABLE lms.Users(
	user_id INT PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	email VARCHAR(50) NOT NULL UNIQUE,
	role VARCHAR(30) CHECK ( role IN('student','instructor')) 
);

ALTER TABLE lms.Users ALTER COLUMN email VARCHAR(100);


--Create table Courses with attributes course_id, title, description, instructor_id
CREATE TABLE lms.Courses(
	course_id INT PRIMARY KEY,
	title VARCHAR(30) NOT NULL,
	description TEXT,
	instructor_id INT NOT NULL,
	user_id INT NOT NULL ,
	CONSTRAINT fk_user_id
	FOREIGN KEY (user_id) REFERENCES  lms.Users (user_id)
);

--Create table lessons with attributes lesson_id, course_id , title, content, lesson_order
CREATE TABLE lms.Lessons(
	lesson_id INT PRIMARY KEY,
	course_id INT NOT NULL,
	title VARCHAR(30),
	content TEXT,
	lesson_order INT NOT NULL,
	CONSTRAINT fk_lessons_course
    FOREIGN KEY (course_id) REFERENCES lms.Courses(course_id)
);

--Create table Enrollment with attributes enrollment_id, user_id, course_id, enrolled_at, status
CREATE TABLE lms.Enrollments (
    enrollment_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    enrolled_at DATE,
	status VARCHAR(20) CHECK (status IN ('active','inactive')),
    FOREIGN KEY (user_id) REFERENCES lms.Users(user_id),
    FOREIGN KEY (course_id) REFERENCES lms.Courses(course_id)
);

--Create table USER ACTIVITY with attributes activity_id, user_id, lesson_id, activity_type, timestamp
CREATE TABLE lms.UserActivity(
	activity_id INT PRIMARY KEY,
	user_id INT NOT NULL,
	lesson_id INT NOT NULL,
	activity_type VARCHAR(30) NOT NULL,
	timestamp DATETIME2,
	FOREIGN KEY (user_id) REFERENCES lms.Users (user_id),
	FOREIGN KEY (lesson_id) REFERENCES lms.Lessons (lesson_id)
);

--Create table ASSESMENTS with attributes assessment_id, course_id , title, total_marks 
CREATE TABLE lms.Assesments(
	assessment_id INT PRIMARY KEY,
	course_id INT NOT NULL,
	title VARCHAR(200),
	total_marks INT NOT NULL,
	FOREIGN KEY (course_id) REFERENCES lms.Courses(course_id)
);

--Create tbale Assessment_Submission with attributes submission_id, assessment_id, user_id, score, submitted_at
CREATE TABLE lms.AssessmentSubmission(
	submission_id INT PRIMARY KEY,
	assessment_id INT NOT NULL,
	user_id INT NOT NULL,
	score INT NOT NULL,
	submitted_at DATETIME2,
	FOREIGN KEY (assessment_id) REFERENCES lms.Assesments (assessment_id),
	FOREIGN KEY (user_id) REFERENCES lms.Users (user_id)
);
