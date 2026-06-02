import re, json, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
paths=open('lib/nucleo/constantes/firestore_paths.dart',encoding='utf-8').read()
rules=open('firestore.rules',encoding='utf-8').read()
idx=json.load(open('firestore.indexes.json',encoding='utf-8'))

consts=set(re.findall(r"String\s+\w+\s*=\s*'([a-zA-Z]+)';",paths))
rule_cols=set(re.findall(r"match /([a-zA-Z]+)/\{",rules))
idx_cols=set(i['collectionGroup'] for i in idx['indexes'])

print("FirestorePaths colecciones:", sorted(consts))
print("rules match colecciones   :", sorted(rule_cols))
print("indexes collectionGroups  :", sorted(idx_cols))
print()
print("En rules pero NO en paths:", sorted(rule_cols-consts) or "ninguna")
print("En paths pero NO en rules:", sorted(consts-rule_cols) or "ninguna")
print("collectionGroups sin entrada en paths:", sorted(idx_cols-consts) or "ninguna")

models={
 'pagos':'lib/modelos/pago_model.dart',
 'notificaciones':'lib/modelos/notificacion_model.dart',
 'chats':'lib/modelos/chat_model.dart',
 'reportes':'lib/modelos/reporte_model.dart',
}
print("\n--- campos de indices presentes en toMap del modelo ---")
allok=True
for i in idx['indexes']:
    cg=i['collectionGroup']
    if cg not in models: continue
    body=open(models[cg],encoding='utf-8').read()
    for f in i['fields']:
        fp=f['fieldPath']
        ok = ("'%s'"%fp) in body
        if not ok: allok=False
        print("  %s.%s: %s"%(cg,fp,'OK' if ok else 'FALTA'))
print("\nRESULTADO:", "TODO CONSISTENTE" if allok else "HAY CAMPOS FALTANTES")
