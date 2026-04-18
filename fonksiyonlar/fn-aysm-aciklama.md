# fn_Aysm Fonksiyonları Referans Rehberi

Mikro ERP'nin cari yaşlandırma hesaplamalarında kullandığı `fn_Aysm` (Ay Sonu Mahsup) fonksiyonları, veritabanında **scalar function** olarak tanımlıdır. Bu fonksiyonlar Mikro tarafından otomatik oluşturulur.

> 📝 **Detaylı açıklama:** [Mikro ERP Cari Yaşlandırma SQL Sorgusu](https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu)

## Fonksiyon Listesi

### `fn_Aysm_v2_CariharBorcAlacak`

Bir cari hareket kaydının **net borç veya alacak tutarını** hesaplar.

```sql
-- Kullanım:
SELECT dbo.fn_Aysm_v2_CariharBorcAlacak(
    cha_Guid,           -- Hareket GUID
    cha_tip,            -- 0: Borç, 1: Alacak
    cha_meblag,         -- Meblağ
    cha_aratoplam,      -- Ara toplam
    ...                 -- Vergi parametreleri
) AS BorcAlacak
```

**Ne yapar:**
- `cha_tip = 0` (borç) → pozitif değer döner
- `cha_tip = 1` (alacak) → negatif değer döner
- İskonto, masraf ve vergi hesaplamalarını dahil eder
- Kısmi kapanışları (eşleşmeleri) düşer

### `fn_Aysm_v2_CariHarTarih`

Cari hareketin **gerçek tarihini** döner.

```sql
SELECT dbo.fn_Aysm_v2_CariHarTarih(
    cha_tarihi,         -- Hareket tarihi
    cha_belge_tarih     -- Belge tarihi
) AS HareketTarihi
```

**Ne yapar:**
- Genellikle `cha_tarihi` değerini döner
- Bazı evrak tiplerinde `cha_belge_tarih` kullanır

### `fn_Aysm_v2_CariHarVade`

Cari hareketin **vade tarihini** hesaplar.

```sql
SELECT dbo.fn_Aysm_v2_CariHarVade(
    cha_tarihi,         -- Hareket tarihi
    cha_vade            -- Vade (integer)
) AS VadeTarihi
```

**Ne yapar:**
- `cha_vade` integer değerini gerçek DateTime'a çevirir
- 0 ise hareket tarihini döner
- Yaşlandırma periyod hesabının temelidir

## Yaşlandırma Sorgusunda Kullanım

```sql
-- Örnek: 0-30, 31-60, 61-90, 90+ gün dilimleri
SELECT 
    cha_kod,
    SUM(CASE 
        WHEN DATEDIFF(DAY, 
            dbo.fn_Aysm_v2_CariHarVade(cha_tarihi, cha_vade), 
            GETDATE()) BETWEEN 0 AND 30
        THEN dbo.fn_Aysm_v2_CariharBorcAlacak(...)
        ELSE 0 
    END) AS [0-30 Gün],
    -- ... diğer dilimler
FROM CARI_HESAP_HAREKETLERI WITH (NOLOCK)
WHERE cha_iptal = 0 AND cha_tpoz = 0
GROUP BY cha_kod
```

## Fonksiyonlar Sisteminizde Yoksa

Eğer `fn_Aysm` fonksiyonları veritabanınızda yoksa:
1. Mikro ERP Desktop'tan ilgili raporu bir kez çalıştırın — fonksiyonları otomatik oluşturur
2. Veya `cari-yaslandirma.sql` dosyasındaki basitleştirilmiş sorguyu kullanın

## İlgili Kaynaklar

- [Cari Yaşlandırma SQL Sorgusu](https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu) — fn_Aysm fonksiyonlarının detaylı açıklaması
- [Vade Hesaplama](https://mikroerp.dev/blog/mikro-erp-vade-hesaplama-cha-vade-sql) — cha_vade alanının çalışma mantığı
- [Mikro ERP Sözlük](https://mikroerp.dev/sozluk) — Tüm tablo alan açıklamaları
