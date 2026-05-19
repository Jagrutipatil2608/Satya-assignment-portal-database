# Satya-assignment-portal-database :
PostgreSQL database for Satya Assignment portal - an AI powered assignment checker portal.

## About the Project :
SatyaAssign is a college assignment submission portal that automatically detects AI-generated content and plagiarism in student submissions. Teachers can view 
AI scores, plagiarism scores and risk levels for each submission and grade accordingly.

## Database Tables
- **users** - Students, teachers and admins
- **classes** - Class groups assigned to teachers  
- **assignments** - Assignments created by teachers
- **submissions** - Student submissions with AI scores

 ## Features
- Row Level Security (RLS) for role based access
- Indexes for query performance
- Soft delete for data recovery
- Timestamps for audit trail
- Deployed on Supabase

 ## Tech Stack
- PostgreSQL
- Supabase.
