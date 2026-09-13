"""Scan the release APK for embedded secrets (M6.4 security review)."""
import re
import sys
import zipfile
from pathlib import Path

BACKEND_ENV = Path(__file__).resolve().parents[2] / "backend" / ".env"
APK = Path(__file__).resolve().parents[1] / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"

SENSITIVE_KEYS = ["GEMINI_API_KEY", "OPENAI_API_KEY", "SECRET_KEY"]
PATTERNS = [
    rb"AIza[0-9A-Za-z_\-]{20,}",
    rb"sk-[A-Za-z0-9_\-]{20,}",
]


def env_value(name: str) -> str | None:
    for line in BACKEND_ENV.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.strip().startswith(name + "="):
            v = line.split("=", 1)[1].strip()
            if v and "your-" not in v and "change-me" not in v:
                return v
    return None


def main() -> int:
    secrets = {k: v for k in SENSITIVE_KEYS if (v := env_value(k))}
    print(f"Real secrets found in backend/.env: {list(secrets)}")
    if not APK.exists():
        print("APK not built yet:", APK)
        return 1

    hits = []
    with zipfile.ZipFile(APK) as zf:
        for entry in zf.namelist():
            data = zf.read(entry)
            for pat in PATTERNS:
                if re.search(pat, data):
                    hits.append((entry, f"pattern {pat!r}"))
            for name, value in secrets.items():
                if value.encode() in data:
                    hits.append((entry, f"{name} literal"))

    if hits:
        print("LEAKS FOUND:")
        for entry, what in hits:
            print(f"  {entry}: {what}")
        return 1

    # Also sanity-check the debug keystore is the only signer (expected for MVP)
    signers = [n for n in zipfile.ZipFile(APK).namelist() if n.startswith("META-INF/") and n.endswith((".RSA", ".DSA", ".EC"))]
    print(f"APK size: {APK.stat().st_size / 1024 / 1024:.1f} MB, signer blocks: {signers}")
    print("APK SECRET SCAN: CLEAN")
    return 0


if __name__ == "__main__":
    sys.exit(main())
