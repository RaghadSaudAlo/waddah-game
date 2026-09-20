# وضّاح · Waddah

An Arabic speech therapy game for children aged 4–10.

Children meet a character called Waddah, repeat words after him, and get
instant feedback on their pronunciation. Words they struggle with turn into a
short practice session built around the exact sound they find difficult.

**Live demo → https://waddah-app-36358.web.app**

---

## How it works

<img src="app/assets/images/waddah.png" width="110" align="right" alt="Waddah">

1. Waddah shows a picture and says the word out loud.
2. The child taps the microphone and repeats it.
3. The recording is checked against the expected pronunciation.
4. The child gets encouragement, or a gentle "let's try again".

At the centre of the project is a **HuBERT CTC phoneme recogniser** fine-tuned
on Arabic child speech. Instead of asking "was the whole word right?", it reads
the sequence of sounds the child actually produced and aligns it against the
expected sequence — so it can identify *which* sound went wrong, and whether it
was substituted, dropped, or added.

That distinction is what makes the therapy side possible: a child who says
/س/ instead of /ش/ needs different practice from one who drops the sound
entirely.

---

## The lexicon

The vocabulary is an **84-word lexicon** covering 35 Arabic phonemes, designed
rather than collected:

- every target sound appears at the **start, middle, and end** of words
  (28 each), because children often master a sound in one position before
  another
- words are age-appropriate and picturable, so a 4-year-old can be prompted
  without reading
- the lexicon is fingerprinted with a SHA-256 hash that the API verifies at
  startup, since every model output index is derived from it

It lives in `shared/` and is read by the app, the API, and the training
notebook alike — so the word list can never drift between them.

---

## Project structure

```
waddah/
├── app/         Flutter app — the game
├── api/         FastAPI service that serves the model
├── ml/          Training notebook + Colab scripts
├── shared/      The 84-word phoneme lexicon
├── services/    Therapy planning service
├── tools/       Audio generation and verification
└── docs/        Deployment guide
```

---

## Tech stack

| | |
|---|---|
| **App** | Flutter (web + Android) |
| **Model** | PyTorch · HuggingFace Transformers · HuBERT CTC |
| **API** | FastAPI · Docker |
| **Speech** | ElevenLabs, pre-generated and bundled offline |
| **Hosting** | Firebase Hosting |

---

## Running it locally

```bash
git clone https://github.com/RaghadSaudAlo/waddah-game.git
cd waddah-game/app
flutter pub get
flutter run -d chrome
```

All 185 Arabic voice clips ship with the app, so it runs offline with no setup
and no API keys.

To deploy, or to run the model API, see **[docs/DEPLOY.md](docs/DEPLOY.md)**.

---

## Privacy

The project handles children's voice recordings, so the safeguards are built
into the code rather than left to discipline:

- recordings go to temporary storage and are **deleted as soon as the result is
  shown** — including when a request fails
- audio is captured at 16 kHz mono, the exact format the model expects, so no
  copy is kept or converted along the way
- audio files, `.env` files and model weights are blocked in `.gitignore`, so
  they cannot reach this repository by accident

---

## Team

- Ghaida Alzahrani
- Fawz Almutairi
- Sadeem Alshehri
- Rawan Alharbi
- Raghad Alotaibi
