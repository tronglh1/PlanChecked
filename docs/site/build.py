#!/usr/bin/env python3
"""Regenerates docs/site/privacy.html from docs/privacy-policy.{vi,en}.md.

Usage:  python3 docs/site/build.py
Only the privacy page is generated; index.html and delete-account.html are hand-written.
"""
import html
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)


def inline(t):
    t = html.escape(t, quote=False)
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"(https?://[^\s)<,]+[^\s).,<])", r'<a href="\1">\1</a>', t)
    t = t.replace("delete-account.html", '<a href="delete-account.html">delete-account.html</a>')
    return t


def md(src):
    out, lines, i = [], src.split("\n"), 0
    para, lst, tbl = [], [], []

    def flush():
        nonlocal para, lst, tbl
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
        if lst:
            out.append("<ul>" + "".join("<li>%s</li>" % inline(x) for x in lst) + "</ul>")
        if tbl:
            rows = [[c.strip() for c in r.strip().strip("|").split("|")] for r in tbl]
            rows = [r for r in rows if not all(re.fullmatch(r"-+", c) for c in r)]
            h = "".join("<th>%s</th>" % inline(c) for c in rows[0])
            b = "".join("<tr>" + "".join("<td>%s</td>" % inline(c) for c in r) + "</tr>" for r in rows[1:])
            out.append('<div class="tw"><table><thead><tr>%s</tr></thead><tbody>%s</tbody></table></div>' % (h, b))
        para, lst, tbl = [], [], []

    for ln in lines:
        if ln.startswith("# "):
            flush()
            out.append("<h1>%s</h1>" % inline(ln[2:]))
        elif ln.startswith("## "):
            flush()
            out.append("<h2>%s</h2>" % inline(ln[3:]))
        elif ln.startswith("- "):
            if para or tbl:
                flush()
            lst.append(ln[2:])
        elif ln.startswith("|"):
            if para or lst:
                flush()
            tbl.append(ln)
        elif ln.strip() == "":
            flush()
        else:
            if lst or tbl:
                flush()
            para.append(ln.strip())
    flush()
    return "\n".join(out)


def read(name):
    with open(os.path.join(DOCS, name), encoding="utf-8") as f:
        return f.read()


PAGE = """<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Chính sách quyền riêng tư – Vườn Nhà</title>
<meta name="description" content="Chính sách quyền riêng tư của ứng dụng Vườn Nhà / Privacy policy of the Vườn Nhà app.">
<link rel="stylesheet" href="style.css">
</head>
<body>
<div class="blob b1"></div><div class="blob b2"></div>
<header class="top"><a class="brand" href="index.html">Vườn Nhà</a>
<nav><a href="index.html">Trang chủ</a><a href="privacy.html" aria-current="page">Quyền riêng tư</a><a href="delete-account.html">Xoá tài khoản</a></nav></header>
<main>
<input type="radio" name="lang" id="l-vi" checked><input type="radio" name="lang" id="l-en">
<div class="langs"><label for="l-vi">Tiếng Việt</label><label for="l-en">English</label></div>
<article class="card doc doc-vi" lang="vi">
{vi}
</article>
<article class="card doc doc-en" lang="en">
{en}
</article>
</main>
<footer>&copy; Vườn Nhà · <a href="mailto:&lt;EMAIL_LIÊN_HỆ&gt;">&lt;EMAIL_LIÊN_HỆ&gt;</a></footer>
</body>
</html>
"""

with open(os.path.join(HERE, "privacy.html"), "w", encoding="utf-8") as f:
    f.write(PAGE.format(vi=md(read("privacy-policy.vi.md")), en=md(read("privacy-policy.en.md"))))
print("wrote docs/site/privacy.html")
