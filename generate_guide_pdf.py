import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, KeepTogether, ListFlowable, ListItem
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Header (on pages after cover)
        if self._pageNumber > 1:
            self.drawString(54, 750, "Learnova — Server Setup & Mobile APK Connection Guide")
            self.setStrokeColor(colors.HexColor("#E2E8F0"))
            self.setLineWidth(0.5)
            self.line(54, 742, 558, 742)
            
        # Footer
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 45, 558, 45)
        self.drawString(54, 32, "Confidential — Academic & Development Use Only")
        self.drawRightString(558, 32, f"Page {self._pageNumber} of {page_count}")
        self.restoreState()

def create_guide_pdf(filename):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()
    
    # Custom styles
    primary_color = colors.HexColor("#1E3A8A")   # Deep Navy
    secondary_color = colors.HexColor("#2563EB") # Royal Blue
    accent_dark = colors.HexColor("#0F172A")     # Dark Slate
    body_color = colors.HexColor("#334155")      # Slate 700

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=primary_color,
        spaceAfter=6
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubTitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=secondary_color,
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=19,
        textColor=primary_color,
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=secondary_color,
        spaceBefore=10,
        spaceAfter=5,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=body_color,
        spaceAfter=6
    )

    bold_body_style = ParagraphStyle(
        'BoldBody',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=accent_dark,
        spaceAfter=4
    )

    code_style = ParagraphStyle(
        'CodeText',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=9.5,
        leading=13,
        textColor=colors.HexColor("#0F172A")
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=colors.HexColor("#1E293B")
    )

    def code_box(code_text):
        p = Paragraph(code_text.replace("\n", "<br/>").replace(" ", "&nbsp;"), code_style)
        t = Table([[p]], colWidths=[504])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F1F5F9")),
            ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
            ('LEFTPADDING', (0,0), (-1,-1), 12),
            ('RIGHTPADDING', (0,0), (-1,-1), 12),
            ('TOPPADDING', (0,0), (-1,-1), 8),
            ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ]))
        return t

    def info_box(text, bg_color="#EFF6FF", border_color="#93C5FD", icon="ℹ️"):
        p = Paragraph(f"<b>{icon} Note:</b> {text}", callout_style)
        t = Table([[p]], colWidths=[504])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor(bg_color)),
            ('BOX', (0,0), (-1,-1), 1, colors.HexColor(border_color)),
            ('LEFTPADDING', (0,0), (-1,-1), 12),
            ('RIGHTPADDING', (0,0), (-1,-1), 12),
            ('TOPPADDING', (0,0), (-1,-1), 8),
            ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ]))
        return t

    def warning_box(text):
        return info_box(text, bg_color="#FFFBEB", border_color="#FCD34D", icon="⚠️")

    story = []

    # Title & Header
    story.append(Paragraph("LEARNOVA MOBILE APPLICATION", title_style))
    story.append(Paragraph("Complete Server Setup, IP Discovery & APK Connection Guide", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=secondary_color, spaceAfter=14))

    # Architecture Overview
    story.append(Paragraph("1. System Architecture Overview", h1_style))
    story.append(Paragraph(
        "Learnova connects your mobile device directly to the Django REST backend server running on your computer. "
        "Because both devices communicate over your local Wi-Fi router, the mobile app requires your computer's "
        "local <b>IPv4 address</b> (e.g., <code>10.143.206.252</code>) instead of <code>127.0.0.1</code> or <code>localhost</code>.",
        body_style
    ))
    
    arch_table_data = [
        [
            Paragraph("<b>Mobile Phone (Learnova APK)</b><br/>Running on Android Phone<br/>Target: <code>http://&lt;PC-IP&gt;:8000/api</code>", body_style),
            Paragraph("<b>&harr;&nbsp;Wi-Fi Router&nbsp;&harr;</b><br/>Local WLAN Network", body_style),
            Paragraph("<b>Development PC (Django Server)</b><br/>Running on <code>0.0.0.0:8000</code><br/>Wi-Fi IPv4: <code>10.143.206.252</code>", body_style)
        ]
    ]
    arch_table = Table(arch_table_data, colWidths=[170, 144, 190])
    arch_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(arch_table)
    story.append(Spacer(1, 10))

    # SECTION 2: Finding IP
    story.append(Paragraph("2. How to View Your PC's Server IP Address (`ipconfig`)", h1_style))
    story.append(Paragraph(
        "Wi-Fi routers automatically assign dynamic IP addresses via DHCP. Whenever your computer disconnects "
        "or reconnects to Wi-Fi, your IP address may change. Follow these quick steps to find your current IP:",
        body_style
    ))

    story.append(Paragraph("<b>Step 1:</b> Press <b>Win + R</b>, type <b><code>cmd</code></b> or <b><code>powershell</code></b>, and press <b>Enter</b>.", body_style))
    story.append(Paragraph("<b>Step 2:</b> In the black terminal window, type the following command and press Enter:", body_style))
    story.append(code_box("ipconfig"))
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Step 3:</b> Scroll through the output and look for the section titled <b>Wireless LAN adapter Wi-Fi</b>:", body_style))
    story.append(code_box(
        "Wireless LAN adapter Wi-Fi:\n"
        "   Connection-specific DNS Suffix  . : \n"
        "   Link-local IPv6 Address . . . . . : fe80::7e3b:baed:bd80:9d26%7\n"
        "   IPv4 Address. . . . . . . . . . . : 10.143.206.252   <--- THIS IS YOUR SERVER IP\n"
        "   Subnet Mask . . . . . . . . . . . : 255.255.255.0\n"
        "   Default Gateway . . . . . . . . . : 10.143.206.18"
    ))
    story.append(Spacer(1, 6))
    story.append(warning_box(
        "Always copy the <b>IPv4 Address</b> from <b>Wireless LAN adapter Wi-Fi</b>. "
        "Do NOT use 'Ethernet' or virtual adapter IPs (e.g. 192.168.56.1 from VirtualBox) when your phone is connected over Wi-Fi."
    ))

    story.append(Spacer(1, 10))

    # SECTION 3: Running Django Server
    story.append(Paragraph("3. How to Run the Django Backend Server", h1_style))
    story.append(Paragraph(
        "To allow external devices like your physical phone to communicate with your backend, you must bind "
        "the server to <b><code>0.0.0.0:8000</code></b>. If you only run <code>python manage.py runserver</code> without "
        "specifying <code>0.0.0.0</code>, Django only listens to <code>127.0.0.1</code> (localhost) and the phone cannot connect.",
        body_style
    ))

    story.append(Paragraph("<b>Step 1:</b> Open terminal/PowerShell in the project backend folder:", body_style))
    story.append(code_box("cd \"c:\\Users\\PERSONAL\\OneDrive\\Desktop\\mad assignment\\backend\""))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Step 2 (Optional - First Time Only):</b> Apply database migrations and load demo seeds:", body_style))
    story.append(code_box("python manage.py migrate\npython seed_data.py"))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Step 3:</b> Start the server bound to all network interfaces on port 8000:", body_style))
    story.append(code_box("python manage.py runserver 0.0.0.0:8000"))
    story.append(Spacer(1, 6))

    story.append(info_box(
        "You should see output: <code>Starting development server at http://0.0.0.0:8000/</code>.<br/>"
        "Keep this terminal window OPEN while using the mobile app."
    ))

    story.append(Spacer(1, 10))

    # SECTION 4: Connecting the APK
    story.append(Paragraph("4. How to Connect the Learnova APK with the Server", h1_style))
    story.append(Paragraph(
        "Your new Learnova APK features an <b>Automatic Server Setup Prompt</b> right on the splash screen loading phase, "
        "meaning you can seamlessly connect to any new Wi-Fi IP address in seconds without reinstalling the app!",
        body_style
    ))

    story.append(Paragraph("<b>Step 1: Check Wi-Fi Connection</b>", bold_body_style))
    story.append(Paragraph("Ensure both your Android smartphone and your PC are connected to the <b>same Wi-Fi network</b>.", body_style))

    story.append(Paragraph("<b>Step 2: Install and Open the APK</b>", bold_body_style))
    story.append(Paragraph("Install <b><code>app-release.apk</code></b> on your phone and launch <b>Learnova</b>.", body_style))

    story.append(Paragraph("<b>Step 3: Enter IP on the Splash Screen</b>", bold_body_style))
    story.append(Paragraph(
        "During app startup, a bottom sheet titled <b>'Connect to Server'</b> will appear automatically:<br/>"
        "• <b>Server IPv4 Address:</b> Type the IPv4 address from your <code>ipconfig</code> (e.g., <code>10.143.206.252</code>).<br/>"
        "• <b>Port:</b> Leave as <code>8000</code>.<br/>"
        "• Tap <b>'Connect &amp; Continue'</b>.<br/>"
        "The app saves this IP in its secure storage, so you don't need to retype it until your Wi-Fi changes.",
        body_style
    ))

    story.append(Paragraph("<b>Step 4: Changing IP Later from the Login Screen</b>", bold_body_style))
    story.append(Paragraph(
        "If your IP changes tomorrow, look at the bottom of the Login Screen. You will see a button labeled "
        "<b>'Server: 10.143.206.252:8000'</b>. Tap it at any time to update your IP without restarting or reinstalling!",
        body_style
    ))

    story.append(Spacer(1, 10))

    # SECTION 5: Credentials Table
    story.append(Paragraph("5. Default Demo Login Credentials", h1_style))
    story.append(Paragraph("You can use any of the pre-configured accounts to test all student, faculty, and administrative flows:", body_style))

    cred_data = [
        [Paragraph("<b>Role</b>", bold_body_style), Paragraph("<b>User ID / Username</b>", bold_body_style), Paragraph("<b>Password</b>", bold_body_style), Paragraph("<b>Features Available</b>", bold_body_style)],
        [Paragraph("Student", body_style), Paragraph("<code>23CSE001</code>", code_style), Paragraph("<code>student123</code>", code_style), Paragraph("Assignments, Timetable, Notes, OCR Submissions", body_style)],
        [Paragraph("Faculty / Teacher", body_style), Paragraph("<code>FAC001</code>", code_style), Paragraph("<code>faculty123</code>", code_style), Paragraph("Create Tasks, Plagiarism Check, Grading & Reviews", body_style)],
        [Paragraph("Administrator", body_style), Paragraph("<code>admin</code>", code_style), Paragraph("<code>admin123</code>", code_style), Paragraph("Manage Users, System Analytics, Global Notifications", body_style)],
    ]
    cred_table = Table(cred_data, colWidths=[90, 110, 100, 204])
    cred_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#F1F5F9")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(cred_table)
    story.append(Spacer(1, 10))

    # SECTION 6: Troubleshooting
    story.append(Paragraph("6. Quick Troubleshooting & Firewall Fixes", h1_style))
    trouble_data = [
        [
            Paragraph("<b>Issue: 'Cannot connect to server at http://...'</b>", bold_body_style),
            Paragraph(
                "1. Verify both phone and PC are on the <b>same Wi-Fi</b>.<br/>"
                "2. Confirm the server was started with <b><code>0.0.0.0:8000</code></b>.<br/>"
                "3. Test connection by opening Chrome on your phone and visiting <b><code>http://&lt;PC-IP&gt;:8000/api/</code></b>.",
                body_style
            )
        ],
        [
            Paragraph("<b>Issue: Windows Firewall blocks incoming phone requests</b>", bold_body_style),
            Paragraph(
                "In Windows Search, open <b>'Windows Defender Firewall with Advanced Security'</b> &rarr; "
                "<b>Inbound Rules</b> &rarr; <b>New Rule</b> &rarr; <b>Port</b> &rarr; <b>TCP 8000</b> &rarr; "
                "<b>Allow the connection</b>. This allows phones on your home/office Wi-Fi to reach port 8000.",
                body_style
            )
        ],
        [
            Paragraph("<b>Issue: Android shows 'Unsafe installation blocked'</b>", bold_body_style),
            Paragraph(
                "Because this is a private development APK built for your project, Android Play Protect may show a warning. "
                "Tap <b>'More Details'</b> and select <b>'Install Anyway'</b>.",
                body_style
            )
        ]
    ]
    trouble_table = Table(trouble_data, colWidths=[180, 324])
    trouble_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (0,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(trouble_table)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generated successfully at: {filename}")

if __name__ == "__main__":
    out_file = r"c:\Users\PERSONAL\OneDrive\Desktop\mad assignment\Learnova_Server_and_APK_Guide.pdf"
    create_guide_pdf(out_file)
