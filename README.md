# Challenge 3 Sedaf

## Development Workflow

Repository ini menggunakan dua branch utama:

- `main` sebagai branch utama yang stabil dan siap dirilis.
- `development` sebagai branch integrasi untuk pengembangan fitur sebelum masuk ke `main`.

Branch `main` dan `development` dilindungi menggunakan ruleset yang sama.

## Branch Policy

Branch yang dilindungi:

```text
main
development
```

Aturan untuk branch `main` dan `development`:

- Tidak diperbolehkan melakukan direct push.
- Semua perubahan harus dilakukan melalui Pull Request.
- Pull Request wajib direview sebelum merge, jika required approval diaktifkan.
- Conversation pada Pull Request harus diselesaikan sebelum merge.
- Force push tidak diperbolehkan.
- Delete branch tidak diperbolehkan.
- Ruleset tidak boleh di-bypass kecuali oleh actor yang diberi izin secara eksplisit.

## Branch Usage

### `main`

Branch `main` berisi kode stabil dan siap dirilis.

Merge ke `main` hanya dilakukan melalui Pull Request dari:

```text
development
hotfix/*
release/*
```

Contoh:

```text
development → main
hotfix/crash-on-launch → main
release/1.0.0 → main
```

### `development`

Branch `development` digunakan untuk integrasi fitur dan perbaikan sebelum masuk ke `main`.

Merge ke `development` dilakukan melalui Pull Request dari:

```text
feature/*
bugfix/*
```

Contoh:

```text
feature/keynote-control → development
feature/speech-feedback → development
bugfix/audio-permission → development
```

## Branch Naming

Gunakan format branch berikut:

```text
feature/<nama-fitur>
bugfix/<nama-bug>
hotfix/<nama-hotfix>
release/<versi>
```

Contoh:

```text
feature/keynote-control
feature/speech-feedback
bugfix/audio-permission
hotfix/crash-on-launch
release/1.0.0
```

## Workflow

### Membuat Feature Branch

Pastikan branch `development` lokal sudah terbaru.

```bash
git checkout development
git pull origin development
```

Buat branch fitur dari `development`.

```bash
git checkout -b feature/nama-fitur
```

Commit dan push perubahan.

```bash
git add .
git commit -m "Add feature name"
git push origin feature/nama-fitur
```

Buat Pull Request ke `development`.

```text
feature/nama-fitur → development
```

### Merge ke `main`

Setelah kode di `development` sudah stabil dan siap dirilis, buat Pull Request ke `main`.

```text
development → main
```

Pull Request ke `main` harus dipastikan aman sebelum merge.

## Merge Policy

- Semua perubahan ke `main` dan `development` harus melalui Pull Request.
- Gunakan squash merge agar history branch utama tetap rapi.
- Hapus branch setelah Pull Request berhasil di-merge.
- Jangan merge kode yang belum dites ke `main`.

## Recommended Commit Message

Gunakan pesan commit yang singkat dan jelas.

Contoh:

```text
Add speech training session view
Fix microphone permission handling
Update keynote integration flow
Refactor audio recording service
```

Halo, aku sande. Aku cobain branch ku...
