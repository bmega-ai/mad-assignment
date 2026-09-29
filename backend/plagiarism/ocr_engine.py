import io
import os
import re
from PIL import Image, ImageEnhance, ImageFilter
import PyPDF2

def preprocess_image(image: Image.Image) -> Image.Image:
    """
    Implements standard preprocessing for handwritten assignment images:
    1. Resize image maintaining aspect ratio
    2. Convert to grayscale
    3. Improve contrast
    4. Remove noise (median filter)
    5. Adaptive thresholding / binarization
    """
    # 1. Resize to max dimension 1600px
    max_dim = 1600
    w, h = image.size
    if max(w, h) > max_dim:
        scale = max_dim / max(w, h)
        image = image.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)

    # 2. Grayscale
    gray = image.convert('L')

    # 3. Enhance Contrast
    enhancer = ImageEnhance.Contrast(gray)
    contrast_img = enhancer.enhance(1.8)

    # 4. Noise reduction
    filtered = contrast_img.filter(ImageFilter.MedianFilter(size=3))

    # 5. Thresholding / Binarization
    threshold = 140
    binarized = filtered.point(lambda p: 255 if p > threshold else 0)

    return binarized

def ocr_single_image(image_file) -> tuple[str, float, str]:
    """
    Runs preprocessing and OCR on a single image file.
    Returns (extracted_text, confidence_score, status)
    """
    try:
        if hasattr(image_file, 'seek'):
            image_file.seek(0)
        img = Image.open(image_file)
        processed = preprocess_image(img)

        # Try pytesseract if tesseract is installed
        try:
            import pytesseract
            # Check if tesseract binary responds
            text = pytesseract.image_to_string(processed).strip()
            data = pytesseract.image_to_data(processed, output_type=pytesseract.Output.DICT)
            confidences = [int(c) for c in data.get('conf', []) if c != '-1']
            avg_conf = round(sum(confidences) / len(confidences), 1) if confidences else 85.0
            if text:
                return text, avg_conf, "COMPLETED"
        except Exception:
            pass

        # Try EasyOCR if available
        try:
            import easyocr
            reader = easyocr.Reader(['en'], gpu=False)
            import numpy as np
            results = reader.readtext(np.array(processed))
            extracted_words = []
            conf_list = []
            for bbox, word, conf in results:
                extracted_words.append(word)
                conf_list.append(conf * 100)
            text = " ".join(extracted_words).strip()
            avg_conf = round(sum(conf_list) / len(conf_list), 1) if conf_list else 80.0
            if text:
                return text, avg_conf, "COMPLETED"
        except Exception:
            pass

        # If no local OCR binary is configured on host, check if text/caption is in metadata or return simulated quality OCR
        return "", 0.0, "OCR_REVIEW_REQUIRED"

    except Exception as e:
        print(f"Error in ocr_single_image: {e}")
        return "", 0.0, "FAILED"

def extract_assignment_text(file_obj, additional_files=None, direct_text="") -> tuple[str, float, str, int]:
    """
    Extracts complete text from an assignment submission (PDF, DOCX, TXT, or multiple handwritten image pages).
    Returns (combined_text, average_confidence, overall_status, page_count)
    """
    all_pages_text = []
    confidence_scores = []
    page_count = 0

    if direct_text and direct_text.strip():
        all_pages_text.append(direct_text.strip())

    files_to_process = []
    if file_obj:
        files_to_process.append(file_obj)
    if additional_files:
        files_to_process.extend(additional_files)

    for f in files_to_process:
        fname = getattr(f, 'name', '').lower()
        page_count += 1

        if fname.endswith('.pdf'):
            try:
                if hasattr(f, 'seek'):
                    f.seek(0)
                reader = PyPDF2.PdfReader(f)
                pdf_text = []
                for idx, page in enumerate(reader.pages):
                    pt = page.extract_text()
                    if pt and pt.strip():
                        pdf_text.append(pt.strip())
                if hasattr(f, 'seek'):
                    f.seek(0)

                if pdf_text:
                    all_pages_text.append("\n".join(pdf_text))
                    confidence_scores.append(95.0)
                else:
                    # PDF may be scanned handwritten images
                    all_pages_text.append("")
                    confidence_scores.append(60.0)
            except Exception as e:
                print(f"PDF extract error: {e}")

        elif fname.endswith(('.jpg', '.jpeg', '.png', '.bmp', '.webp', '.tiff', '.heic')):
            txt, conf, status = ocr_single_image(f)
            if txt:
                all_pages_text.append(txt)
                confidence_scores.append(conf)
            else:
                confidence_scores.append(conf)
        else:
            # Text file / source code
            try:
                if hasattr(f, 'seek'):
                    f.seek(0)
                raw = f.read()
                if hasattr(f, 'seek'):
                    f.seek(0)
                if isinstance(raw, bytes):
                    content = raw.decode('utf-8', errors='ignore').strip()
                else:
                    content = str(raw).strip()
                if content:
                    all_pages_text.append(content)
                    confidence_scores.append(98.0)
            except Exception as e:
                print(f"File read error: {e}")

    combined_text = "\n\n".join([t for t in all_pages_text if t.strip()]).strip()
    avg_confidence = round(sum(confidence_scores) / len(confidence_scores), 1) if confidence_scores else 90.0

    if not combined_text:
        status = "OCR_REVIEW_REQUIRED"
    elif avg_confidence < 40:
        status = "OCR_REVIEW_REQUIRED"
    else:
        status = "COMPLETED"

    return combined_text, avg_confidence, status, max(1, page_count)

def extract_text_from_file(file_obj) -> str:
    text, _, _, _ = extract_assignment_text(file_obj)
    return text

