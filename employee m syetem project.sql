-- create databse
create database emp_db;
use emp_db;
-- drop database emp_db;

-- Table 1: Job Department
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);
-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- Table 3: Employee
CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
        REFERENCES JobDepartment(Job_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Table 4: Qualification
CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    Emp_ID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
        REFERENCES Employee(emp_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Table 5: Leaves
CREATE TABLE Leaves (
    leave_ID INT PRIMARY KEY,
    emp_ID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table 6: Payroll
CREATE TABLE Payroll (
    payroll_ID INT PRIMARY KEY,
    emp_ID INT,
    job_ID INT,
    salary_ID INT,
    leave_ID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

select * from employee;
select * from jobdepartment;
select * from leaves;
select * from qualification;
select * from salarybonus;
select * from Payroll;


## Analysis Questions
-- 1. EMPLOYEE INSIGHTS

-- How many unique employees are currently in the system?
select count(distinct emp_id) 
from employee;

-- Which departments have the highest number of employees?
SELECT jd.jobdept, COUNT(emp_id) AS total_employees
FROM Employee e
join jobdepartment jd
on jd.job_id = e.job_id     
GROUP BY jd.jobdept
ORDER BY total_employees DESC;

-- What is the average salary per department?
select jd.jobdept,avg(sb.amount) as avg_salary
from salarybonus sb
join jobdepartment jd 
on sb.job_id = jd.job_id
group by jd.jobdept;

-- Who are the top 5 highest-paid employees?
select emp.emp_id , emp.firstname, emp.lastname, sb.amount
from employee emp
join jobdepartment jd on jd.job_id = emp.job_id
join salarybonus sb on sb.job_id = jd.job_id
ORDER BY sb.amount DESC
LIMIT 5;

-- What is the total salary expenditure across the company?
select sum(amount) as total_amt
from salarybonus;

-- 2. JOB ROLE AND DEPARTMENT ANALYSIS

-- How many different job roles exist in each department?
select jobdept,count(name) as total_jobdept
from jobdepartment
group by jobdept;

-- What is the average salary range per department?
SELECT jd.jobdept, AVG(sb.amount) AS avg_salary
FROM jobdepartment jd
JOIN salarybonus sb ON jd.job_id = sb.job_id
GROUP BY jd.jobdept;

-- Which job roles offer the highest salary?
select jd.job_id,name, max(sb.amount) as highest_salary
from jobdepartment jd
join salarybonus sb on jd.job_id = sb.job_id
group by jd.job_id , jd.name
order by highest_salary desc
limit 5;

-- Which departments have the highest total salary allocation?
select  jd.jobdept, sum(sb.amount) as total_salary
from jobdepartment jd
join salarybonus sb on jd.job_id = sb.job_id
group by jd.jobdept
order by total_salary desc;

-- 3. QUALIFICATION AND SKILLS ANALYSIS

-- How many employees have at least one qualification listed?
select e.emp_id, e.firstname,e.lastname, count( q.position) as least_one_qualified
from qualification q
join employee e
on e.emp_id = q.emp_id
group by e.emp_id, e.firstname,e.lastname 
order by least_one_qualified desc;

SELECT COUNT(DISTINCT e.emp_id) AS employees_with_qualification
FROM employee e
JOIN qualification q ON e.emp_id = q.emp_id;

-- Which positions require the most qualifications?
select position, Requirements as most_qualification
from qualification q
where Requirements like "%/%";

-- Which employees have the highest number of qualifications?
select e.firstname,e.lastname ,q.position,q.requirements
    from employee e
    join qualification q
    on q.emp_ID = e.emp_ID
    where q.requirements like '%/%';

-- 4. LEAVE AND ABSENCE PATTERNS

-- Which year had the most employees taking leaves?
select year(date),count(distinct emp_id) as most_leaves_emp
from leaves
group by  year(date) 
order by most_leaves_emp desc;

-- What is the average number of leave days taken by its employees per department?
SELECT jd.jobdept, AVG(emp_leaves) AS avg_leave_days
FROM (
    SELECT e.emp_id, COUNT(l.date) AS emp_leaves
    FROM employee e
    JOIN leaves l ON e.emp_id = l.emp_id
    GROUP BY e.emp_id
) AS t
JOIN employee e ON t.emp_id = e.emp_id
JOIN jobdepartment jd ON e.job_id = jd.job_id
GROUP BY jd.jobdept
ORDER BY avg_leave_days DESC;


-- Which employees have taken the most leaves?
select e.firstname , e.lastname ,count(l.date)  as most_leave_emp
from employee e 
join leaves l
on e.emp_id = l.emp_id
group by e.emp_id
order by most_leave_emp desc;

-- What is the total number of leave days taken company-wide?
SELECT SUM(leave_count) as total_leave_days
from (
select e.emp_id, count(*) as leave_count
from leaves l
join employee e
on e.emp_id = l.emp_id
group by e.emp_id)as t;


-- How do leave days correlate with payroll amounts?
SELECT e.emp_id, e.firstname, e.lastname, COUNT(l.date) AS leave_days, sb.amount AS salary_amount
FROM employee e
LEFT JOIN leaves l 
       ON e.emp_id = l.emp_id
JOIN jobdepartment jd 
       ON e.job_id = jd.job_id
JOIN salarybonus sb 
       ON jd.job_id = sb.job_id
GROUP BY e.emp_id, e.firstname, e.lastname, sb.amount
ORDER BY leave_days DESC;


-- 5. PAYROLL AND COMPENSATION ANALYSIS

--  What is the total monthly payroll processed? 
select report, sum(total_amount) as monthly_payroll
from payroll
group by report;

-- What is the average bonus given per department?
select jd.jobdept, avg(s.bonus) as avg_bonus 
from salarybonus s
join jobdepartment jd
on jd.job_id= s.job_id
group by jd.jobdept;

-- Which department receives the highest total bonuses?
select jd.jobdept, max(bonus) as high_bonus
from salarybonus s
join jobdepartment jd
on jd.job_id= s.job_id
group by jd.jobdept
order by high_bonus desc
limit 1;

-- What is the average value of total_amount after considering leave deductions?
SELECT AVG(final_salary) AS avg_salary_after_deductions
FROM (
    SELECT e.emp_id,
           sb.amount - (COUNT(l.date) * (sb.amount / 30)) AS final_salary
    FROM employee e
    JOIN jobdepartment jd ON e.job_id = jd.job_id
    JOIN salarybonus sb ON jd.job_id = sb.job_id
    LEFT JOIN leaves l ON e.emp_id = l.emp_id
    GROUP BY e.emp_id, sb.amount
) AS t;
