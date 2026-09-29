import re
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from .ocr_engine import extract_assignment_text, extract_text_from_file

def normalize_text(text: str) -> str:
    """
    Normalizes text for TF-IDF similarity calculation:
    - Converts to lowercase
    - Normalizes repeated whitespaces
    - Removes punctuation noise while preserving technical terms and numbers
    """
    if not text:
        return ""
    text = text.lower()
    # Replace non-alphanumeric (except basic punctuation used in code/math)
    text = re.sub(r'[\r\n\t]+', ' ', text)
    text = re.sub(r'[^a-z0-9\s\.\_\-\+]', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def find_matching_snippet(text1: str, text2: str, max_chars: int = 150) -> str:
    """
    Finds the most significant overlapping sentence or phrase between two texts.
    """
    words1 = text1.split()
    words2 = set(text2.lower().split())
    matching_phrases = []

    for i in range(len(words1) - 4):
        phrase = " ".join(words1[i:i+5])
        if phrase.lower() in text2.lower():
            matching_phrases.append(phrase)

    if matching_phrases:
        return matching_phrases[0][:max_chars] + "..."
    # Fallback snippet
    return text1[:max_chars] + "..." if text1 else ""

def check_similarity(new_text, existing_texts):
    """
    Basic TF-IDF similarity between new_text and a list of texts.
    """
    cleaned_existing = [t for t in existing_texts if t and t.strip()]
    if not new_text or not new_text.strip() or not cleaned_existing:
        return 0.0, []

    texts = [new_text] + cleaned_existing
    vectorizer = TfidfVectorizer(stop_words='english', ngram_range=(1, 2))
    try:
        tfidf_matrix = vectorizer.fit_transform(texts)
    except ValueError:
        return 0.0, []

    cosine_sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:])
    similarities = cosine_sim[0]
    max_sim = max(similarities) if len(similarities) > 0 else 0.0

    matches = []
    for idx, sim in enumerate(similarities):
        sim_pct = round(float(sim) * 100, 1)
        matches.append({
            "submission_index": idx,
            "similarity_percentage": sim_pct
        })

    return round(float(max_sim) * 100, 1), matches

def run_multi_student_similarity(target_text: str, candidate_submissions: list) -> tuple[float, float, str, str, list, dict]:
    """
    Compares target_text against all other candidate student submissions for the same assignment.
    candidate_submissions: list of dicts with:
      {'id': sub_id, 'student_id': str, 'student_name': str, 'text': str, 'submission_obj': obj}

    Returns:
      (highest_similarity_pct, originality_pct, processing_status, decision, matches_list, top_match_info)
    """
    clean_target = normalize_text(target_text)
    if not clean_target or not candidate_submissions:
        return (0.0, 100.0, "LOW_SIMILARITY", "ACCEPTED", [], {})

    valid_candidates = []
    corpus = [clean_target]

    for cand in candidate_submissions:
        c_text = normalize_text(cand.get('text', ''))
        if c_text:
            valid_candidates.append(cand)
            corpus.append(c_text)

    if not valid_candidates:
        return (0.0, 100.0, "LOW_SIMILARITY", "ACCEPTED", [], {})

    vectorizer = TfidfVectorizer(stop_words='english', ngram_range=(1, 2), min_df=1)
    try:
        tfidf_matrix = vectorizer.fit_transform(corpus)
    except ValueError:
        return (0.0, 100.0, "LOW_SIMILARITY", "ACCEPTED", [], {})

    cosine_sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:])
    sim_scores = cosine_sim[0]

    matches_list = []
    for idx, sim in enumerate(sim_scores):
        cand = valid_candidates[idx]
        sim_pct = round(float(sim) * 100, 1)
        raw_text = cand.get('text', '')
        snippet = find_matching_snippet(target_text, raw_text)

        matches_list.append({
            "submission_id": cand.get('id'),
            "student_id": cand.get('student_id', ''),
            "student_name": cand.get('student_name', 'Student'),
            "similarity_percentage": sim_pct,
            "matching_text": snippet
        })

    # Sort descending by similarity
    matches_list.sort(key=lambda m: m["similarity_percentage"], reverse=True)

    highest_similarity_pct = matches_list[0]["similarity_percentage"] if matches_list else 0.0
    originality_pct = max(0.0, round(100.0 - highest_similarity_pct, 1))
    top_match = matches_list[0] if matches_list else {}

    # Classification according to 70% threshold rule
    if highest_similarity_pct > 70.0:
        processing_status = "HIGH_SIMILARITY"
        decision = "REJECTED — REWRITE REQUIRED"
    elif highest_similarity_pct >= 50.0:
        processing_status = "HIGH_SIMILARITY"
        decision = "TEACHER_REVIEW_RECOMMENDED"
    elif highest_similarity_pct >= 30.0:
        processing_status = "MODERATE_SIMILARITY"
        decision = "ACCEPTED"
    else:
        processing_status = "LOW_SIMILARITY"
        decision = "ACCEPTED"

    return (highest_similarity_pct, originality_pct, processing_status, decision, matches_list, top_match)
