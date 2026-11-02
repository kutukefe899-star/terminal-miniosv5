import os
import socket
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog
from http.server import HTTPServer, SimpleHTTPRequestHandler

class HTMLServerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Yerel Ağ HTML Sunucusu")
        self.root.geometry("400x250")
        self.root.resizable(False, False)

        self.server = None
        self.server_thread = None
        self.selected_file = None
        self.port = None

        # Arayüz Bileşenleri
        self.label_title = tk.Label(root, text="Python Yerel Ağ Sunucusu", font=("Arial", 12, "bold"))
        self.label_title.pack(pady=15)

        self.btn_select = tk.Button(root, text="HTML Dosyası Seç", font=("Arial", 10), command=self.select_file, width=25, height=2)
        self.btn_select.pack(pady=5)

        self.lbl_file_status = tk.Label(root, text="Seçilen Dosya: Yok", font=("Arial", 9), fg="gray")
        self.lbl_file_status.pack(pady=5)

        self.btn_start = tk.Button(root, text="Sunucuyu Başlat", font=("Arial", 10, "bold"), bg="#4CAF50", fg="white", command=self.start_server, width=25, height=2, state=tk.DISABLED)
        self.btn_start.pack(pady=10)

    def select_file(self):
        file_path = filedialog.askopenfilename(
            title="HTML Dosyası Seçin",
            filetypes=[("HTML Dosyaları", "*.html;*.htm"), ("Tüm Dosyalar", "*.*")]
        )
        if file_path:
            self.selected_file = file_path
            file_name = os.path.basename(file_path)
            self.lbl_file_status.config(text=f"Seçilen Dosya: {file_name}", fg="black")
            self.btn_start.config(state=tk.NORMAL)

    def get_local_ip(self):
        try:
            # Yerel IP adresini socket üzerinden öğrenme
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"

    def start_server(self):
        # Port numarası iste
        port_str = simpledialog.askstring("Port Seçimi", "Lütfen bir port numarası girin (Örn: 8080):", initialvalue="8080")
        
        if not port_str:
            return
        
        try:
            self.port = int(port_str)
        except ValueError:
            messagebox.showerror("Hata", "Geçersiz port numarası! Lütfen bir sayı girin.")
            return

        file_dir = os.path.dirname(self.selected_file)
        file_name = os.path.basename(self.selected_file)
        local_ip = self.get_local_ip()

        # HTTP isteği geldiğinde sadece seçilen dosyayı sunmak için handler özelleştirmesi
        class CustomHandler(SimpleHTTPRequestHandler):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, directory=file_dir, **kwargs)

            def translate_path(self, path):
                # Kök dizine gelen istekleri doğrudan seçilen dosyaya yönlendir
                if path == '/' or path == '':
                    return os.path.join(file_dir, file_name)
                return super().translate_path(path)

        try:
            # 0.0.0.0 kullanarak yerel ağdaki herkesin erişmesini sağlıyoruz
            self.server = HTTPServer(('0.0.0.0', self.port), CustomHandler)
        except Exception as e:
            messagebox.showerror("Sunucu Hatası", f"Sunucu başlatılamadı:\n{e}")
            return

        # Arayüzü güncelle ve kilitle
        self.btn_select.config(state=tk.DISABLED)
        self.btn_start.config(state=tk.DISABLED, text="Sunucu Çalışıyor...", bg="#f44336")

        access_url = f"http://{local_ip}:{self.port}"
        
        # Sunucuyu arka planda (thread içinde) çalıştır ki arayüz donmasın
        self.server_thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.server_thread.start()

        messagebox.showinfo(
            "Sunucu Aktif!",
            f"Sunucu başarıyla başlatıldı!\n\n"
            f"Kendi bilgisayarından erişmek için:\nhttp://localhost:{self.port}\n\n"
            f"Yerel ağdaki diğer cihazların erişmesi için:\n{access_url}"
        )

if __name__ == "__main__":
    root = tk.Tk()
    app = HTMLServerApp(root)
    root.mainloop()
