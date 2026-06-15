import fitz, zipfile, os, glob, json, collections
SRC = 'tools/curriculum/source/رنو'
OUT = 'tools/curriculum/render'
os.makedirs(OUT, exist_ok=True)
summary = []
for path in sorted(glob.glob(os.path.join(SRC, '*'))):
    name = os.path.basename(path)
    stem = os.path.splitext(name)[0]
    safe = stem.replace('/', '_')[:60]
    d = os.path.join(OUT, safe); os.makedirs(d, exist_ok=True)
    rec = {'file': name, 'stem': stem, 'kind': None, 'pages': 0, 'images': 0, 'imgexts': {}}
    if name.lower().endswith('.pdf'):
        rec['kind'] = 'pdf'
        try:
            doc = fitz.open(path)
            rec['pages'] = doc.page_count
            for pno in range(doc.page_count):
                pg = doc.load_page(pno)
                pix = pg.get_pixmap(dpi=140)
                pix.save(os.path.join(d, f'p{pno+1:03d}.png'))
            doc.close()
        except Exception as e:
            rec['error'] = str(e)
    elif name.lower().endswith('.docx'):
        rec['kind'] = 'docx'
        try:
            z = zipfile.ZipFile(path)
            media = [m for m in z.namelist() if m.startswith('word/media/')]
            exts = collections.Counter()
            for i, m in enumerate(media):
                ext = m.rsplit('.',1)[-1].lower()
                exts[ext]+=1
                data = z.read(m)
                with open(os.path.join(d, f'm{i+1:03d}.{ext}'), 'wb') as f:
                    f.write(data)
            rec['images'] = len(media); rec['imgexts'] = dict(exts)
        except Exception as e:
            rec['error'] = str(e)
    summary.append(rec)
with open(os.path.join(OUT, '_render_summary.json'), 'w', encoding='utf-8') as f:
    json.dump(summary, f, ensure_ascii=False, indent=2)
tot_png = sum(r['pages'] for r in summary if r['kind']=='pdf')
tot_media = sum(r['images'] for r in summary if r['kind']=='docx')
allexts = collections.Counter()
for r in summary:
    for k,v in r.get('imgexts',{}).items(): allexts[k]+=v
print(f'PDFs: {sum(1 for r in summary if r["kind"]=="pdf")}  ->  {tot_png} page PNGs')
print(f'DOCX: {sum(1 for r in summary if r["kind"]=="docx")}  ->  {tot_media} embedded media  (exts: {dict(allexts)})')
print(f'TOTAL renderable images (png pages + docx media): {tot_png + tot_media}')
errs = [r for r in summary if 'error' in r]
print('ERRORS:', len(errs))
for r in errs[:5]: print('  ', r['file'], '->', r['error'])
