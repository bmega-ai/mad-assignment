from plagiarism.services import run_multi_student_similarity

text_b = "Network security consists of policies, processes, and practices implemented to prevent and monitor unauthorized access or denial of a computer network and network-accessible resources. Network security involves authorization of access to data in a network, controlled by the network administrator. Users choose or are assigned an ID and password or other authenticating credentials allowing access to information and programs within their authority. Network security covers multiple computer networks, both public and private, used in everyday jobs for transactions and communications among businesses, government agencies and individuals. Networks can be private within a company, or open to public access."
text_c = "Network security principles dictate policies and processes adopted to prevent unauthorized access and protect computer network resources. In addition to user passwords and authentication information for accessing network programs, modern security covers both public and private networks with cryptographic encryption ciphers, digital certificates, and intrusion prevention firewalls."
text_d = "Information assurance and security covers computer networks and authentication protocols. Secure communications among businesses and government agencies rely on public key cryptography, hashing functions, and certificate authority validation."
text_e = "Computer network architectures use packet switching and routing tables. Data communication requires hardware firewalls and secure administrative credentials to monitor throughput."

candidates = [
    {"id": 2, "student_id": "23CSE002", "student_name": "Priya Sharma", "text": text_b, "submission_obj": None},
    {"id": 3, "student_id": "23CSE003", "student_name": "Rahul Kumar", "text": text_c, "submission_obj": None},
    {"id": 4, "student_id": "23CSE004", "student_name": "Anjali Devi", "text": text_d, "submission_obj": None},
    {"id": 5, "student_id": "23CSE005", "student_name": "Vikram Singh", "text": text_e, "submission_obj": None},
]

text_v2 = "Modern network defensive architectures incorporate zero-trust security models, where trust is never assumed and continuous verification is mandated at every access layer. Identity-aware proxies, multi-factor biometric authentication, and micro-segmentation protect internal data enclaves from lateral cyber threats."

highest_v2, orig_v2, status_v2, decision_v2, matches_v2, _ = run_multi_student_similarity(text_v2, candidates)
print(f"Version 2 -> Highest: {highest_v2}%, Status: {status_v2}, Decision: {decision_v2}")
