from plagiarism.services import run_multi_student_similarity

text_a = "Network security consists of the policies, processes, and practices adopted to prevent, detect, and monitor unauthorized access, misuse, modification, or denial of a computer network and network-accessible resources. Network security involves the authorization of access to data in a network, which is controlled by the network administrator. Users choose or are assigned an ID and password or other authenticating information that allows them access to information and programs within their authority. Network security covers a variety of computer networks, both public and private, that are used in everyday jobs: conducting transactions and communications among businesses, government agencies and individuals. Networks can be private, such as within a company, and others which might be open to public access."

# Fine-tuned for ~82%
text_b = "Network security consists of policies, processes, and practices implemented to prevent and monitor unauthorized access or denial of a computer network and network-accessible resources. Network security involves authorization of access to data in a network, controlled by the network administrator. Users choose or are assigned an ID and password or other authenticating credentials allowing access to information and programs within their authority. Network security covers multiple computer networks, both public and private, used in everyday jobs for transactions and communications among businesses, government agencies and individuals. Networks can be private within a company, or open to public access."

# Fine-tuned for ~42%
text_c = "Network security principles dictate policies and processes adopted to prevent unauthorized access and protect computer network resources. In addition to user passwords and authentication information for accessing network programs, modern security covers both public and private networks with cryptographic encryption ciphers, digital certificates, and intrusion prevention firewalls."

# Fine-tuned for ~18%
text_d = "Information assurance and security covers computer networks and authentication protocols. Secure communications among businesses and government agencies rely on public key cryptography, hashing functions, and certificate authority validation."

# Fine-tuned for ~12%
text_e = "Computer network architectures use packet switching and routing tables. Data communication requires hardware firewalls and secure administrative credentials to monitor throughput."

candidates = [
    {"id": 2, "student_id": "23CSE002", "student_name": "Priya Sharma", "text": text_b, "submission_obj": None},
    {"id": 3, "student_id": "23CSE003", "student_name": "Rahul Kumar", "text": text_c, "submission_obj": None},
    {"id": 4, "student_id": "23CSE004", "student_name": "Anjali Devi", "text": text_d, "submission_obj": None},
    {"id": 5, "student_id": "23CSE005", "student_name": "Vikram Singh", "text": text_e, "submission_obj": None},
]

highest, orig, status, decision, matches, top = run_multi_student_similarity(text_a, candidates)
print(f"Highest: {highest}%, Orig: {orig}%, Status: {status}, Decision: {decision}")
for m in matches:
    print(f" -> {m['student_name']}: {m['similarity_percentage']}%")
