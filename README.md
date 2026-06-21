# ThaiLaw AI Advisor (ผู้ช่วยวิเคราะห์กฎหมายไทย)

เครื่องมือวิเคราะห์และให้คำแนะนำข้อกฎหมายไทยเบื้องต้นด้วยระบบปัญญาประดิษฐ์ (AI-powered Thai Legal Intelligence Advisor) พัฒนาด้วย Flutter รองรับการใช้งานข้ามแพลตฟอร์ม (Mobile, Desktop, และ Web) 

โปรเจกต์นี้ได้รับการไมเกรตและอัปเกรดความสามารถจากระบบเดิมที่เป็น React Native Expo

---

## คุณสมบัติเด่น (Key Features)

*   **วิเคราะห์สถานการณ์กฎหมายไทยแบบเชิงลึก (AI Legal Analysis)**: รับข้อมูลสถานการณ์จริงจากผู้ใช้ในชีวิตประจำวัน ข้อพิพาททางธุรกิจ หรือข้อขัดแย้งทางแพ่งและอาญา แล้ววิเคราะห์ประเด็นกฎหมาย ระบุเลขมาตรา พร้อมแนวทางการสู้คดีของโจทก์ จำเลย และแนวทางคดีของพนักงานสอบสวน
*   **Gemini 3.x Engine**: รองรับการใช้งาน Gemini API โมเดลล่าสุดของ Google (Gemini 3.5, Gemini 3.1 และ Gemini 3.0 ทั้งรุ่น Flash และ Pro)
*   **ระบบสแกนประวัติการวิเคราะห์พร้อมสรุปย่อ (History Summary Dashboard)**: หน้าแรกแสดงประวัติการวิเคราะห์กฎหมายที่ผ่านมา โดยดึงบทสรุปภายใน (Internal Summary) ที่ AI วิเคราะห์ได้มาประกอบคู่กับเหตุการณ์จริง
*   **ระบบจัดเก็บข้อมูลในเครื่องข้ามแพลตฟอร์ม (Cross-Platform Hive Database)**: จัดเก็บข้อมูลคดีและประวัติด้วย Hive Box ทำให้รองรับการทำงานในแบบไร้รอยต่อบน Web, Mobile และ Desktop โดยไม่ต้องติดตั้งไฟล์ฐานข้อมูลเพิ่ม
*   **ความปลอดภัยคีย์ผู้ใช้งาน (Keystore API Key Protection)**: เก็บรักษา Gemini API Key ของผู้ใช้อย่างปลอดภัยด้วยการเข้ารหัสผ่าน `flutter_secure_storage`
*   **การออกแบบระดับพรีเมียม (Premium UX/UI)**: หน้าจอรองรับทั้งโหมดสว่างและโหมดมืด (Material 3 Dark/Light Theme) มีหน้าจอเลือกโมเดล (Model Selection Card) และชุดป้ายตัวอย่างสถานการณ์ที่เข้าข่ายบ่อย

---

## สถาปัตยกรรมระบบ (System Architecture)

*   **UI Framework**: Flutter (Dart 3.x)
*   **Storage (Database)**: [Hive](https://pub.dev/packages/hive_flutter) (จัดเก็บประวัติการวิเคราะห์)
*   **Secure Storage**: [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) (จัดเก็บ API Key อย่างปลอดภัย)
*   **Icons**: [Flutter Lucide](https://pub.dev/packages/flutter_lucide) (ไอคอนการออกแบบที่ทันสมัย)
*   **Markdown Parsing**: [Flutter Markdown](https://pub.dev/packages/flutter_markdown) (เรนเดอร์คำตอบกฎหมายจาก AI เป็นสไตล์ Markdown)
*   **AI Integration**: Direct HTTP Client ยิงตรงเข้า Google Generative Language API

---

## ขั้นตอนการติดตั้งและใช้งาน (Getting Started)

### ความต้องการของระบบ (Prerequisites)
*   Flutter SDK เวอร์ชันล่าสุด (แนะนำ 3.22.0 ขึ้นไป)
*   เชื่อมต่ออุปกรณ์จริง หรือ Emulator สำหรับการรันระบบ

### ขั้นตอนการรันโปรเจกต์ (Installation)

1.  ดาวน์โหลด Dependencies ทั้งหมด:
    ```bash
    flutter pub get
    ```

2.  เริ่มรันแอปพลิเคชัน:
    ```bash
    flutter run
    ```

3.  **การตั้งค่า Gemini API Key**:
    เมื่อติดตั้งเสร็จแล้ว ให้เข้าไปที่เมนู **ตั้งค่า (Settings)** มุมขวาบนของหน้าแรก เพื่อป้อน Gemini API Key และเลือกโมเดลที่ต้องการใช้งาน

---

