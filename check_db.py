import json
import os
import re


os.chdir(os.path.dirname(os.path.abspath(__file__)))


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


paths = read("lib/nucleo/constantes/firestore_rutas.dart")
rules = read("firestore.rules")
idx = load_json("firestore.indexes.json")
firebase_options = read("lib/firebase_options.dart")
google_services = load_json("android/app/google-services.json")

consts = set(re.findall(r"static const String \w+\s*=\s*'([a-zA-Z]+)';", paths))
rule_cols = set(re.findall(r"match /([a-zA-Z]+)/\{", rules))
idx_cols = set(i["collectionGroup"] for i in idx.get("indexes", []))

print("FirestorePaths colecciones:", sorted(consts))
print("rules match colecciones   :", sorted(rule_cols))
print("indexes collectionGroups  :", sorted(idx_cols))
print()
print("En rules pero NO en paths:", sorted(rule_cols - consts) or "ninguna")
print("En paths pero NO en rules:", sorted(consts - rule_cols) or "ninguna")
print("collectionGroups sin entrada en paths:", sorted(idx_cols - consts) or "ninguna")

models = {
    "pagos": "lib/modelos/pago_modelo.dart",
    "notificaciones": "lib/modelos/notificacion_modelo.dart",
    "chats": "lib/modelos/chat_modelo.dart",
    "reportes": "lib/modelos/reporte_modelo.dart",
}

print("\n--- campos de índices presentes en toMap del modelo ---")
all_ok = True
for index in idx.get("indexes", []):
    cg = index["collectionGroup"]
    if cg not in models:
        continue
    body = read(models[cg])
    for field in index["fields"]:
        field_path = field["fieldPath"]
        ok = f"'{field_path}'" in body
        if not ok:
            all_ok = False
        print(f"  {cg}.{field_path}: {'OK' if ok else 'FALTA'}")

print("\n--- consistencia Firebase Android ---")
android_block = re.search(
    r"static const FirebaseOptions android = FirebaseOptions\((.*?)\n\s*\);",
    firebase_options,
    re.S,
)
firebase_values = {}
if android_block:
    for key in ("apiKey", "appId", "messagingSenderId", "projectId", "storageBucket"):
        match = re.search(rf"{key}:\s*'([^']+)'", android_block.group(1))
        firebase_values[key] = match.group(1) if match else None

google_client = google_services["client"][0]
google_values = {
    "apiKey": google_client["api_key"][0]["current_key"],
    "appId": google_client["client_info"]["mobilesdk_app_id"],
    "messagingSenderId": google_services["project_info"]["project_number"],
    "projectId": google_services["project_info"]["project_id"],
    "storageBucket": google_services["project_info"]["storage_bucket"],
}

firebase_ok = True
for key, expected in google_values.items():
    current = firebase_values.get(key)
    ok = current == expected
    firebase_ok = firebase_ok and ok
    print(f"  {key}: {'OK' if ok else 'MISMATCH'}")
    if not ok:
        print(f"    firebase_options.dart: {current}")
        print(f"    google-services.json: {expected}")

print(
    "\nRESULTADO:",
    "TODO CONSISTENTE" if all_ok and firebase_ok else "HAY INCONSISTENCIAS",
)
