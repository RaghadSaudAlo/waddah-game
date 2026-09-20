# Deployment Guide

How to build, deploy, and maintain Waddah. Paths assume the repository is
cloned to `D:\waddah`.

There are two deployable pieces:

| | What it is | Hosting |
|---|---|---|
| **The game** | Flutter web app | Firebase Hosting |
| **The model API** | FastAPI + HuBERT CTC | Hugging Face Docker Space |

The game runs standalone: no server, no API keys, no runtime cost. All Arabic
speech is generated ahead of time and bundled as assets, so the deployed build
makes no outbound calls.

---

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.47.5 (Dart 3.13.4) |
| Node.js | 24.x |
| firebase-tools | 15.x |
| Python | 3.10+ |

On Windows, keep the tool caches off the system drive — they grow to several
gigabytes:

```powershell
[Environment]::SetEnvironmentVariable('PUB_CACHE',     'D:\sdk\pub-cache', 'User')
[Environment]::SetEnvironmentVariable('PIP_CACHE_DIR', 'D:\sdk\pip-cache', 'User')
[Environment]::SetEnvironmentVariable('HF_HOME',       'D:\sdk\hf-cache',  'User')
```

---

## Deploying the game

### First time only

```powershell
firebase login
cd D:\waddah
firebase use --add        # select the project, alias it "default"
```

### Every deploy

```powershell
cd D:\waddah\app
flutter build web --release

cd D:\waddah
firebase deploy --only hosting
```

The hosting URL is printed at the end.

> Use `--release`. A debug web build ships the Dart development compiler and is
> several times larger and noticeably slower to load on a tablet.

### Before a live demo

1. Open the URL on the device you will present from — microphone permission is
   granted per-origin, per-browser.
2. Allow the microphone. Recording requires HTTPS, which Firebase Hosting
   provides; plain `http://` or a raw IP will fail silently.
3. Load the page once beforehand so assets are cached.

---

## Changing spoken text

The app speaks from pre-generated audio, matched on the exact string. Editing a
prompt in Dart without regenerating leaves that line with no clip.

```powershell
cd D:\waddah
python tools/check_audio_coverage.py
```

If it reports an unmatched line, add the exact string to `build_texts()` in
`tools/generate_audio.py`, then:

```powershell
# requires ELEVENLABS_API_KEY in services/therapy-api/.env (gitignored)
python tools/generate_audio.py        # generates only what is missing
python tools/check_audio_coverage.py  # must pass
```

> The coverage check exists because this is the one failure in the build that
> produces no error anywhere — the manifest key includes whitespace and
> newlines, so an invisible edit is enough to break the match.

---

## Deploying the model API

### 1. Publish the weights

Push the checkpoint to a **private** Hugging Face model repository using the
block at the bottom of `ml/colab/03_SAVE_EVERYTHING.py`. The model is derived
from children's speech and must not be public.

### 2. Create the Space

<https://huggingface.co/new-space> → SDK **Docker** → **Blank**.

```powershell
cd D:\waddah\api
git init
git remote add space https://huggingface.co/spaces/<user>/waddah-api
git add -A
git commit -m "Waddah MDD API"
git push space main
```

> `api/` is laid out to be a Space root in its own right — the Dockerfile and
> requirements sit at its top level, which is where a Space expects them.

### 3. Configure secrets

Space settings → **Variables and secrets**:

| Name | Kind | Value |
|---|---|---|
| `WADDAH_MODEL_REPO` | variable | `<user>/waddah-ctc-v3` |
| `HF_TOKEN` | secret | a **read** token |

> A read token is sufficient — the Space only downloads. A write token in a
> Space environment can modify every repository on the account.

### 4. Point the app at it

```powershell
cd D:\waddah\app
flutter build web --release --dart-define=WADDAH_API=https://<user>-waddah-api.hf.space

cd D:\waddah
firebase deploy --only hosting
```

A free Space sleeps after 48 hours idle and takes up to a minute to wake. Open
`/health` once before a demo to warm it.

---

## Android build

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK
winget install --id Google.AndroidStudio

flutter config --android-sdk "D:\Android\Sdk"
flutter doctor --android-licenses

cd D:\waddah\app
flutter build apk --release
```

Two changes are required before distributing an APK:

1. Set a real `applicationId` in `app/android/app/build.gradle.kts` — the
   Play Store rejects the `com.example.*` namespace.
2. Configure a release signing key. Debug-signed builds are fine for Firebase
   App Distribution but cannot be published.

Upload the APK through Firebase Console → App Distribution.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| A prompt plays nothing | that exact string has no clip | `python tools/check_audio_coverage.py` |
| Microphone does nothing on web | not served over HTTPS, or permission denied | use the `.web.app` URL; reset site permissions |
| `pub get` fails, "entry in use" | system drive full | redirect caches (see Prerequisites) |
| `flutter build web` fails on `dart:io` | a file imported `dart:io` or `path_provider` directly | route it through `app/lib/services/recording_store.dart` |
| Deploy succeeds but the page is stale | `main.dart.js` cached | handled in `firebase.json`; hard-refresh once |
| Space returns 503 | cold start | wait, or call `/health` first |
| Space fails to start, lexicon SHA mismatch | `shared/arabic_phoneme_lexicon.csv` changed after training | intentional guard — every model output index derives from that file |
