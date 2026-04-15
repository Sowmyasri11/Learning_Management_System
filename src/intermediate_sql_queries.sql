/*
Section 1: Intermediate SQL Queries
1.List all users who are enrolled in more than three courses.


2.Find courses that currently have no enrollments.


3.Display each course along with the total number of enrolled users.


4.Identify users who enrolled in a course but never accessed any lesson.


5.Fetch lessons that have never been accessed by any user.


6.Show the last activity timestamp for each user.


7.List users who submitted an assessment but scored less than 50 percent of the maximum score.


8.Find assessments that have not received any submissions.


9.Display the highest score achieved for each assessment.


10.Identify users who are enrolled in a course but have an inactive enrollment status.
*/


-- 1.List all users who are enrolled in more than three courses.

SELECT
	u.user_id,
	u.name,
	COUNT(c.course_id) AS course_count
FROM lms.Users u
LEFT JOIN lms.Courses c 
ON u.user_id = c.user_id
GROUP BY u.user_id, u.name
HAVING COUNT(c.course_id) > 3;


-- 2.Find courses that currently have no enrollments.
SELECT
	c.course_id,
	c.title,
	e.enrollment_id,
	e.course_id
FROM lms.Courses c
LEFT JOIN lms.Enrollments e
ON c.course_id = e.course_id
WHERE e.course_id IS NULL;


-- 3.Display each course along with the total number of enrolled users.
SELECT
	c.course_id,
	c.title,
	COUNT(e.user_id) AS enrolled_users
FROM lms.Courses c
LEFT JOIN lms.Enrollments e
ON c.course_id = e.course_id
GROUP BY c.course_id, c.title;


-- 4.Identify users who enrolled in a course but never accessed any lesson.
SELECT DISTINCT
    u.user_id,
    u.name,
    u.email,
    e.course_id
FROM lms.Users u
JOIN lms.Enrollments e
ON u.user_id = e.user_id
LEFT JOIN lms.Lessons l
ON e.course_id = l.course_id
LEFT JOIN lms.UserActivity ua
ON ua.lesson_id = l.lesson_id
AND ua.user_id = u.user_id
WHERE ua.activity_id IS NULL;



-- 5.Fetch lessons that have never been accessed by any user.
SELECT 
	l.lesson_id,
	l.course_id,
	l.title
FROM lms.Lessons l
LEFT JOIN lms.UserActivity ua
ON l.lesson_id = ua.lesson_id
WHERE ua.lesson_id IS NULL;

-- 6.Show the last activity timestamp for each user.
SELECT
	u.user_id,
	u.name,
	MAX(ua.timestamp) AS last_activity
FROM lms.Users u
LEFT JOIN lms.UserActivity ua
ON u.user_id = ua.user_id
GROUP BY u.user_id, u.name;


-- 7. List users who submitted an assessment but scored less than 50 percent of the maximum score.
SELECT
	u.user_id,
	u.name,
	s.assessment_id,
	s.score,
	a.total_marks
FROM lms.Users u
JOIN lms.AssessmentSubmission s
ON u.user_id = s.user_id
JOIN
lms.Assesments a
ON a.assessment_id = s.assessment_id
WHERE s.score < 0.5 * a.total_marks;



-- 8.Find assessments that have not received any submissions.

/* LEFT JOIN ensures all assessments are considered, including those that may never have been attempted.
WHERE s.assessment_id IS NULL : Filters the assessments that have no submissions*/
SELECT 
	a.assessment_id,
	a.course_id,
	a.title,
	a.total_marks
FROM lms.Assesments a
LEFT JOIN lms.AssessmentSubmission s
ON a.assessment_id = s.assessment_id
WHERE s.assessment_id IS NULL ;

--9.Display the highest score achieved for each assessment.

--MAX(score) : returns the highest score for each assessment
SELECT 
	assessment_id,
	MAX(score) AS Highest_score
FROM lms.AssessmentSubmission
GROUP BY assessment_id
ORDER BY assessment_id;

--10.Identify users who are enrolled in a course but have an inactive enrollment status.

/* INNER JOIN returns only the users who are enrolled in a course
WHERE e.status = 'inactive' : Filters users who's status is inactive*/
SELECT 
	u.user_id,
	u.name,
	u.email,
	e.enrollment_id,
	e.status
FROM lms.Users u
JOIN lms.Enrollments e
ON e.user_id = u.user_id
WHERE e.status = 'inactive';
