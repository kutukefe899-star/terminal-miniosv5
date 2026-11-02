#!/usr/bin/env bash

# dialog kontrolü
if ! command -v dialog &> /dev/null; then
    echo "Hata: 'dialog' paketi kurulu değil. Kurmak için: sudo apt install dialog"
    exit 1
fi

CURRENT_DIR="$(pwd)"

# Metin Düzenleyici ve Dosya İşlemleri Menüsü
text_editor_menu() {
    local file="$1"
    
    while true; do
        EDIT_CHOICE=$(dialog --title "Gelişmiş Metin Düzenleyici: $(basename "$file")" --menu "İşlem seçin:" 18 70 6 \
            "1" "Nano ile Düzenle (Standart)" \
            "2" "Dosyayı Ekranda Oku (TextBox)" \
            "3" "Dosyanın Sonuna Metin Ekle" \
            "4" "Dosya İçeriğini Tamamen Temizle" \
            "5" "Satır / Kelime Sayısı (wc)" \
            "6" "Geri Dön" 3>&1 1>&2 2>&3)
            
        case "$EDIT_CHOICE" in
            1)
                clear
                nano "$file"
                ;;
            2)
                dialog --title "Dosya İçeriği: $(basename "$file")" --textbox "$file" 22 78
                ;;
            3)
                APPEND_TEXT=$(dialog --title "Metin Ekle" --inputbox "Dosyanın sonuna eklenecek metni girin:" 10 60 3>&1 1>&2 2>&3)
                if [ -n "$APPEND_TEXT" ]; then
                    echo "$APPEND_TEXT" >> "$file"
                    dialog --title "Başarılı" --msgbox "Metne ekleme yapıldı!" 8 40
                fi
                ;;
            4)
                if dialog --title "Uyarı" --yesno "'$file' dosyasının içeriği sıfırlansın mı?" 10 50; then
                    > "$file"
                    dialog --title "Bilgi" --msgbox "Dosya içeriği temizlendi." 8 40
                fi
                ;;
            5)
                STATS=$(wc "$file" | awk '{print "Satır Sayısı: " $1 "\nKelime Sayısı: " $2 "\nKarakter/Bayt: " $3}')
                dialog --title "Dosya İstatistikleri" --msgbox "$STATS" 12 50
                ;;
            *)
                break
                ;;
        esac
    done
}

# Dosya Yönetim / Özellikler Menüsü
file_properties() {
    local item="$1"
    INFO=$(ls -lh "$item" | awk '{print "İzinler: " $1 "\nSahibi: " $3 ":" $4 "\nBoyut: " $5 "\nDeğiştirme: " $6 " " $7 " " $8}')
    
    ACTION=$(dialog --title "Dosya Özellikleri: $(basename "$item")" --menu "$INFO" 18 65 4 \
        "1" "İzinleri Değiştir (chmod)" \
        "2" "Kopyala" \
        "3" "Taşı / Yeniden Adlandır" \
        "4" "Kapat" 3>&1 1>&2 2>&3)
        
    case "$ACTION" in
        1)
            NEW_PERM=$(dialog --title "chmod" --inputbox "Yeni izin değerini girin (Örn: 755 veya +x):" 10 50 3>&1 1>&2 2>&3)
            if [ -n "$NEW_PERM" ]; then
                chmod "$NEW_PERM" "$item" 2>/dev/null && dialog --msgbox "İzinler başarıyla güncellendi." 8 40 || dialog --msgbox "Hata: İzinler değiştirilemedi!" 8 40
            fi
            ;;
        2)
            DEST=$(dialog --title "Kopyala" --inputbox "Hedef dizini veya yeni yolu girin:" 10 60 "$CURRENT_DIR/" 3>&1 1>&2 2>&3)
            if [ -n "$DEST" ]; then
                cp -r "$item" "$DEST" 2>/dev/null && dialog --msgbox "Dosya kopyalandı." 8 40 || dialog --msgbox "Hata oluştu!" 8 40
            fi
            ;;
        3)
            NEW_NAME=$(dialog --title "Taşı / Yeniden Adlandır" --inputbox "Yeni adı veya konumu girin:" 10 60 "$item" 3>&1 1>&2 2>&3)
            if [ -n "$NEW_NAME" ]; then
                mv "$item" "$NEW_NAME" 2>/dev/null && dialog --msgbox "İşlem başarılı." 8 40 || dialog --msgbox "Hata oluştu!" 8 40
            fi
            ;;
    esac
}

# Ana Çalışma Döngüsü
while true; do
    MENU_ITEMS=()
    MENU_ITEMS+=(".." "[ Üst Dizin ]")
    MENU_ITEMS+=("[ YENİ DOSYA ]" "Boş metin dosyası oluştur ve nano ile aç")
    MENU_ITEMS+=("[ YENİ KLASÖR ]" "Yeni dizin oluştur")
    MENU_ITEMS+=("[ DOSYA ARA ]" "Bu dizinde ve alt klasörlerde arama yap")
    MENU_ITEMS+=("[ DİZİN BİLGİSİ ]" "Disk kullanımı ve klasör boyutunu gör")
    
    # Klasörler Önce
    for item in "$CURRENT_DIR"/*; do
        [ -d "$item" ] || continue
        name=$(basename "$item")
        MENU_ITEMS+=("$name/" "[KLASÖR]")
    done
    
    # Sonra Dosyalar
    for item in "$CURRENT_DIR"/*; do
        [ -f "$item" ] || continue
        name=$(basename "$item")
        size=$(ls -lh "$item" | awk '{print $5}')
        MENU_ITEMS+=("$name" "[DOSYA - $size]")
    done

    # Ana Dialog Ekranı
    SELECTION=$(dialog --title "Dialog Dosya Yöneticisi - Aktif Yol: $CURRENT_DIR" \
        --menu "Klasörler üstte, dosyalar alttadır. İşlem seçin:" 23 78 13 \
        "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)

    # Çıkış kontrolü (İptal / ESC)
    if [ $? -ne 0 ]; then
        clear
        echo "Dosya yöneticisinden çıkıldı."
        exit 0
    fi

    case "$SELECTION" in
        "..")
            CURRENT_DIR=$(dirname "$CURRENT_DIR")
            ;;
        "[ YENİ DOSYA ]")
            NEW_FILE=$(dialog --title "Yeni Dosya" --inputbox "Oluşturulacak dosya adını girin:" 10 50 3>&1 1>&2 2>&3)
            if [ -n "$NEW_FILE" ]; then
                touch "$CURRENT_DIR/$NEW_FILE"
                clear
                nano "$CURRENT_DIR/$NEW_FILE"
            fi
            ;;
        "[ YENİ KLASÖR ]")
            NEW_DIR=$(dialog --title "Yeni Klasör" --inputbox "Klasör adını girin:" 10 50 3>&1 1>&2 2>&3)
            if [ -n "$NEW_DIR" ]; then
                mkdir -p "$CURRENT_DIR/$NEW_DIR"
            fi
            ;;
        "[ DOSYA ARA ]")
            SEARCH_TERM=$(dialog --title "Arama" --inputbox "Aranacak kelime veya dosya adı:" 10 50 3>&1 1>&2 2>&3)
            if [ -n "$SEARCH_TERM" ]; then
                FIND_RESULTS=$(find "$CURRENT_DIR" -maxdepth 3 -iname "*$SEARCH_TERM*" 2>/dev/null | head -n 20)
                dialog --title "Arama Sonuçları (İlk 20)" --msgbox "${FIND_RESULTS:-Eşleşen sonuç bulunamadı.}" 18 70
            fi
            ;;
        "[ DİZİN BİLGİSİ ]")
            DISK_USAGE=$(df -h "$CURRENT_DIR" | tail -n 1 | awk '{print "Toplam Alan: " $2 "\nKullanılan: " $3 "\nBoş Alan: " $4 "\nKullanım Oranı: " $5}')
            FOLDER_SIZE=$(du -sh "$CURRENT_DIR" 2>/dev/null | awk '{print $1}')
            dialog --title "Dizin Raporu" --msgbox "Konum: $CURRENT_DIR\nKlasör Boyutu: $FOLDER_SIZE\n\nDisk Durumu:\n$DISK_USAGE" 16 60
            ;;
        *)
            TARGET="$CURRENT_DIR/$SELECTION"
            TARGET=${TARGET%/}
            
            if [ -d "$TARGET" ]; then
                CURRENT_DIR="$TARGET"
            elif [ -f "$TARGET" ]; then
                FILE_ACTION=$(dialog --title "Dosya: $(basename "$TARGET")" --menu "Ne yapmak istiyorsunuz?" 16 65 5 \
                    "1" "Nano ile Düzenle" \
                    "2" "Özellikler / İzinler / Kopyala" \
                    "3" "Dosyayı Kalıcı Olarak Sil" \
                    "4" "Geri Dön" 3>&1 1>&2 2>&3)
                    
                case "$FILE_ACTION" in
                    1)
                        clear
                        nano "$TARGET"
                        ;;
                    2)
                        file_properties "$TARGET"
                        ;;
                    3)
                        if dialog --title "Silme Onayı" --yesno "'$(basename "$TARGET")' silinsin mi?" 10 50; then
                            rm -f "$TARGET"
                            dialog --msgbox "Dosya silindi." 8 40
                        fi
                        ;;
                esac
            fi
            ;;
    esac
done
