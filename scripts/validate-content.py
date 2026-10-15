import json,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
a=(root/'content/catalog.json').read_bytes()
assert len(a)<=1_000_000
c=json.loads(a)
assert c['schemaVersion']==1 and isinstance(c['revision'],int) and c['revision']>0
assert 1<=len(c['scenarios'])<=100
assert len({s['id'] for s in c['scenarios']})==len(c['scenarios'])
for s in c['scenarios']:
 for key,n in [('id',64),('title',120),('summary',4000),('practice',12000)]:
  assert isinstance(s[key],str) and 0<len(s[key].strip())<=n
 for key in ['pilotRoles','atcRoles']:
  assert 1<=len(s[key])<=20 and all(isinstance(t,str) and 0<len(t.strip())<=1000 for t in s[key])
 assert 2<=len(s['dialogue'])<=40
 assert all(x['from'] in ['PILOT','ATC'] and isinstance(x['msg'],str) and 0<len(x['msg'].strip())<=2000 for x in s['dialogue'])
assert len(c["references"])<=100
assert len({v["id"] for v in c["references"]})==len(c["references"])
import re
for v in c["references"]:
 assert re.fullmatch(r"[A-Za-z0-9_-]{11}",v["id"])
 assert 0<len(v["title"])<=200 and 0<len(v["channel"])<=120
 assert v["category"] in {s["id"] for s in c["scenarios"]}
 assert not v.get("lessonId") or v["lessonId"] in {s["id"] for s in c["scenarios"]}
assert a==(root/'ios/MaydayATC/catalog.json').read_bytes(), 'Copy catalog.json into the iOS bundle before committing'
print(f"Validated {len(c['scenarios'])} scenarios, revision {c['revision']}")
