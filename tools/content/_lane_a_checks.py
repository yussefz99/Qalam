"""Throwaway Lane-A data checks (deleted before staging)."""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
        return json.load(fh)


# 1) introOrder of the first letters + lessons alignment.
letters = load("assets/curriculum/letters.json")["letters"]
order = sorted((l["introOrder"], l["id"]) for l in letters)[:6]
print("first 6 by introOrder:", order)

lessons = load("assets/curriculum/lessons.json")["lessons"]
ordered = sorted(lessons, key=lambda x: x["order"])
print("lessons:", len(lessons))
print("first 5 lessons:", [
    (l["id"], l.get("order"),
     [i["ref"] for i in l["items"] if i["type"] == "letter"],
     l["unlock"]["requires"]) for l in ordered[:5]
])
intro = {l["id"]: l["introOrder"] for l in letters}
aligned = all(
    intro[[i["ref"] for i in l["items"] if i["type"] == "letter"][0]] == idx + 1
    for idx, l in enumerate(ordered)
)
print("lesson order == introOrder:", aligned)


# 2) Firestore nested-array legality of the v2 curriculum files.
def nested(o, path=""):
    hits = []
    if isinstance(o, list):
        for i, v in enumerate(o):
            if isinstance(v, list):
                hits.append("%s[%d]" % (path, i))
            hits += nested(v, "%s[%d]" % (path, i))
    elif isinstance(o, dict):
        for k, v in o.items():
            hits += nested(v, path + "." + k)
    return hits


for f in ("exercises", "units"):
    hits = nested(load("assets/curriculum/%s.json" % f))
    print(f, "nested-array paths:", hits[:5], "(total %d)" % len(hits))
for f in ("baa", "thaa"):
    hits = nested(load("assets/curriculum/graphs/%s.json" % f))
    print("graphs/" + f, "nested-array paths:", hits[:5], "(total %d)" % len(hits))
