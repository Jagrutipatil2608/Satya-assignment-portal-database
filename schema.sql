--1.USERS TABLE--

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT CHECK (role IN('student','teacher','admin')) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

--2.CLASSES TABLE--

CREATE TABLE classes(
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  teacher_id INT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

--3.ASSIGNMENTS TABLE--

CREATE TABLE assignments(
  id SERIAL PRIMARY KEY,
  class_id INT REFERENCES classes(id),
  title TEXT NOT NULL,
  description TEXT,
  deadline TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

--4.SUBMISSIONS TABLE--

CREATE TABLE submissions(
  id SERIAL PRIMARY KEY,
  assignment_id INT REFERENCES assignments(id),
  student_id INT REFERENCES users(id),
  file_url TEXT,
  extracted_text TEXT,
  ai_score DECIMAL(5,2),
  plagiarism_score DECIMAL(5,2),
  risk_level TEXT CHECK(risk_level IN ('low','medium','high')),
  grade TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

--5.updated_at TIMESTAMP--

ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE classes ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE assignments ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE submissions ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();

--6.SOFT DELETE--

ALTER TABLE users ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE classes ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE assignments ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE submissions ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

--7.INDEXES--

CREATE INDEX ON users(email);
CREATE INDEX ON users(name);
CREATE INDEX ON users(role);
CREATE INDEX ON users(is_deleted);
CREATE INDEX ON classes(teacher_id);
CREATE INDEX ON classes(name);
CREATE INDEX ON classes(is_deleted);
CREATE INDEX ON assignments(class_id);
CREATE INDEX ON assignments(deadline);
CREATE INDEX ON assignments(is_deleted);
CREATE INDEX ON submissions(student_id);
CREATE INDEX ON submissions(assignment_id);
CREATE INDEX ON submissions(risk_level);
CREATE INDEX ON submissions(ai_score);
CREATE INDEX ON submissions(grade);
CREATE INDEX ON submissions(is_deleted);

--8.RLS USERS ONLY--

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
ON users FOR select
USING (auth.uid()::text = id::text);

CREATE POLICY "Admin can view all users"
ON users FOR select
USING (auth.jwt() ->> 'role' = 'admin');

--9.RLS CLASSES ONLY--

ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teacher can view their own classes"
ON classes FOR select
USING (auth.uid()::text = teacher_id::text);

CREATE POLICY "Admin can view all classes"
ON classes FOR SELECT
USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Teachers can create classes"
ON classes FOR INSERT
WITH CHECK (auth.uid()::text = teacher_id::text);

--10.RLS ASSIGNMENTS ONLY--

ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers can view their own assignments"
ON assignments FOR SELECT 
USING (class_id IN (SELECT id FROM classes WHERE teacher_id::text = auth.uid()::text ));

CREATE POLICY "Students can view assignments of their class"
ON assignments FOR SELECT
USING(is_deleted = FALSE);

CREATE POLICY "Teacher can create assignments"
ON assignments FOR INSERT 
WITH CHECK (class_id IN (SELECT id FROM classes WHERE teacher_id::text = auth.uid()::text));

CREATE POLICY "Admin can do everything on assignments"
ON assignments FOR ALL 
USING (auth.jwt() ->> 'role' = 'admin');

--11.RLS SUBMISSIONS ONLY--

ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students can view their own submissions"
ON submissions FOR SELECT   
USING ((select auth.uid())::text = student_id::text);

CREATE POLICY "Students can insert their own submissions"
ON submissions FOR INSERT
WITH CHECK((select auth.uid())::text = student_id::text);  

CREATE POLICY "Teachers can view submissions of their class"
ON submissions FOR SELECT
USING (
  assignment_id IN(
    SELECT id FROM assignments
    WHERE class_id IN (
      SELECT id FROM classes
      WHERE teacher_id::text = (select auth.uid())::text
    )
  )
);

CREATE POLICY "Teachers can update grade only"
ON submissions FOR UPDATE 
USING(assignment_id IN(
  SELECT ID FROM assignments 
  WHERE class_id IN (
    SELECT id FROM classes
    WHERE teacher_id::text = (select auth.uid())::text
  )
)
)
WITH CHECK(
  assignment_id IN(
    SELECT id FROM assignments
    WHERE class_id IN (
      SELECT id FROM classes
      WHERE teacher_id::text = (select auth.uid())::text
    )
  )
);

CREATE POLICY "Admin can do everything on submissions"
ON submissions FOR ALL
USING (auth.jwt() ->> 'role' = 'admin'); 
