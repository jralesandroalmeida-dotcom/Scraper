"""
ML Scraper — Playwright Chromium com cancel, retry, paginação e cache de IDs
"""
import asyncio, random, re, json, os, time
from playwright.async_api import async_playwright

COUNTRY_LIST = {
    "BR": "lista.mercadolivre.com.br",
    "AR": "listado.mercadolibre.com.ar",
    "MX": "listado.mercadolibre.com.mx",
    "CO": "listado.mercadolibre.com.co",
    "CL": "listado.mercadolibre.cl",
}

CACHE_FILE = "scraped_ids.json"

# ── Cache de IDs ──────────────────────────────────────

def load_cache() -> dict:
    """Carrega cache do disco. Estrutura: {id: {url, nome, timestamp}}"""
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            pass
    return {}

def save_cache(cache: dict):
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)

def extract_ml_id(url: str) -> str | None:
    """Extrai o ID único do produto da URL. Ex: MLB-123456 → MLB123456"""
    m = re.search(r'(ML[A-Z])-?(\d+)', url)
    if m:
        return f"{m.group(1)}{m.group(2)}"
    return None

# ── Helpers ───────────────────────────────────────────

async def delay(a=1.0, b=3.0):
    await asyncio.sleep(random.uniform(a, b))

async def txt(el, sel, default=""):
    try:
        e = await el.query_selector(sel)
        return (await e.inner_text()).strip() if e else default
    except:
        return default

# ── Listagem ──────────────────────────────────────────

async def get_links(page, query, domain, max_items, log, cancel_event, cache):
    links, seen = [], set()
    page_num = 0
    skipped_cached = 0

    while len(links) < max_items:
        if cancel_event.is_set():
            break

        offset = page_num * 48
        url = (f"https://{domain}/{query.strip().replace(' ','-')}"
               + (f"_Desde_{offset+1}" if page_num > 0 else ""))
        log(f"Página {page_num+1}: {url}", "info")

        try:
            await page.goto(url, wait_until="domcontentloaded", timeout=40000)
            await delay(2, 3)
            for _ in range(4):
                await page.evaluate("window.scrollBy(0,600)")
                await delay(0.3, 0.6)
        except Exception as e:
            log(f"Erro ao abrir página: {e}", "err")
            break

        page_links = []
        for sel in [
            "li.ui-search-layout__item a.ui-search-link__title-card",
            "li.ui-search-layout__item a.ui-search-link",
            "li.ui-search-layout__item a.poly-component__title",
            "li.ui-search-layout__item a[href*='MLB']",
            "li.ui-search-layout__item a[href*='MLA']",
            "li.ui-search-layout__item a[href*='MLM']",
            "ol.ui-search-layout a[href*='ML']",
        ]:
            els = await page.query_selector_all(sel)
            for el in els:
                href = (await el.get_attribute("href") or "").split("?")[0].split("#")[0]
                if not href or not re.search(r'ML[A-Z]-?\d+', href):
                    continue
                if href in seen:
                    continue
                seen.add(href)

                ml_id = extract_ml_id(href)
                if ml_id and ml_id in cache:
                    skipped_cached += 1
                    continue  # já foi raspado antes

                page_links.append(href)
            if page_links:
                break

        if not page_links:
            # Fallback geral
            all_a = await page.query_selector_all("a[href]")
            for el in all_a:
                href = (await el.get_attribute("href") or "").split("?")[0]
                if not re.search(r'ML[A-Z]-?\d{5,}', href) or href in seen:
                    continue
                seen.add(href)
                ml_id = extract_ml_id(href)
                if ml_id and ml_id in cache:
                    skipped_cached += 1
                    continue
                page_links.append(href)

        if not page_links:
            log(f"Sem novos links na página {page_num+1}. Título: {await page.title()}", "warn")
            break

        links.extend(page_links)
        msg = f"Página {page_num+1}: {len(page_links)} novos"
        if skipped_cached:
            msg += f" ({skipped_cached} já raspados antes, pulados)"
        log(msg, "ok")

        next_btn = await page.query_selector(
            "a.andes-pagination__link[title='Siguiente'],"
            "a[title='Próximo'],"
            "li.andes-pagination__button--next a"
        )
        if not next_btn or len(links) >= max_items:
            break
        page_num += 1

    if skipped_cached:
        log(f"Total ignorados por cache: {skipped_cached} produto(s) já raspados anteriormente", "warn")

    return links[:max_items]

# ── Produto ───────────────────────────────────────────

async def scrape_product(page, url, log, retries=3):
    for attempt in range(retries):
        try:
            await page.goto(url, wait_until="domcontentloaded", timeout=35000)
            await delay(1.5, 2.5)
            for pos in [300, 700, 1200]:
                await page.evaluate(f"window.scrollTo(0,{pos})")
                await delay(0.2, 0.5)

            nome = ""
            for s in ["h1.ui-pdp-title","h1.item-title__primary-info","h1"]:
                nome = await txt(page, s)
                if nome: break

            if not nome:
                if attempt < retries - 1:
                    log(f"Sem nome, retry {attempt+1}/{retries}...", "warn")
                    await delay(5, 10)
                    continue
                return None

            preco = ""
            frac = await txt(page, "span.andes-money-amount__fraction")
            if frac:
                cents = await txt(page, "span.andes-money-amount__cents")
                preco = f"R$ {frac}" + (f",{cents}" if cents else "")

            vendas = ""
            for s in ["span.ui-pdp-subtitle","p.ui-pdp-subtitle",".ui-pdp-buybox__quantity"]:
                t = await txt(page, s)
                if t and any(c.isdigit() for c in t): vendas = t; break

            vendedor = ""
            for s in [".ui-pdp-seller__link-trigger","a.ui-pdp-action-modal__link span",
                      ".seller-info__status-title","[data-testid='seller-info-link']"]:
                vendedor = await txt(page, s)
                if vendedor: break

            rating = ""
            r = await txt(page, ".ui-pdp-review__rating")
            if r:
                qtd = await txt(page, ".ui-pdp-review__amount")
                rating = f"⭐ {r}" + (f" ({qtd})" if qtd and qtd != r else "")

            frete = ""
            for s in [".ui-pdp-color--GREEN.ui-pdp-family--SEMIBOLD",
                      ".ui-shipping-summary__title","[data-testid='shipping-message']"]:
                t = await txt(page, s)
                if t and ("grátis" in t.lower() or "frete" in t.lower()):
                    frete = t; break
            if not frete:
                for g in await page.query_selector_all(".ui-pdp-color--GREEN"):
                    t = (await g.inner_text()).strip()
                    if "grátis" in t.lower(): frete = t; break

            try:
                for btn in await page.query_selector_all(
                    "button[data-testid='action-collapsable'],.andes-card__action button"):
                    try: await btn.scroll_into_view_if_needed(); await btn.click(); await delay(0.3,0.5)
                    except: pass
            except: pass

            specs = []
            for tsel in [".ui-pdp-specs__table tr",".andes-table__row",
                         ".ui-vpp-highlighted-specs-res__attribute-box",".ui-pdp-specs tr","table tr"]:
                rows = await page.query_selector_all(tsel)
                if not rows: continue
                for row in rows:
                    cells = await row.query_selector_all("th,td,span")
                    texts = [(await c.inner_text()).strip() for c in cells]
                    texts = [t for t in texts if t and len(t) > 1]
                    if len(texts) >= 2: specs.append(f"{texts[0]}: {texts[1]}")
                if specs: break

            desc = ""
            try:
                for btn in await page.query_selector_all(
                    "button[data-testid='description-toggle'],a[data-testid='description-see-more'],"
                    ".ui-pdp-description .andes-card__action button"):
                    try: await btn.scroll_into_view_if_needed(); await btn.click(); await delay(0.4,0.8)
                    except: pass
            except: pass

            for s in [".ui-pdp-description__content p",".ui-pdp-description p",
                      "[data-testid='description-content']",".item-description__text",".ui-pdp-description"]:
                els = await page.query_selector_all(s)
                parts = [(await e.inner_text()).strip() for e in els]
                parts = [p for p in parts if p and len(p) > 10]
                if parts: desc = "\n\n".join(parts); break

            imgs, seen_imgs = [], set()
            for img in await page.query_selector_all(
                ".ui-pdp-gallery__figure img,figure img,.ui-pdp-image img,[data-testid='gallery'] img"):
                src = (await img.get_attribute("data-zoom") or
                       await img.get_attribute("src") or "").strip()
                if src and "loading" not in src and src not in seen_imgs:
                    src = re.sub(r'-[A-Z]_\d+x\d+','-F_0',src)
                    seen_imgs.add(src); imgs.append(src)

            return {
                "Nome do Produto":         nome,
                "Preço Atual":             preco,
                "Quantidade de Vendas":    vendas,
                "Vendedor":                vendedor,
                "Avaliações":              rating,
                "Frete":                   frete,
                "Especificações Técnicas": "\n".join(specs),
                "Descrição Completa":      desc,
                "URLs das Imagens":        " | ".join(imgs),
                "URL do Produto":          url,
            }

        except Exception as e:
            if attempt < retries - 1:
                log(f"Erro (tentativa {attempt+1}/{retries}): {str(e)[:60]} — aguardando...", "warn")
                await delay(8, 15)
            else:
                log(f"Falhou após {retries} tentativas: {url[:60]}", "err")
                return None

# ── Entry point ───────────────────────────────────────

async def run_scraper(queries, max_items, country, log, cancel_event=None, **kw):
    import threading
    if cancel_event is None:
        cancel_event = threading.Event()

    domain = COUNTRY_LIST.get(country, "lista.mercadolivre.com.br")
    all_products = []

    # Carrega cache de IDs já raspados
    cache = load_cache()
    log(f"Cache: {len(cache)} produto(s) já raspados anteriormente.", "info")

    log("Iniciando Chromium...", "info")

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(
            headless=False,
            args=["--no-sandbox","--disable-blink-features=AutomationControlled",
                  "--disable-dev-shm-usage","--start-maximized"],
        )
        ctx = await browser.new_context(
            viewport=None,
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            locale="pt-BR",
            timezone_id="America/Sao_Paulo",
            extra_http_headers={"Accept-Language":"pt-BR,pt;q=0.9,en-US;q=0.8"},
        )
        await ctx.add_init_script(
            "Object.defineProperty(navigator,'webdriver',{get:()=>undefined});"
            "Object.defineProperty(navigator,'plugins',{get:()=>[1,2,3]});"
            "window.chrome={runtime:{}};"
        )
        page = await ctx.new_page()

        for qi, query in enumerate(queries):
            if cancel_event.is_set():
                log("Raspagem cancelada pelo usuário.", "warn")
                break

            pct = int(qi / len(queries) * 100)
            log(json.dumps({"pct":pct,"label":f'Listagem: "{query}" ({qi+1}/{len(queries)})...'}), "progress")

            links = await get_links(page, query, domain, max_items, log, cancel_event, cache)
            log(f"{len(links)} produtos novos para raspar", "ok" if links else "warn")

            if not links:
                log(f'Todos os produtos de "{query}" já foram raspados antes.', "warn")
                continue

            for li, link in enumerate(links):
                if cancel_event.is_set():
                    log("Cancelado — salvando produtos coletados até agora.", "warn")
                    break

                ml_id = extract_ml_id(link) or link

                item_pct = pct + int((li+1)/max(len(links),1)*(100//max(len(queries),1)))
                log(json.dumps({
                    "pct": min(item_pct, 95),
                    "label": f'Produto {li+1}/{len(links)} — "{query}"',
                    "current": li+1, "total_links": len(links), "query": query
                }), "progress")
                log(f"[{li+1}/{len(links)}] {ml_id} — {link[:60]}", "info")

                p = await scrape_product(page, link, log, retries=3)
                if p and p["Nome do Produto"]:
                    all_products.append(p)

                    # Salva no cache imediatamente após raspar com sucesso
                    cache[ml_id] = {
                        "url": link,
                        "nome": p["Nome do Produto"][:80],
                        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                    }
                    save_cache(cache)

                    s = "✓" if p["Especificações Técnicas"] else "✗"
                    d = "✓" if p["Descrição Completa"] else "✗"
                    log(json.dumps({
                        "type_inner":"product","name":p["Nome do Produto"],
                        "price":p["Preço Atual"],"specs":bool(p["Especificações Técnicas"]),
                        "desc":bool(p["Descrição Completa"]),
                    }), "product")
                    log(f'✓ {p["Nome do Produto"][:55]}  Specs:{s} Desc:{d}', "ok")

                await delay(3, 7)

        try: await browser.close()
        except: pass

    log(f"Cache atualizado: {len(cache)} produto(s) no total.", "info")
    return all_products
