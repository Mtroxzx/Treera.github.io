# ระยะจริง | Realtime Measure

เว็บแอปวัดระยะจากการลากจุดสแกนวัตถุ A และ B แบบเรียลไทม์ พร้อมติดตั้งเป็น PWA บนมือถือ

## เปิดใช้งานในเครื่อง

```powershell
python -m http.server 5500
```

เปิด `http://localhost:5500/`

## อัปโหลดออนไลน์ด้วย GitHub Pages

1. สร้าง repository ใหม่บน GitHub
2. อัปโหลดไฟล์ทั้งหมดในโฟลเดอร์นี้
3. ไปที่ **Settings > Pages**
4. เลือก **Deploy from a branch**, branch `main`, folder `/ (root)`
5. เปิดลิงก์ที่ GitHub สร้างให้ เช่น `https://ชื่อผู้ใช้.github.io/ชื่อโปรเจกต์/`
6. เปิดลิงก์จากมือถือ แล้วเลือกติดตั้งแอปหรือ Add to Home Screen

การเผยแพร่ผ่าน HTTPS ทำให้การขอสิทธิ์กล้องบนมือถือทำงานได้ตามปกติ
