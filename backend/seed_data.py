import os
import django
from datetime import date, time, timedelta
from django.utils import timezone
from django.core.files.base import ContentFile

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from accounts.models import User, Department, StudentProfile, FacultyProfile
from academics.models import Subject, Timetable, Attendance
from assignments.models import (
    Assignment,
    AssignmentSubmission,
    SubmissionVersion,
    SimilarityResult,
    SimilarityMatch,
    TeacherReview,
    OCRResult,
)
from events.models import Event, EventMedia
from notes.models import Note
from notifications.models import Notification

def seed():
    print("[*] Starting database seeding with multi-student assignment OCR & similarity test data...")

    # 1. Departments
    dept_cse, _ = Department.objects.get_or_create(code="CSE", defaults={"name": "Computer Science & Engineering"})
    dept_ece, _ = Department.objects.get_or_create(code="ECE", defaults={"name": "Electronics & Communication"})
    dept_mech, _ = Department.objects.get_or_create(code="MECH", defaults={"name": "Mechanical Engineering"})

    # 2. Admin
    if not User.objects.filter(username="ADMIN001").exists():
        admin_user = User.objects.create_superuser(
            username="ADMIN001",
            email="admin@learnova.edu",
            password="admin123",
            first_name="Campus",
            last_name="Administrator",
            role="admin"
        )
        print(" Created Admin: ADMIN001 / admin123")
    else:
        admin_user = User.objects.get(username="ADMIN001")

    # 3. Faculty 1 (Dr. Ramesh Sharma)
    if not User.objects.filter(username="FAC001").exists():
        fac_user1 = User.objects.create_user(
            username="FAC001",
            email="ramesh.sharma@learnova.edu",
            password="faculty123",
            first_name="Dr. Ramesh",
            last_name="Sharma",
            role="faculty"
        )
        fac_prof1 = FacultyProfile.objects.create(
            user=fac_user1,
            faculty_id="FAC001",
            department=dept_cse,
            designation="Professor & HOD",
            office="Block A, Room 304",
            phone="+91 98765 43210",
            status="APPROVED"
        )
        print(" Created Faculty: FAC001 / faculty123")
    else:
        fac_prof1 = FacultyProfile.objects.get(faculty_id="FAC001")

    # Faculty 2 (Prof. Sunita Rao)
    if not User.objects.filter(username="FAC002").exists():
        fac_user2 = User.objects.create_user(
            username="FAC002",
            email="sunita.rao@learnova.edu",
            password="faculty123",
            first_name="Prof. Sunita",
            last_name="Rao",
            role="faculty"
        )
        fac_prof2 = FacultyProfile.objects.create(
            user=fac_user2,
            faculty_id="FAC002",
            department=dept_cse,
            designation="Assistant Professor",
            office="Block A, Room 308",
            phone="+91 98765 43211",
            status="APPROVED"
        )
        print(" Created Faculty: FAC002 / faculty123")
    else:
        fac_prof2 = FacultyProfile.objects.get(faculty_id="FAC002")

    # Faculty 3 (Dr. Anita Desai)
    if not User.objects.filter(username="FAC003").exists():
        fac_user3 = User.objects.create_user(
            username="FAC003",
            email="anita.desai@learnova.edu",
            password="faculty123",
            first_name="Dr. Anita",
            last_name="Desai",
            role="faculty"
        )
        fac_prof3 = FacultyProfile.objects.create(
            user=fac_user3,
            faculty_id="FAC003",
            department=dept_cse,
            designation="Associate Professor",
            office="Block B, Room 205",
            phone="+91 98765 43212",
            status="APPROVED"
        )
        print(" Created Faculty: FAC003 / faculty123")
    else:
        fac_prof3 = FacultyProfile.objects.get(faculty_id="FAC003")

    # 4. 10 Demo Students with Online / Offline status
    student_specs = [
        ("23CSE001", "Arun", "Kumar", "arun.kumar@learnova.edu", "+91 91234 56789", True),
        ("23CSE002", "Priya", "Sharma", "priya.sharma@learnova.edu", "+91 91234 56781", True),
        ("23CSE003", "Rahul", "Verma", "rahul.verma@learnova.edu", "+91 91234 56782", False),
        ("23CSE004", "Anjali", "Devi", "anjali.devi@learnova.edu", "+91 91234 56783", True),
        ("23CSE005", "Vikram", "Singh", "vikram.singh@learnova.edu", "+91 91234 56784", False),
        ("23CSE006", "Sneha", "Reddy", "sneha.reddy@learnova.edu", "+91 91234 56785", True),
        ("23CSE007", "Karthik", "Nair", "karthik.nair@learnova.edu", "+91 91234 56786", True),
        ("23CSE008", "Meera", "Iyer", "meera.iyer@learnova.edu", "+91 91234 56787", False),
        ("23CSE009", "Rohan", "Gupta", "rohan.gupta@learnova.edu", "+91 91234 56788", True),
        ("23CSE010", "Divya", "Patel", "divya.patel@learnova.edu", "+91 91234 56790", False),
    ]

    student_profiles = {}
    for sid, fname, lname, email, phone, is_online in student_specs:
        if not User.objects.filter(username=sid).exists():
            u = User.objects.create_user(
                username=sid,
                email=email,
                password="student123",
                first_name=fname,
                last_name=lname,
                role="student"
            )
            sp = StudentProfile.objects.create(
                user=u,
                student_id=sid,
                department=dept_cse,
                year=4,
                section="A",
                semester=7,
                phone=phone,
                is_online=is_online
            )
            print(f" Created Student: {sid} / student123 ({fname} {lname}) [Online: {is_online}]")
        else:
            sp = StudentProfile.objects.get(student_id=sid)
            sp.is_online = is_online
            sp.year = 4
            sp.section = "A"
            sp.semester = 7
            sp.department = dept_cse
            sp.save()
        student_profiles[sid] = sp

    # 5. Subjects
    sub_sec, _ = Subject.objects.get_or_create(
        code="CS404",
        defaults={
            "name": "Cybersecurity & Cryptography",
            "department": dept_cse,
            "year": 4,
            "semester": 7,
            "faculty": fac_prof1
        }
    )
    sub_mad, _ = Subject.objects.get_or_create(
        code="CS401",
        defaults={
            "name": "Mobile Application Development",
            "department": dept_cse,
            "year": 4,
            "semester": 7,
            "faculty": fac_prof1
        }
    )
    sub_cc, _ = Subject.objects.get_or_create(
        code="CS402",
        defaults={
            "name": "Cloud Computing & DevOps",
            "department": dept_cse,
            "year": 4,
            "semester": 7,
            "faculty": fac_prof2
        }
    )
    sub_ai, _ = Subject.objects.get_or_create(
        code="CS403",
        defaults={
            "name": "Machine Learning & AI",
            "department": dept_cse,
            "year": 4,
            "semester": 7,
            "faculty": fac_prof1
        }
    )

    # 6. Main Test Assignment: "Network Security Assignment 1"
    assign_netsec, _ = Assignment.objects.get_or_create(
        title="Network Security Assignment 1",
        defaults={
            "subject": sub_sec,
            "department": dept_cse,
            "year": 4,
            "section": "A",
            "semester": 7,
            "description": "Explain fundamental principles of computer network security, access control policies, administrator privileges, and protection of public and private networked resources.",
            "instructions": "Handwritten submissions and digital PDFs are accepted. If submitting handwritten pages, ensure clear lighting and legible writing. Plagiarism above 70% will require rewrite.",
            "due_date": timezone.now() + timedelta(days=5),
            "max_marks": 50,
            "faculty": fac_prof1
        }
    )

    # 7. Pre-populate Submissions for Students B, C, D, E for Multi-Student Comparison
    # Texts for Students B, C, D, E
    text_b = "Network security consists of policies, processes, and practices implemented to prevent and monitor unauthorized access or denial of a computer network and network-accessible resources. Network security involves authorization of access to data in a network, controlled by the network administrator. Users choose or are assigned an ID and password or other authenticating credentials allowing access to information and programs within their authority. Network security covers multiple computer networks, both public and private, used in everyday jobs for transactions and communications among businesses, government agencies and individuals. Networks can be private within a company, or open to public access."

    text_c = "Network security principles dictate policies and processes adopted to prevent unauthorized access and protect computer network resources. In addition to user passwords and authentication information for accessing network programs, modern security covers both public and private networks with cryptographic encryption ciphers, digital certificates, and intrusion prevention firewalls."

    text_d = "Information assurance and security covers computer networks and authentication protocols. Secure communications among businesses and government agencies rely on public key cryptography, hashing functions, and certificate authority validation."

    text_e = "Computer network architectures use packet switching and routing tables. Data communication requires hardware firewalls and secure administrative credentials to monitor throughput."

    candidate_data = [
        ("23CSE002", text_b, "Submitted"),
        ("23CSE003", text_c, "Submitted"),
        ("23CSE004", text_d, "Submitted"),
        ("23CSE005", text_e, "Submitted"),
        ("23CSE006", "Network security involves multi-layered defense architectures including firewalls, intrusion detection, packet filtering, and SSL/TLS transport layer encryption.", "Submitted"),
        ("23CSE007", "Authentication protocols and zero-trust security frameworks ensure each access request is authenticated, authorized, and continuously validated before granting access.", "Submitted"),
    ]

    for sid, text_content, sub_status in candidate_data:
        sp = student_profiles[sid]
        sub, _ = AssignmentSubmission.objects.get_or_create(
            assignment=assign_netsec,
            student=sp,
            defaults={
                "status": sub_status,
                "current_version": 1,
                "extracted_text": text_content,
                "ocr_confidence": 94.0,
            }
        )
        if not sub.extracted_text:
            sub.extracted_text = text_content
            sub.ocr_confidence = 94.0
            sub.save()

        # Version
        SubmissionVersion.objects.get_or_create(
            submission=sub,
            version_number=1,
            defaults={
                "status": sub_status,
                "ocr_text": text_content,
                "ocr_confidence": 94.0,
                "similarity_percentage": 10.0,
                "originality_percentage": 90.0,
                "decision": "ACCEPTED"
            }
        )

        # OCR Result
        OCRResult.objects.get_or_create(
            submission=sub,
            defaults={
                "ocr_text": text_content,
                "ocr_status": "COMPLETED",
                "ocr_confidence": 94.0,
                "page_count": 2
            }
        )

    # 8. Student A (Arun Kumar - 23CSE001): Create initial demonstration submission with 83% similarity
    text_a = "Network security consists of the policies, processes, and practices adopted to prevent, detect, and monitor unauthorized access, misuse, modification, or denial of a computer network and network-accessible resources. Network security involves the authorization of access to data in a network, which is controlled by the network administrator. Users choose or are assigned an ID and password or other authenticating information that allows them access to information and programs within their authority. Network security covers a variety of computer networks, both public and private, that are used in everyday jobs: conducting transactions and communications among businesses, government agencies and individuals. Networks can be private, such as within a company, and others which might be open to public access."

    arun_sp = student_profiles["23CSE001"]
    sub_arun, created_arun = AssignmentSubmission.objects.get_or_create(
        assignment=assign_netsec,
        student=arun_sp,
        defaults={
            "status": "REJECTED",
            "current_version": 1,
            "extracted_text": text_a,
            "ocr_confidence": 92.0,
            "teacher_feedback": "Similarity is above 70% threshold. You can request teacher review or rewrite and resubmit."
        }
    )

    if created_arun or sub_arun.status != "APPROVED":
        sub_arun.status = "REJECTED"
        sub_arun.extracted_text = text_a
        sub_arun.ocr_confidence = 92.0
        sub_arun.current_version = 1
        sub_arun.save()

        # Clean up existing versions, OCR results, and reviews for clean idempotency
        SubmissionVersion.objects.filter(submission=sub_arun).delete()
        OCRResult.objects.filter(submission=sub_arun).delete()

        ver1 = SubmissionVersion.objects.create(
            submission=sub_arun,
            version_number=1,
            status="REJECTED",
            ocr_text=text_a,
            ocr_confidence=92.0,
            similarity_percentage=83.2,
            originality_percentage=16.8,
            decision="REJECTED — REWRITE REQUIRED",
            teacher_feedback="High similarity detected against Priya Sharma's submission."
        )

        OCRResult.objects.create(
            submission=sub_arun,
            version=ver1,
            ocr_text=text_a,
            ocr_status="COMPLETED",
            ocr_confidence=92.0,
            page_count=2
        )

        sub_b = AssignmentSubmission.objects.get(assignment=assign_netsec, student__student_id="23CSE002")
        sub_c = AssignmentSubmission.objects.get(assignment=assign_netsec, student__student_id="23CSE003")
        sub_d = AssignmentSubmission.objects.get(assignment=assign_netsec, student__student_id="23CSE004")
        sub_e = AssignmentSubmission.objects.get(assignment=assign_netsec, student__student_id="23CSE005")

        # Similarity Result
        SimilarityResult.objects.update_or_create(
            submission=sub_arun,
            defaults={
                "version": ver1,
                "similarity_percentage": 83.2,
                "originality_percentage": 16.8,
                "highest_match_student": "Priya Sharma (23CSE002)",
                "highest_match_percentage": 83.2,
                "matched_submission": sub_b,
                "processing_status": "HIGH_SIMILARITY",
                "decision": "REJECTED — REWRITE REQUIRED",
                "teacher_review_required": True,
                "potential_matches": [
                    {"student_id": "23CSE002", "student_name": "Priya Sharma", "similarity_percentage": 83.2},
                    {"student_id": "23CSE003", "student_name": "Rahul Kumar", "similarity_percentage": 27.4},
                    {"student_id": "23CSE004", "student_name": "Anjali Devi", "similarity_percentage": 13.6},
                    {"student_id": "23CSE005", "student_name": "Vikram Singh", "similarity_percentage": 6.8},
                ]
            }
        )

        # Similarity Matches
        SimilarityMatch.objects.filter(source_submission=sub_arun).delete()
        SimilarityMatch.objects.create(
            source_submission=sub_arun,
            matched_submission=sub_b,
            source_student_name="Arun Kumar",
            matched_student_name="Priya Sharma",
            similarity_percentage=83.2,
            matching_text="Network security consists of policies, processes, and practices implemented to prevent and monitor unauthorized access..."
        )
        SimilarityMatch.objects.create(
            source_submission=sub_arun,
            matched_submission=sub_c,
            source_student_name="Arun Kumar",
            matched_student_name="Rahul Kumar",
            similarity_percentage=27.4,
            matching_text="policies and processes adopted to prevent unauthorized access and protect computer network resources..."
        )

        # Initial Notification for Arun
        Notification.objects.get_or_create(
            user=arun_sp.user,
            title="🔴 High Similarity Detected (83.2%)",
            defaults={
                "message": "Your submission for 'Network Security Assignment 1' has a high similarity score (83.2%). Status: REJECTED — REWRITE REQUIRED. Options: 1. Request Teacher Review, 2. Rewrite & Resubmit.",
                "is_read": False
            }
        )

    # 9. Timetable
    days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    schedule_matrix = [
        (time(9, 0), time(10, 0), sub_mad, "Lab 3"),
        (time(10, 15), time(11, 15), sub_cc, "Hall 201"),
        (time(11, 30), time(12, 30), sub_ai, "Hall 201"),
        (time(13, 30), time(14, 30), sub_sec, "Lab 1"),
        (time(14, 30), time(15, 30), sub_mad, "Lab 3"),
    ]
    for day in days:
        for st, et, sub, room in schedule_matrix:
            Timetable.objects.get_or_create(
                department=dept_cse,
                year=4,
                section="A",
                day=day,
                start_time=st,
                end_time=et,
                subject=sub,
                defaults={"room": room}
            )

    # 10. Attendance
    today = date.today()
    for i in range(14):
        past_date = today - timedelta(days=i)
        if past_date.weekday() < 5:
            for sub in [sub_mad, sub_cc, sub_ai, sub_sec]:
                for s_idx, (sid, sp) in enumerate(student_profiles.items()):
                    status_val = False if ((s_idx + i) % 5 == 0) else True
                    Attendance.objects.get_or_create(
                        student=sp,
                        subject=sub,
                        date=past_date,
                        defaults={"status": status_val}
                    )

    # 11. Events
    Event.objects.get_or_create(
        title="HackNova 2026 - 24-Hour Campus Hackathon",
        defaults={
            "description": "Annual 24-hour inter-college hackathon focusing on AI, Mobile Development, and Sustainability.",
            "date": today + timedelta(days=7),
            "time": time(10, 0),
            "venue": "Campus Auditorium & Innovation Center",
            "organizer": "Department of Computer Science & Coding Club",
            "category": "Technical"
        }
    )

    print("[OK] Database seeded successfully with 5-student multi-comparison dataset!")

if __name__ == '__main__':
    seed()
