/*
11.For each course, calculate:

	Total number of enrolled users
	Total number of lessons
	Average lesson duration


12.Identify the top three most active users based on total activity count.


13.Calculate course completion percentage per user based on lesson activity.


14.Find users whose average assessment score is higher than the course average.


15.List courses where lessons are frequently accessed but assessments are never attempted.


16.Rank users within each course based on their total assessment score.


17.Identify the first lesson accessed by each user for every course.


18.Find users with activity recorded on at least five consecutive days.


19.Retrieve users who enrolled in a course but never submitted any assessment.


20,List courses where every enrolled user has submitted at least one assessment.
*/


/*11. For each course, calculate:
total number of enrolled users
total number of lessons
average lesson duration*/

SELECT
	c.course_id,
	c.title,
	COUNT(DISTINCT e.user_id) AS total_Enrolled_users,
	COUNT(DISTINCT l.lesson_id) AS total_lessons
FROM lms.Courses c
LEFT JOIN lms.Enrollments e
ON c.course_id = e.course_id
LEFT JOIN lms.Lessons l
ON c.course_id = l.course_id
GROUP BY c.course_id, c.title;


--12. indentify the top three most active users based on total activity count
SELECT TOP 3
    u.user_id,
    u.name,
    u.email,
    COUNT(ua.activity_id) AS Activity_Count
FROM lms.Users u
JOIN lms.UserActivity ua
    ON u.user_id = ua.user_id
GROUP BY 
    u.user_id,
    u.name,
    u.email
ORDER BY Activity_Count DESC;


--13. Calculate course completion percentage per user based on lesson activity

SELECT
    u.user_id,
    u.name,
    c.course_id,
    COUNT(DISTINCT l.lesson_id) AS total_lessons,
    COUNT(DISTINCT ua.lesson_id) AS lessons_completed,
    COALESCE((COUNT(DISTINCT ua.lesson_id) * 100.0)/ NULLIF(COUNT(DISTINCT l.lesson_id),0),0) AS completion_percentage
FROM  lms.Enrollments AS e
JOIN lms.Users AS u
   	ON u.user_id = e.user_id	
JOIN lms.Courses AS c
   	ON c.course_id = e.course_id	
LEFT JOIN lms.Lessons AS l
   	ON l.course_id = c.course_id	
LEFT JOIN lms.UserActivity AS ua
	ON ua.user_id = u.user_id
	AND ua.lesson_id = l.lesson_id
GROUP BY
	u.user_id,
	u.name,
	c.course_id
ORDER BY completion_percentage DESC;
    
--14.Find users whose average assessment score is higher than the course average.
-- CTE's : seperates course average score and user average score for clarity
WITH UserCourseAverage AS (
    SELECT
        s.user_id,
        a.course_id,
        AVG(s.score) AS user_avg_score
    FROM lms.AssessmentSubmission s
    JOIN lms.Assesments a
        ON s.assessment_id = a.assessment_id
    GROUP BY
        s.user_id,
        a.course_id
),
CourseAverage AS (
    SELECT
        a.course_id,
        AVG(s.score) AS course_avg_score
    FROM lms.AssessmentSubmission s
    JOIN lms.Assesments a
        ON s.assessment_id = a.assessment_id
    GROUP BY
        a.course_id
)
SELECT
    u.user_id,
    u.name,
    uca.course_id,
    uca.user_avg_score,
    ca.course_avg_score
FROM UserCourseAverage uca
JOIN CourseAverage ca
    ON uca.course_id = ca.course_id
JOIN lms.Users u
    ON u.user_id = uca.user_id
WHERE uca.user_avg_score > ca.course_avg_score
ORDER BY u.user_id, uca.course_id;


--15. List Courses where lessons are frequently accessed but assesments are never attempted
SELECT
    c.course_id,
    c.title,
    COUNT(DISTINCT ua.activity_id) AS total_lesson_accesses,
    COUNT(DISTINCT s.assessment_id) AS total_assessment_attempts
    FROM lms.Courses c
    JOIN lms.Lessons l
    ON c.course_id = l.lesson_id
    LEFT JOIN lms.UserActivity ua
    ON l.lesson_id = ua.lesson_id
    LEFT JOIN lms.Assesments a
    ON c.course_id = a.course_id
    LEFT JOIN lms.AssessmentSubmission s
    ON
    a.assessment_id = s.assessment_id
    GROUP BY c.course_id, c.title
    HAVING COUNT(DISTINCT ua.activity_id) > 0
    AND COUNT(DISTINCT s.assessment_id) = 0
    

--16.Rank users within each course based on their total assessment score.
--INNER JOIN returns only the matching rows from both the rows
WITH UserScores AS (
    SELECT 
        u.user_id,
        u.name,
        a.course_id,
        SUM(s.score) AS total_score
    FROM lms.AssessmentSubmission s
    JOIN lms.Users u 
    ON s.user_id = u.user_id
    JOIN lms.Assesments a 
    ON s.assessment_id = a.assessment_id
    JOIN lms.Courses c 
    ON a.course_id = c.course_id
    GROUP BY u.user_id, u.name, a.course_id
)
SELECT 
    user_id,
    name,
    course_id,
    total_score,
    RANK() OVER (PARTITION BY course_id ORDER BY total_score DESC) AS rank
FROM UserScores;


--17.Identify the first lesson accessed by each user for every course.
--using CTE to rank the lessons accessed by each user for every course and then filtering to get the first lesson accessed
WITH CTE_Lesson_Accessed AS
(
    SELECT
        u.user_id,
        c.course_id,
        l.lesson_id,
        ua.timestamp,
        RANK() OVER (PARTITION BY u.user_id, c.course_id ORDER BY ua.timestamp) AS Rank
   FROM lms.Users u 
   JOIN lms.UserActivity ua
   ON u.user_id = ua.user_id
   JOIN lms.Lessons l
   ON l.lesson_id = ua.lesson_id
   JOIN lms.Courses c
   ON c.course_id = l.course_id
)

SELECT 
    Ct.user_id,
    Ct.course_id,
    Ct.lesson_id,
    Ct.timestamp
FROM CTE_Lesson_Accessed AS Ct
WHERE Rank =1;

--18.Find users with activity recorded on at least five consecutive days.
WITH UserActivityDates AS (
    SELECT DISTINCT
        ua.user_id,
        CAST(ua.timestamp AS DATE) AS activity_date
    FROM lms.UserActivity ua
),
DateGroups AS (
    SELECT
        user_id,
        activity_date,
        DATEADD(DAY,ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY activity_date), activity_date) AS grp
    FROM UserActivityDates
)
SELECT
    user_id,
    MIN(activity_date) AS start_date,
    MAX(activity_date) AS end_date,
    COUNT(*) AS consecutive_days
FROM DateGroups
GROUP BY user_id, grp
HAVING COUNT(*) >= 5
ORDER BY user_id;

--19.Retrieve users who enrolled in a course but never submitted any assessment.
SELECT 
    u.user_id,
    c.course_id,
    e.enrollment_id,
    s.submission_id
FROM lms.Users u
JOIN lms.Enrollments e
ON u.user_id = e.user_id
JOIN lms.Courses c
ON c.course_id = e.course_id
LEFT JOIN lms.AssessmentSubmission s
ON u.user_id = s.user_id
WHERE s.user_id IS NULL;

--20.List courses where every enrolled user has submitted at least one assessment.
SELECT DISTINCT * 
FROM
(SELECT 
    e.course_id,
    a.assessment_id
FROM lms.Enrollments e
LEFT JOIN lms.Assesments a
ON a.course_id = e.course_id
LEFT JOIN lms.AssessmentSubmission s
ON s.assessment_id = a.assessment_id AND s.user_id = e.user_id
WHERE a.assessment_id IS NOT NULL
)t ;
