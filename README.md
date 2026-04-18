<div align="center">

# 🏢 Mikro ERP SQL Sorgu Rehberi

**Mikro ERP veritabanı için hazır SQL sorguları, fonksiyon referansları ve entegrasyon rehberleri.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Mikro ERP](https://img.shields.io/badge/Mikro_ERP-V16%2FV17-E30613)](https://www.mikro.com.tr)
[![SQL Server](https://img.shields.io/badge/SQL_Server-2016+-CC2927?logo=microsoftsqlserver)](https://www.microsoft.com/sql-server)
[![Blog](https://img.shields.io/badge/Blog-mikroerp.dev-3b82f6)](https://mikroerp.dev)

<p>
  <a href="https://mikroerp.dev">📖 Blog</a> •
  <a href="https://mikroerp.dev/sozluk">📚 Sözlük</a> •
  <a href="https://mikroerp.dev/case-study">🏗️ Case Study</a> •
  <a href="https://apidocs.mikro.com.tr">📋 Mikro API Docs</a>
</p>

---

*Gerçek üretim ortamında test edilmiş, 8 şubeli kurumsal yapıda kullanılan SQL sorguları.*

</div>

## 📋 İçindekiler

- [🎯 Neden Bu Repo?](#-neden-bu-repo)
- [💰 Cari Hesap Sorguları](#-cari-hesap-sorguları)
- [📦 Stok Sorguları](#-stok-sorguları)
- [📊 Satış & Finans Sorguları](#-satış--finans-sorguları)
- [⚙️ Fonksiyonlar](#️-fonksiyonlar)
- [⚠️ Kullanım Uyarıları](#️-kullanım-uyarıları)
- [🤝 Katkıda Bulunma](#-katkıda-bulunma)

---

## 🎯 Neden Bu Repo?

Mikro ERP'nin dahili raporlama aracı tek tek müşteriler için yeterli olsa da:

- **Tüm carilerin** yaşlandırmasını tek seferde çekmek istiyorsanız
- Sonuçları **web dashboard'a**, Excel'e veya başka bir sisteme aktaracaksanız
- Birden fazla **şube veritabanını** tek raporda birleştirmek istiyorsanız
- **Otomatik** günlük rapor oluşturmak istiyorsanız

...bu sorguları direkt kullanabilirsiniz.

> 💡 Her sorgunun detaylı açıklaması [mikroerp.dev](https://mikroerp.dev) blogunda mevcuttur.

---

## 💰 Cari Hesap Sorguları

| Dosya | Açıklama | Blog Yazısı |
|-------|----------|-------------|
| [`cari/cari-yaslandirma.sql`](cari/cari-yaslandirma.sql) | Bakiye dağıtımlı FIFO yaşlandırma | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu) |
| [`cari/cari-ekstre.sql`](cari/cari-ekstre.sql) | Cari hesap ekstre raporu | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-cari-ekstre-raporu-sql) |
| [`cari/cari-risk-raporu.sql`](cari/cari-risk-raporu.sql) | Cari risk ve limit analizi | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-cari-risk-raporu-sql) |
| [`cari/kapanmamis-hareketler.sql`](cari/kapanmamis-hareketler.sql) | Açık/kapanmamış cari hareketler | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-kapanmamis-cari-hareket-sql) |
| [`cari/belge-no-arama.sql`](cari/belge-no-arama.sql) | Belge numarasıyla hareket bulma | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-belge-no-cari-hareket-bulma-sql) |
| [`cari/vade-hesaplama.sql`](cari/vade-hesaplama.sql) | cha_vade → gerçek tarih hesaplama | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-vade-hesaplama-cha-vade-sql) |

## 📦 Stok Sorguları

| Dosya | Açıklama | Blog Yazısı |
|-------|----------|-------------|
| [`stok/depo-bazli-bakiye.sql`](stok/depo-bazli-bakiye.sql) | Depo bazlı stok bakiye raporu | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-depo-bazli-stok-bakiye-sql) |
| [`stok/son-alis-fiyati.sql`](stok/son-alis-fiyati.sql) | Son alış fiyatı raporu | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-son-alis-fiyati-sql) |
| [`stok/fiyat-listesi-kontrol.sql`](stok/fiyat-listesi-kontrol.sql) | Fiyat listesi kontrol ve karşılaştırma | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-fiyat-listesi-kontrol-sql) |

## 📊 Satış & Finans Sorguları

| Dosya | Açıklama | Blog Yazısı |
|-------|----------|-------------|
| [`satis/satis-raporu.sql`](satis/satis-raporu.sql) | Satış raporu (dönemsel) | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-satis-raporu-sql) |
| [`satis/alis-satis-kar.sql`](satis/alis-satis-kar.sql) | Alış-satış kar analizi | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-alis-satis-kar-analizi-sql) |
| [`satis/acik-siparis-teslimat.sql`](satis/acik-siparis-teslimat.sql) | Açık sipariş ve teslimat takip | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-acik-siparis-teslimat-raporu-sql) |
| [`satis/fatura-siparis-eslestirme.sql`](satis/fatura-siparis-eslestirme.sql) | Fatura-sipariş eşleştirme | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-fatura-siparis-eslestirme-sql) |
| [`finans/banka-bakiye.sql`](finans/banka-bakiye.sql) | Banka hesap bakiyeleri | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-banka-hesap-bakiye-sql) |
| [`finans/cek-senet-vade.sql`](finans/cek-senet-vade.sql) | Çek/senet vade takip | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-cek-senet-vade-takip-sql) |
| [`finans/kasa-nakit-akis.sql`](finans/kasa-nakit-akis.sql) | Kasa nakit akış raporu | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-kasa-nakit-akis-raporu-sql) |
| [`finans/kur-farki-kontrol.sql`](finans/kur-farki-kontrol.sql) | Döviz kur farkı kontrol | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-kur-farki-kontrol-sql) |

## ⚙️ Fonksiyonlar

| Dosya | Açıklama | Blog Yazısı |
|-------|----------|-------------|
| [`fonksiyonlar/fn-aysm-aciklama.md`](fonksiyonlar/fn-aysm-aciklama.md) | fn_Aysm fonksiyonları referans rehberi | [📝 Oku](https://mikroerp.dev/blog/mikro-erp-cari-yaslandirma-sql-sorgusu) |

---

## ⚠️ Kullanım Uyarıları

> **ÖNEMLİ:** Bu sorgular üretim veritabanlarında çalıştırılmak üzere tasarlanmıştır. Lütfen dikkat edin:

1. **`WITH (NOLOCK)`** — Tüm SELECT sorguları `WITH (NOLOCK)` kullanmalıdır. Bu, üretim ortamında kilitlenmeleri önler.

2. **Veritabanı Adı** — Sorgulardaki veritabanı adlarını kendi ortamınıza göre değiştirin:
   ```sql
   -- Kendi ortamınıza göre değiştirin:
   USE [MikroDesktop_SUBE_ADI]
   ```

3. **Yedekleme** — Herhangi bir UPDATE/INSERT sorgusu çalıştırmadan önce mutlaka yedek alın.

4. **Şube Yapısı** — Çok şubeli yapılarda her şubenin ayrı veritabanı olduğunu unutmayın.

---

## 🏗️ Proje Bağlamı

Bu sorgular, **AstaFlow** kurumsal iş yönetim platformunda aktif olarak kullanılmaktadır:

- 🏢 8 şubeli reklam ajansı
- 📊 15+ modül (Stok, Satış, Cari, Sipariş, Tahsilat...)
- ⚡ Mikro ERP → Supabase (PostgreSQL) senkronizasyonu
- 🌐 React + TypeScript web dashboard

Detaylı case study: [mikroerp.dev/case-study](https://mikroerp.dev/case-study)

---

## 📚 Ek Kaynaklar

- [📖 MikroERP.dev Blog](https://mikroerp.dev) — Tüm rehberler ve yazılar
- [📋 Mikro ERP Sözlük](https://mikroerp.dev/sozluk) — Tablo alan açıklamaları
- [🔗 Mikro API Docs](https://apidocs.mikro.com.tr) — Resmi API dokümantasyonu
- [📺 Mikro API Eğitim Videoları](https://www.youtube.com/playlist?list=PLygZWyaCH67-bTF0WRR6v98l4DEoZ52we)

---

## 🤝 Katkıda Bulunma

Yeni sorgular eklemek, mevcut sorguları iyileştirmek veya hata bildirmek için:

1. 🍴 Fork edin
2. 🔧 Değişiklik yapın (her `.sql` dosyasının başında açıklama bloğu olmalı)
3. 📤 Pull Request gönderin

Her SQL dosyasının başına şu formatı ekleyin:

```sql
-- ============================================
-- Mikro ERP: [Sorgu Açıklaması]
-- Kaynak: https://mikroerp.dev/blog/[yazı-slug]
-- Uyumluluk: Mikro V16, V17
-- Son Güncelleme: [Tarih]
-- ============================================
```

---

## 📄 Lisans

MIT License — Ticari ve kişisel projelerinizde serbestçe kullanabilirsiniz.

---

<div align="center">
  <sub>
    ❤️ <a href="https://mikroerp.dev">MikroERP.dev</a> tarafından geliştirilmiştir ·
    <a href="https://www.astareklam.com.tr">Asta Reklam</a>
  </sub>
</div>
