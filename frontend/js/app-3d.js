(function () {
    "use strict";

    function loadScript(url, timeoutMs) {
        return new Promise((resolve, reject) => {
            const s = document.createElement("script");
            const timer = setTimeout(() => {
                s.remove();
                reject(new Error(`加载超时: ${url}`));
            }, timeoutMs || 10000);
            s.src = url;
            s.async = true;
            s.onload = () => {
                clearTimeout(timer);
                resolve();
            };
            s.onerror = () => {
                clearTimeout(timer);
                s.remove();
                reject(new Error(`加载失败: ${url}`));
            };
            document.head.appendChild(s);
        });
    }

    async function loadFromCandidates(candidates, checker) {
        let lastErr = null;
        for (const url of candidates) {
            try {
                await loadScript(url);
                if (checker()) return;
            } catch (err) {
                lastErr = err;
            }
        }
        throw lastErr || new Error("依赖加载失败");
    }

    async function ensure3DDeps() {
        if (!window.THREE) {
            await loadFromCandidates(
                [
                    "/vendor/three.min.js",
                    "https://cdn.jsdelivr.net/npm/three@0.126.1/build/three.min.js",
                ],
                () => !!window.THREE
            );
        }
        if (!window.ForceGraph3D) {
            await loadFromCandidates(
                [
                    "/vendor/3d-force-graph.min.js",
                    "https://cdn.jsdelivr.net/npm/3d-force-graph@1.70.0/dist/3d-force-graph.min.js",
                ],
                () => !!window.ForceGraph3D
            );
        }
    }

    function inferLayer(node) {
        const direct = String(node.layer || "").toUpperCase();
        if (["ODS", "DIM", "DWD", "DWS", "ADS"].includes(direct)) {
            return direct === "DWS" ? "DWD" : direct;
        }
        const name = String(node.name || "").toLowerCase();
        if (name.startsWith("ods_")) return "ODS";
        if (name.startsWith("dim_") || name.startsWith("dm_")) return "DIM";
        if (name.startsWith("dwd_") || name.startsWith("dws_")) return "DWD";
        if (name.startsWith("ads_")) return "ADS";
        return "OTHER";
    }

    function boot() {
        const graphWrap = document.getElementById("graph-3d");
        const tooltip = document.getElementById("tooltip");
        const stats = document.getElementById("graph-stats");
        const searchInput = document.getElementById("search-input");
        const searchCount = document.getElementById("search-result-count");
        const layerChecks = Array.from(document.querySelectorAll(".layer-check"));
        const btnRefresh = document.getElementById("btn-refresh");
        const sector = (document.body.dataset.sector || "PRD_AL").toUpperCase();
        const detailPanel = document.getElementById("detail-panel");
        const panelClose = document.getElementById("panel-close");
        const panelContent = document.getElementById("panel-content");
        const CACHE_KEY = `graph3d-cache:${sector}`;
        const CACHE_MAX_AGE_MS = 6 * 60 * 60 * 1000;

        if (!graphWrap || !window.ForceGraph3D) throw new Error("3D 容器或依赖不存在");

        const layerColor = { ODS: "#5470c6", DIM: "#fac858", DWD: "#ee6666", ADS: "#73c0de", OTHER: "#9a60b4" };
        /** 与 2D app.js GRAPH_THEME.metricsDataset 一致：纯指标平台 DATASET 节点 */
        const METRICS_NODE_COLOR = "#ab47bc";
        const DIM_NODE = "rgba(120,130,160,0.24)";
        const DIM_LINK = "rgba(180,180,200,0.10)";
        const NORMAL_LINK = "rgba(210,210,220,0.82)";

        function isMetricsOnlyNode3d(n) {
            if (!n) return false;
            if ((n.tableType || "") === "metrics_dataset") return true;
            return String(n.id || "").indexOf("__metric_ds__") === 0;
        }
        function isMetricsDualNode3d(n) {
            return !!(n && n.metricsSameAsDataset);
        }
        function nodeVal3d(n) {
            return Math.max(2, Math.min(12, (n.relation_count || 1) / 2));
        }
        function sphereRadius3d(n) {
            return 4.1 * Math.cbrt(nodeVal3d(n) / 2.2);
        }
        function nIdStr(n) {
            if (!n || n.id == null) return "";
            return String(n.id);
        }
        function colorStringToPhongMaterial(mat, css) {
            if (!mat || !css) return;
            const t = String(css).trim();
            const rgbaM = /^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)/i.exec(t);
            if (rgbaM) {
                mat.transparent = true;
                mat.opacity = Math.min(1, Math.max(0, parseFloat(rgbaM[4]) || 0));
                mat.color.setRGB(+rgbaM[1] / 255, +rgbaM[2] / 255, +rgbaM[3] / 255);
                return;
            }
            mat.transparent = false;
            mat.opacity = 1;
            mat.color.set(t);
        }
        function resolveNodeSurfaceCss(node) {
            const myId = nIdStr(node);
            const isSel = selectedNodeId != null && myId === String(selectedNodeId);
            if (isMetricsDualNode3d(node)) {
                const g = layerColor[node.layer] || layerColor.OTHER;
                if (!highlightNodeIds) return g;
                if (highlightNodeIds.has(myId)) {
                    return brightenHexColor(g, isSel ? 0.32 : 0.14);
                }
                return "rgba(120,130,160,0.35)";
            }
            if (isMetricsOnlyNode3d(node)) {
                if (!highlightNodeIds) return METRICS_NODE_COLOR;
                if (highlightNodeIds.has(myId)) {
                    return brightenHexColor(
                        METRICS_NODE_COLOR,
                        isSel ? 0.32 : 0.14
                    );
                }
                return "rgba(120,130,160,0.35)";
            }
            const base = layerColor[node.layer] || layerColor.OTHER;
            if (!highlightNodeIds) return base;
            if (highlightNodeIds.has(myId)) {
                return brightenHexColor(base, isSel ? 0.32 : 0.14);
            }
            return "rgba(120,130,160,0.35)";
        }
        function paint3dNodeMats(node) {
            if (!node.__3dMats) return;
            const myId = nIdStr(node);
            const isSel = selectedNodeId != null && myId === String(selectedNodeId);
            if (node.__3dMats.type === "dual") {
                const g = layerColor[node.layer] || layerColor.OTHER;
                const m = METRICS_NODE_COLOR;
                if (!highlightNodeIds) {
                    colorStringToPhongMaterial(node.__3dMats.left, g);
                    colorStringToPhongMaterial(node.__3dMats.right, m);
                } else if (highlightNodeIds.has(myId)) {
                    const br = isSel ? 0.32 : 0.14;
                    colorStringToPhongMaterial(node.__3dMats.left, brightenHexColor(g, br));
                    colorStringToPhongMaterial(node.__3dMats.right, brightenHexColor(m, br));
                } else {
                    const dim = "rgba(120,130,160,0.35)";
                    colorStringToPhongMaterial(node.__3dMats.left, dim);
                    colorStringToPhongMaterial(node.__3dMats.right, dim);
                }
            } else if (node.__3dMats.type === "single") {
                colorStringToPhongMaterial(node.__3dMats.main, resolveNodeSurfaceCss(node));
            }
        }

        let allData = { nodes: [], links: [] };
        let viewData = { nodes: [], links: [] };
        let nodeById = new Map();
        let outAdj = new Map();
        let inAdj = new Map();
        let activeLayers = new Set();
        layerChecks.forEach((cb) => {
            if (cb.checked) activeLayers.add(cb.value);
        });
        if (!activeLayers.size) {
            activeLayers = new Set(["ODS", "DIM", "DWD", "ADS"]);
        }
        let mouseX = 0;
        let mouseY = 0;
        let selectedNodeId = null;
        let highlightNodeIds = null;
        let highlightLinkKeys = null;

        function brightenHexColor(hex, amount) {
            const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || "");
            if (!m) return hex;
            const clamp = (v) => Math.max(0, Math.min(255, v));
            const r = parseInt(m[1], 16);
            const g = parseInt(m[2], 16);
            const b = parseInt(m[3], 16);
            const mix = (v) => clamp(Math.round(v + (255 - v) * amount));
            const toHex = (v) => v.toString(16).padStart(2, "0");
            return `#${toHex(mix(r))}${toHex(mix(g))}${toHex(mix(b))}`;
        }

        function makeNodeTextSprite(text) {
            const canvas = document.createElement("canvas");
            const ctx = canvas.getContext("2d");
            const font = "24px 'Segoe UI','Microsoft YaHei',sans-serif";
            ctx.font = font;
            const padding = 12;
            const w = Math.ceil(ctx.measureText(text).width + padding * 2);
            const h = 40;
            canvas.width = w;
            canvas.height = h;
            ctx.font = font;
            ctx.fillStyle = "rgba(18,22,35,0.72)";
            ctx.fillRect(0, 0, w, h);
            ctx.strokeStyle = "rgba(190,210,255,0.55)";
            ctx.strokeRect(0.5, 0.5, w - 1, h - 1);
            ctx.fillStyle = "#eaf1ff";
            ctx.textBaseline = "middle";
            ctx.fillText(text, padding, h / 2);

            const texture = new window.THREE.CanvasTexture(canvas);
            texture.minFilter = window.THREE.LinearFilter;
            const material = new window.THREE.SpriteMaterial({ map: texture, transparent: true, depthWrite: false });
            const sprite = new window.THREE.Sprite(material);
            sprite.scale.set((w / h) * 14, 14, 1);
            sprite.position.set(0, 12, 0);
            return sprite;
        }

        function nodeColorAccessor(node) {
            return resolveNodeSurfaceCss(node);
        }

        function linkColorAccessor(link) {
            if (!highlightLinkKeys) return NORMAL_LINK;
            return highlightLinkKeys.has(link.__key) ? "rgba(235,238,250,0.98)" : DIM_LINK;
        }

        function linkWidthAccessor(link) {
            return !highlightLinkKeys || highlightLinkKeys.has(link.__key) ? 2.2 : 0.6;
        }

        function linkArrowAccessor(link) {
            return !highlightLinkKeys || highlightLinkKeys.has(link.__key) ? 7 : 2;
        }

        function refreshGraphStyle() {
            /* 勿在 refresh 前对 node.__3dMats 上色：Graph.refresh 会释放旧 nodeThreeObject，那时材质已废 */
            Graph
                .nodeColor(nodeColorAccessor)
                .linkColor(linkColorAccessor)
                .linkWidth(linkWidthAccessor)
                .linkDirectionalArrowLength(linkArrowAccessor);
            if (typeof Graph.refresh === "function") Graph.refresh();
        }

        const Graph = window.ForceGraph3D()(graphWrap)
            .backgroundColor("#111")
            .nodeRelSize(8)
            .nodeVal(node => Math.max(2, Math.min(12, (node.relation_count || 1) / 2)))
            .nodeColor(nodeColorAccessor)
            .linkWidth(linkWidthAccessor)
            .linkColor(linkColorAccessor)
            .linkDirectionalArrowLength(linkArrowAccessor)
            .linkDirectionalArrowRelPos(1)
            .nodeLabel((node) => `${node.name} (${node.layer})`)
            .onNodeHover((node) => {
                if (!node) {
                    tooltip.style.display = "none";
                    return;
                }
                const srcNote = isMetricsOnlyNode3d(node)
                    ? "<br>来源：指标平台"
                    : isMetricsDualNode3d(node)
                        ? "<br>来源：治理表 + 指标（同名）"
                        : "";
                tooltip.innerHTML = `<strong>${node.name}</strong><br>层级：${node.layer}<br>关联数：${node.relation_count}${srcNote}`;
                tooltip.style.display = "block";
                tooltip.style.left = `${mouseX + 14}px`;
                tooltip.style.top = `${mouseY + 14}px`;
            })
            .onBackgroundClick(() => {
                tooltip.style.display = "none";
                clearSelection();
            })
            .onNodeClick((node) => {
                tooltip.style.display = "none";
                const idStr = nIdStr(node);
                if (idStr && String(selectedNodeId) === idStr) {
                    clearSelection();
                    return;
                }
                selectedNodeId = idStr;
                applyFocusFromSeeds([idStr], true);
                showNodePanel(idStr);
                focusCamera(idStr);
            });
        Graph.nodeThreeObjectExtend(false);
        Graph.nodeThreeObject((node) => {
            const T = window.THREE;
            /* 每次由库调用时都新建 Mesh：Graph.refresh 会 dispose 旧自定义对象，复用已缓存 Group 会出现「球体消失」 */
            const R = sphereRadius3d(node);
            const g = new T.Group();
            if (isMetricsDualNode3d(node)) {
                const h1 = new T.SphereGeometry(R, 28, 28, 0, Math.PI);
                const h2 = new T.SphereGeometry(R, 28, 28, Math.PI, Math.PI);
                const m1 = new T.MeshPhongMaterial();
                const m2 = new T.MeshPhongMaterial();
                g.add(new T.Mesh(h1, m1), new T.Mesh(h2, m2));
                node.__3dMats = { type: "dual", left: m1, right: m2 };
            } else {
                const mat = new T.MeshPhongMaterial();
                g.add(new T.Mesh(new T.SphereGeometry(R, 32, 32), mat));
                node.__3dMats = { type: "single", main: mat };
            }
            const sp = makeNodeTextSprite(node.name || node.id || "");
            sp.visible = !!(highlightNodeIds && highlightNodeIds.has(nIdStr(node)));
            sp.position.set(0, 12, 0);
            g.add(sp);
            node.__nameSprite = sp;
            paint3dNodeMats(node);
            return g;
        });

        graphWrap.addEventListener("mousemove", (evt) => {
            mouseX = evt.pageX;
            mouseY = evt.pageY;
            if (tooltip.style.display === "block") {
                tooltip.style.left = `${mouseX + 14}px`;
                tooltip.style.top = `${mouseY + 14}px`;
            }
        });

        const charge = Graph.d3Force("charge");
        if (charge && charge.strength) charge.strength(-260);
        const link = Graph.d3Force("link");
        if (link && link.distance) link.distance(110);

        function resizeGraph() {
            Graph.width(graphWrap.clientWidth || 1200);
            Graph.height(graphWrap.clientHeight || 700);
            const ctrl = typeof Graph.controls === "function" ? Graph.controls() : null;
            if (ctrl) ctrl.autoRotate = false;
        }

        function normalizePayload(payload) {
            const nodes = (payload.nodes || []).map((n) => ({
                ...n,
                id: String(n.id),
                name: n.name || String(n.id),
                relation_count: Number(n.relationCount || n.relation_count || 0),
                layer: inferLayer(n),
            }));
            const links = (payload.links || []).map((l) => {
                const s = String(typeof l.source === "object" ? l.source.id : l.source);
                const t = String(typeof l.target === "object" ? l.target.id : l.target);
                return { ...l, source: s, target: t, __sid: s, __tid: t, __key: `${s}\x1e${t}` };
            });
            return { nodes, links };
        }

        function rebuildIndexes() {
            nodeById = new Map(viewData.nodes.map((n) => [String(n.id), n]));
            outAdj = new Map();
            inAdj = new Map();
            viewData.nodes.forEach((n) => {
                const id = String(n.id);
                outAdj.set(id, new Set());
                inAdj.set(id, new Set());
            });
            viewData.links.forEach((l) => {
                const s = String(l.__sid);
                const t = String(l.__tid);
                if (outAdj.has(s)) outAdj.get(s).add(t);
                if (inAdj.has(t)) inAdj.get(t).add(s);
            });
        }

        function applyFilteredData() {
            const nodes = allData.nodes.filter((n) => n.layer === "OTHER" || activeLayers.has(n.layer));
            const visible = new Set(nodes.map((n) => n.id));
            const links = allData.links.filter((l) => visible.has(l.__sid) && visible.has(l.__tid));
            viewData = { nodes, links };
            rebuildIndexes();
            Graph.graphData(viewData);
            stats.textContent = `${nodes.length} 节点 / ${links.length} 边`;
            updateSearchCount();
            clearSelection(false);
            setTimeout(() => Graph.zoomToFit(1000, 80), 80);
        }

        function persistGraphCache(rawPayload) {
            try {
                const plain = rawPayload || {
                    nodes: allData.nodes.map((n) => ({
                        id: n.id,
                        name: n.name,
                        displayName: n.displayName,
                        comment: n.comment,
                        filePath: n.filePath,
                        layer: n.layer,
                        tableType: n.tableType,
                        metricsSameAsDataset: n.metricsSameAsDataset,
                        relationCount: n.relation_count,
                    })),
                    links: allData.links.map((l) => ({
                        source: l.__sid || l.source,
                        target: l.__tid || l.target,
                        relationType: l.relationType,
                    })),
                };
                const payload = {
                    ts: Date.now(),
                    data: plain,
                };
                localStorage.setItem(CACHE_KEY, JSON.stringify(payload));
            } catch (_e) {
                // ignore
            }
        }

        function restoreGraphCache() {
            try {
                const raw = localStorage.getItem(CACHE_KEY);
                if (!raw) return false;
                const parsed = JSON.parse(raw);
                if (!parsed || !parsed.ts || !parsed.data) return false;
                if (Date.now() - Number(parsed.ts) > CACHE_MAX_AGE_MS) return false;
                const cached = normalizePayload(parsed.data);
                if (!cached.nodes.length) return false;
                allData = cached;
                applyFilteredData();
                return true;
            } catch (_e) {
                return false;
            }
        }

        function getOneHopUnion(seedIds) {
            const nodeSet = new Set();
            const linkSet = new Set();
            (seedIds || []).forEach((raw) => {
                const id = String(raw);
                if (!nodeById.has(id)) return;
                nodeSet.add(id);
                const outs = outAdj.get(id) || new Set();
                const ins = inAdj.get(id) || new Set();
                outs.forEach((t) => {
                    const tt = String(t);
                    nodeSet.add(tt);
                    linkSet.add(`${id}\x1e${tt}`);
                });
                ins.forEach((s) => {
                    const ss = String(s);
                    nodeSet.add(ss);
                    linkSet.add(`${ss}\x1e${id}`);
                });
            });
            return { nodeSet, linkSet };
        }

        function applyFocusFromSeeds(seedIds, includeInterLinks) {
            const { nodeSet, linkSet } = getOneHopUnion(seedIds);
            if (includeInterLinks) {
                viewData.links.forEach((l) => {
                    if (nodeSet.has(l.__sid) && nodeSet.has(l.__tid)) linkSet.add(l.__key);
                });
            }
            highlightNodeIds = nodeSet.size ? nodeSet : null;
            highlightLinkKeys = linkSet.size ? linkSet : null;
            refreshGraphStyle();
        }

        /** 对接 /api/agent/ask/stream 返回的 highlight：node_ids + links */
        function applyApiHighlight(hl) {
            if (!hl) {
                clearSelection(false);
                return;
            }
            const nodeIds = (hl.node_ids || []).map(String).filter((id) => nodeById.has(id));
            const linkKeys = new Set();
            (hl.links || []).forEach((l) => {
                if (!l || l.source == null || l.target == null) return;
                const s = String(l.source);
                const t = String(l.target);
                if (nodeById.has(s) && nodeById.has(t)) linkKeys.add(`${s}\x1e${t}`);
            });
            if (nodeIds.length) {
                highlightNodeIds = new Set(nodeIds);
            } else {
                const fromLinks = new Set();
                (hl.links || []).forEach((l) => {
                    if (!l) return;
                    if (l.source != null) {
                        const s = String(l.source);
                        if (nodeById.has(s)) fromLinks.add(s);
                    }
                    if (l.target != null) {
                        const t = String(l.target);
                        if (nodeById.has(t)) fromLinks.add(t);
                    }
                });
                if (!fromLinks.size) {
                    clearSelection(false);
                    return;
                }
                highlightNodeIds = fromLinks;
            }
            highlightLinkKeys = linkKeys.size ? linkKeys : null;
            refreshGraphStyle();
        }

        function showNodePanel(nodeId) {
            if (!detailPanel || !panelContent) return;
            const node = nodeById.get(String(nodeId));
            if (!node) return;
            const pk = String(nodeId);
            const upstream = Array.from(inAdj.get(pk) || []);
            const downstream = Array.from(outAdj.get(pk) || []);
            const upstreamText = upstream.length ? upstream.join(", ") : "无";
            const downstreamText = downstream.length ? downstream.join(", ") : "无";
            const chineseName = (node.displayName && String(node.displayName).trim()) || node.comment || "暂无";
            panelContent.innerHTML = [
                `<p><strong>英文表名</strong> ${node.name || node.id}</p>`,
                `<p><strong>中文表名</strong> ${chineseName}</p>`,
                `<p><strong>上游表名</strong> ${upstreamText}</p>`,
                `<p><strong>下游表名</strong> ${downstreamText}</p>`,
                `<p><strong>关联数</strong> ${upstream.length + downstream.length}</p>`,
                `<p><strong>表描述</strong> ${node.comment || node.description || "暂无"}</p>`,
                `<p><strong>文件路径</strong> ${node.filePath || "暂无"}</p>`,
            ].join("");
            detailPanel.style.display = "flex";
        }

        function escapeHtml(s) {
            const d = document.createElement("div");
            d.textContent = s == null ? "" : String(s);
            return d.innerHTML;
        }

        function renderAgentMarkdown3d(text) {
            const t = text == null ? "" : String(text);
            if (typeof marked !== "undefined" && typeof DOMPurify !== "undefined") {
                try {
                    return DOMPurify.sanitize(
                        marked.parse(t, { breaks: true, async: false })
                    );
                } catch (e) {
                    /* 回退为纯文本 */
                }
            }
            return escapeHtml(t).replace(/\n/g, "<br>");
        }

        function clearSelection(closePanel = true) {
            selectedNodeId = null;
            highlightNodeIds = null;
            highlightLinkKeys = null;
            refreshGraphStyle();
            if (closePanel && detailPanel) detailPanel.style.display = "none";
        }

        function focusCamera(nodeId) {
            const want = String(nodeId);
            const node = (Graph.graphData().nodes || []).find((n) => String(n.id) === want);
            if (!node) return;
            const dist = 220;
            const ratio = 1 + dist / Math.hypot(node.x || 1, node.y || 1, node.z || 1);
            Graph.cameraPosition(
                { x: (node.x || 0) * ratio, y: (node.y || 0) * ratio, z: (node.z || 0) * ratio },
                node,
                900
            );
        }

        function getMatchesByKeyword(kw) {
            const q = (kw || "").trim().toLowerCase();
            if (!q) return [];
            return viewData.nodes.filter((n) => {
                const name = (n.name || "").toLowerCase();
                const comment = (n.comment || "").toLowerCase();
                const display = (n.displayName || "").toLowerCase();
                return name.includes(q) || comment.includes(q) || display.includes(q);
            });
        }

        function updateSearchCount() {
            if (!searchCount) return;
            const matches = getMatchesByKeyword(searchInput.value || "");
            searchCount.textContent = `匹配 ${matches.length}`;
        }

        function searchAndFocus() {
            const matches = getMatchesByKeyword(searchInput.value || "");
            updateSearchCount();
            if (!matches.length) {
                clearSelection();
                return;
            }
            selectedNodeId = String(matches[0].id);
            applyFocusFromSeeds([selectedNodeId], true);
            showNodePanel(selectedNodeId);
            focusCamera(selectedNodeId);
        }

        function collectAncestors(startId) {
            const seen = new Set();
            const q = [startId];
            while (q.length) {
                const cur = q.shift();
                (inAdj.get(cur) || new Set()).forEach((p) => {
                    if (seen.has(p)) return;
                    seen.add(p);
                    q.push(p);
                });
            }
            return Array.from(seen);
        }

        function collectDescendants(startId) {
            const seen = new Set();
            const q = [startId];
            while (q.length) {
                const cur = q.shift();
                (outAdj.get(cur) || new Set()).forEach((c) => {
                    if (seen.has(c)) return;
                    seen.add(c);
                    q.push(c);
                });
            }
            return Array.from(seen);
        }

        function findShortestPath(startId, endId) {
            if (!startId || !endId || !nodeById.has(startId) || !nodeById.has(endId)) return [];
            const prev = new Map();
            const q = [startId];
            prev.set(startId, null);
            while (q.length) {
                const cur = q.shift();
                if (cur === endId) break;
                (outAdj.get(cur) || new Set()).forEach((nxt) => {
                    if (prev.has(nxt)) return;
                    prev.set(nxt, cur);
                    q.push(nxt);
                });
            }
            if (!prev.has(endId)) return [];
            const path = [];
            let cur = endId;
            while (cur != null) {
                path.push(cur);
                cur = prev.get(cur);
            }
            path.reverse();
            return path;
        }

        function parseTableName(text) {
            const q = (text || "").trim();
            if (!q) return null;
            const exact = viewData.nodes.find((n) => n.name === q);
            if (exact) return exact.name;
            const fuzzy = getMatchesByKeyword(q);
            return fuzzy.length ? fuzzy[0].name : null;
        }

        function runLocalQa(question) {
            const q = (question || "").trim();
            if (!q) return { answer: "请输入问题。", highlights: [] };
            const lower = q.toLowerCase();
            const allNames = viewData.nodes.map((n) => n.name);
            const tableInText = allNames.find((name) => lower.includes(String(name).toLowerCase()));

            if (lower.includes("关键词")) {
                const kw = q.split("关键词").pop().replace(/[：:]/g, "").trim();
                const list = getMatchesByKeyword(kw);
                return {
                    answer: list.length ? `命中 ${list.length} 张表：${list.map((n) => n.name).join("，")}` : `未找到包含关键词“${escapeHtml(kw)}”的表。`,
                    highlights: list.map((n) => n.id),
                };
            }

            if ((lower.includes("路径") || lower.includes("链路")) && (lower.includes("到") || lower.includes("->"))) {
                const normalized = q.replace(/->/g, "到");
                const parts = normalized.split("到").map((s) => s.trim()).filter(Boolean);
                if (parts.length >= 2) {
                    const start = parseTableName(parts[0]);
                    const end = parseTableName(parts[1]);
                    const path = findShortestPath(start, end);
                    return {
                        answer: path.length ? `最短路径：${path.join(" -> ")}` : "未找到可达路径。",
                        highlights: path,
                    };
                }
            }

            if (lower.includes("上游")) {
                const t = tableInText || parseTableName(q);
                if (!t) return { answer: "未识别到目标表名，请在问题中写出完整或可匹配表名。", highlights: [] };
                const direct = Array.from(inAdj.get(t) || []);
                const all = lower.includes("全部") || lower.includes("所有") ? collectAncestors(t) : direct;
                return {
                    answer: `${t} 的${all === direct ? "直接" : "全部"}上游共 ${all.length} 张：${all.length ? all.join("，") : "无"}`,
                    highlights: [t].concat(all),
                };
            }

            if (lower.includes("下游")) {
                const t = tableInText || parseTableName(q);
                if (!t) return { answer: "未识别到目标表名，请在问题中写出完整或可匹配表名。", highlights: [] };
                const direct = Array.from(outAdj.get(t) || []);
                const all = lower.includes("全部") || lower.includes("所有") ? collectDescendants(t) : direct;
                return {
                    answer: `${t} 的${all === direct ? "直接" : "全部"}下游共 ${all.length} 张：${all.length ? all.join("，") : "无"}`,
                    highlights: [t].concat(all),
                };
            }

            const guessed = getMatchesByKeyword(q);
            if (guessed.length) {
                return {
                    answer: `找到 ${guessed.length} 张相关表：${guessed.slice(0, 20).map((n) => n.name).join("，")}`,
                    highlights: guessed.map((n) => n.id),
                };
            }
            return { answer: "暂未理解该问题。可尝试：上游/下游/路径/关键词 查询。", highlights: [] };
        }

        function bindAgentUi() {
            const fab = document.getElementById("agent-fab");
            const drawer = document.getElementById("agent-drawer");
            const backdrop = document.getElementById("agent-drawer-backdrop");
            const closeBtn = document.getElementById("agent-drawer-close");
            const sendBtn = document.getElementById("agent-send");
            const clearBtn = document.getElementById("agent-clear-input");
            const input = document.getElementById("agent-input");
            const log = document.getElementById("agent-chat-log");
            if (!fab || !drawer || !backdrop || !sendBtn || !input || !log) return;

            function appendMsg(role, text) {
                const row = document.createElement("div");
                row.className = `agent-msg agent-msg-${role}`;
                const bubble = document.createElement("div");
                bubble.className = `agent-bubble agent-bubble-${role}`;
                bubble.textContent = text;
                row.appendChild(bubble);
                log.appendChild(row);
                log.scrollTop = log.scrollHeight;
            }

            function appendMsgAgentAnswer(text, metaLine) {
                const row = document.createElement("div");
                row.className = "agent-msg agent-msg-agent";
                const bubble = document.createElement("div");
                bubble.className = "agent-bubble agent-bubble-agent";
                const md = document.createElement("div");
                md.className = "agent-md";
                md.innerHTML = renderAgentMarkdown3d(text);
                bubble.appendChild(md);
                if (metaLine) {
                    const meta = document.createElement("div");
                    meta.className = "agent-bubble-meta";
                    meta.textContent = metaLine;
                    bubble.appendChild(meta);
                }
                row.appendChild(bubble);
                log.appendChild(row);
                log.scrollTop = log.scrollHeight;
            }

            async function runGraphAgentStreamQuestion(q) {
                const question = (q || "").trim();
                if (!question) return;

                const thinking = document.createElement("div");
                thinking.id = "agent-stream-answer-3d";
                thinking.className = "agent-msg agent-msg-agent";
                thinking.innerHTML =
                    "<div class=\"agent-bubble agent-bubble-agent\"><div class=\"agent-md\">思考中…</div></div>";
                log.appendChild(thinking);
                log.scrollTop = log.scrollHeight;

                let streamedText = "";
                let donePayload = null;

                try {
                    const resp = await fetch("/api/agent/ask/stream", {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ question, sector }),
                    });
                    if (!resp.ok || !resp.body) throw new Error(String(resp.status || 500));

                    const reader = resp.body.getReader();
                    const decoder = new TextDecoder("utf-8");
                    let buf = "";
                    while (true) {
                        const { value, done } = await reader.read();
                        if (done) break;
                        buf += decoder.decode(value, { stream: true }).replace(/\r\n/g, "\n");
                        let splitIdx = buf.indexOf("\n\n");
                        while (splitIdx >= 0) {
                            const block = buf.slice(0, splitIdx).trim();
                            buf = buf.slice(splitIdx + 2);
                            if (block.startsWith("data:")) {
                                const dataStr = block.slice(5).trim();
                                if (dataStr) {
                                    let evt;
                                    try {
                                        evt = JSON.parse(dataStr);
                                    } catch (_e) {
                                        evt = null;
                                    }
                                    if (evt) {
                                        if (evt.type === "error") {
                                            throw new Error(evt.message || "智能回答失败");
                                        }
                                        if (evt.type === "delta") {
                                            streamedText += evt.text || "";
                                            const md = thinking.querySelector(".agent-md");
                                            if (md) md.innerHTML = renderAgentMarkdown3d(streamedText);
                                            log.scrollTop = log.scrollHeight;
                                        } else if (evt.type === "done") {
                                            donePayload = evt;
                                        }
                                    }
                                }
                            }
                            splitIdx = buf.indexOf("\n\n");
                        }
                    }
                    buf = buf.replace(/\r\n/g, "\n");
                    buf += decoder.decode(new Uint8Array(), { stream: false }).replace(/\r\n/g, "\n");
                    if (buf.trim() && !donePayload) {
                        const tail = buf.trim();
                        if (tail.startsWith("data:")) {
                            const dataStr = tail.slice(5).trim();
                            if (dataStr) {
                                let evt;
                                try {
                                    evt = JSON.parse(dataStr);
                                } catch (_e) {
                                    evt = null;
                                }
                                if (evt) {
                                    if (evt.type === "error") {
                                        throw new Error(evt.message || "智能回答失败");
                                    }
                                    if (evt.type === "delta") {
                                        streamedText += evt.text || "";
                                    } else if (evt.type === "done") {
                                        donePayload = evt;
                                    }
                                }
                            }
                        }
                    }
                } catch (e) {
                    const th = document.getElementById("agent-stream-answer-3d");
                    if (th) th.remove();
                    const detail = e && e.message ? String(e.message).trim() : "请求失败";
                    const result = runLocalQa(question);
                    appendMsg("agent", `${detail}。已用本地快速规则作为备用：\n\n${result.answer}`);
                    if (result.highlights && result.highlights.length) {
                        const hid = String(result.highlights[0]);
                        selectedNodeId = hid;
                        applyFocusFromSeeds(result.highlights.map(String), true);
                        focusCamera(hid);
                        showNodePanel(hid);
                    }
                    return;
                }

                const th0 = document.getElementById("agent-stream-answer-3d");
                if (th0) th0.remove();

                if (!donePayload) {
                    const txt = streamedText || "模型未返回有效内容。";
                    appendMsgAgentAnswer(txt, null);
                    clearSelection(false);
                    return;
                }

                const conf = donePayload.confidence != null ? donePayload.confidence : 0;
                const meta = `意图：${
                    donePayload.intent_label || donePayload.intent || ""
                } · 置信度 ${(conf * 100).toFixed(0)}%`;
                const finalText = donePayload.answer != null && String(donePayload.answer) !== ""
                    ? donePayload.answer
                    : streamedText;
                appendMsgAgentAnswer(finalText || "（无正文）", meta);
                const hl = donePayload.highlight;
                if (hl && ((hl.node_ids && hl.node_ids.length) || (hl.links && hl.links.length))) {
                    applyApiHighlight(hl);
                    const ids = (hl.node_ids || []).map(String).filter((id) => nodeById.has(id));
                    const firstId = ids[0] || (hl.links && hl.links[0] && (hl.links[0].source != null
                        ? String(hl.links[0].source) : null));
                    if (firstId && nodeById.has(String(firstId))) {
                        const hid = String(firstId);
                        selectedNodeId = hid;
                        focusCamera(hid);
                        showNodePanel(hid);
                    }
                } else {
                    clearSelection(false);
                }
            }

            function openDrawer() {
                document.body.classList.add("agent-drawer-open");
                fab.classList.add("is-open");
                fab.setAttribute("aria-expanded", "true");
                backdrop.classList.add("is-visible");
                drawer.classList.add("is-open");
                drawer.setAttribute("aria-hidden", "false");
            }

            function closeDrawer() {
                document.body.classList.remove("agent-drawer-open");
                fab.classList.remove("is-open");
                fab.setAttribute("aria-expanded", "false");
                backdrop.classList.remove("is-visible");
                drawer.classList.remove("is-open");
                drawer.setAttribute("aria-hidden", "true");
            }

            async function submitQa() {
                const question = (input.value || "").trim();
                if (!question) return;
                appendMsg("user", question);
                input.value = "";
                sendBtn.disabled = true;
                try {
                    await runGraphAgentStreamQuestion(question);
                } finally {
                    sendBtn.disabled = false;
                }
            }

            fab.addEventListener("click", () => (drawer.classList.contains("is-open") ? closeDrawer() : openDrawer()));
            if (closeBtn) closeBtn.addEventListener("click", closeDrawer);
            backdrop.addEventListener("click", closeDrawer);
            sendBtn.addEventListener("click", () => submitQa());
            if (clearBtn) {
                clearBtn.addEventListener("click", () => {
                    input.value = "";
                    input.focus();
                });
            }
            input.addEventListener("keydown", (evt) => {
                if (evt.key === "Enter" && !evt.shiftKey) {
                    evt.preventDefault();
                    submitQa();
                }
            });
            appendMsg("agent", "我是知识图谱问答助手，有什么可以帮您的吗？");
        }

        async function fetchGraph() {
            const resp = await fetch(`/api/graph?sector=${encodeURIComponent(sector)}`);
            if (!resp.ok) throw new Error(`请求失败: ${resp.status}`);
            const payload = await resp.json();
            allData = normalizePayload(payload);
            applyFilteredData();
            persistGraphCache(payload);
        }

        function setupPanelDrag() {
            if (!detailPanel) return;
            const header = detailPanel.querySelector(".panel-header");
            if (!header) return;
            let dragging = false;
            let startX = 0;
            let startY = 0;
            let left = 0;
            let top = 0;
            header.style.cursor = "move";
            header.addEventListener("mousedown", (evt) => {
                dragging = true;
                startX = evt.clientX;
                startY = evt.clientY;
                const rect = detailPanel.getBoundingClientRect();
                left = rect.left;
                top = rect.top;
                evt.preventDefault();
            });
            window.addEventListener("mousemove", (evt) => {
                if (!dragging) return;
                const dx = evt.clientX - startX;
                const dy = evt.clientY - startY;
                detailPanel.style.left = `${Math.max(8, left + dx)}px`;
                detailPanel.style.top = `${Math.max(8, top + dy)}px`;
            });
            window.addEventListener("mouseup", () => {
                dragging = false;
            });
        }

        layerChecks.forEach((cb) => {
            cb.addEventListener("change", () => {
                if (cb.checked) activeLayers.add(cb.value);
                else activeLayers.delete(cb.value);
                applyFilteredData();
            });
        });

        searchInput.addEventListener("input", updateSearchCount);
        searchInput.addEventListener("keydown", (evt) => {
            if (evt.key === "Enter") {
                evt.preventDefault();
                searchAndFocus();
            }
        });

        if (panelClose) {
            panelClose.addEventListener("click", () => {
                if (detailPanel) detailPanel.style.display = "none";
                clearSelection(false);
            });
        }

        if (btnRefresh) {
            btnRefresh.addEventListener("click", () => {
                fetchGraph().catch((err) => {
                    graphWrap.innerHTML = `<div class="graph-error">${err.message}</div>`;
                });
            });
        }

        try {
            bindAgentUi();
        } catch (_e) {
            // ignore: 智能问答 UI 不应阻断 3D 图谱渲染
        }
        try {
            setupPanelDrag();
        } catch (_e) {
            // ignore: 详情面板拖拽不应阻断 3D 图谱渲染
        }
        window.addEventListener("resize", resizeGraph);
        resizeGraph();
        restoreGraphCache();
        fetchGraph().catch((err) => {
            if (!allData.nodes.length) {
                graphWrap.innerHTML = `<div class="graph-error">图谱加载失败：${err.message}</div>`;
            }
        });
    }

    ensure3DDeps()
        .then(() => boot())
        .catch((err) => {
            console.error("[3D图谱初始化失败]", err);
            const graphWrap = document.getElementById("graph-3d");
            if (graphWrap) {
                graphWrap.innerHTML = `<div class="graph-error">图谱初始化失败：${err.message}<br>正在切换到 2D 兼容模式...</div>`;
            }
            setTimeout(() => {
                window.location.href = "index-2d.html";
            }, 700);
        });
})();
