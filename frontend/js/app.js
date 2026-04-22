(function () {
    "use strict";

    /* ================================================================
       工具：从 link 中取字符串 id（D3 force 前是字符串，force 后是对象）
    ================================================================ */
    function linkId(link) { return link.id != null ? link.id : (link.source.id || link.source); }
    function nodeId(n)   { return n.id; }
    function linkSrc(link) { return link.source.id || link.source; }
    function linkDst(link) { return link.target.id || link.target; }

    /** 英文库视图常以 v_ 开头；去掉此前缀后与实体表同名规则一致（分层、筛选、扇入分组） */
    function tableBaseName(name) {
        const n = (name || "").toLowerCase();
        return n.startsWith("v_") ? n.slice(2) : n;
    }

    /** 按表名前缀判定数据层，用于同层扇入合并 */
    function tableDataLayer(name) {
        const n = tableBaseName(name);
        if (n.startsWith("ods_")) return "ODS";
        if (n.startsWith("dim_") || n.startsWith("dm_")) return "DIM";
        if (n.startsWith("dwd_") || n.startsWith("dws_")) return "DWD";
        if (n.startsWith("ads_")) return "ADS";
        return "OTHER";
    }

    /**
     * 将 links 按 (target, sourceLayer) 分组，同组多条边合并为 1 条展示边。
     * 每条展示边带 _srcIds（源表 id 列表）、_layer、_mergedCount。
     * 力仿真仍使用全量边；这里只生成「画布上画什么」。
     */
    function buildDisplayLinks(links) {
        const groups = new Map();
        links.forEach(l => {
            const s = linkSrc(l), t = linkDst(l);
            const layer = tableDataLayer(s);
            const key = `${t}\x1e${layer}`;
            if (!groups.has(key)) groups.set(key, { target: t, layer, srcs: [], links: [] });
            const g = groups.get(key);
            if (!g.srcs.includes(s)) g.srcs.push(s);
            g.links.push(l);
        });
        const out = [];
        groups.forEach(g => {
            const rep = g.links[0];
            const totalWeight = g.links.reduce((a, l) => a + (l.weight || 1), 0);
            out.push({
                source: g.srcs[0],
                target: g.target,
                relationType: rep.relationType || "DATA_FLOW",
                weight: totalWeight,
                _srcIds: g.srcs.slice().sort(),
                _layer: g.layer,
                _mergedCount: g.srcs.length,
                _dkey: `dl:${g.target}:${g.layer}`,
            });
        });
        return out;
    }

    function assocLabel(d) {
        const v = degreeVisible[d.id] || 0;
        const f = degreeFull[d.id] != null ? degreeFull[d.id] : (d.relationCount || 0);
        if (f > v) return `${v} 可见关联 (全图 ${f})`;
        return `${v} 关联`;
    }

    /** 节点卡片尺寸（与 rect 一致），需在创建 simulation 前写入 */
    function setNodeLayoutSize(d) {
        const text = d.name || "";
        d.__w = Math.max(160, text.length * 7 + 24);
        d.__h = 56;
    }

    /** 碰撞用外接圆半径 + 间隙，避免宽节点互相压盖 */
    function nodeBubbleRadius(d, pad) {
        pad = pad == null ? 18 : pad;
        const hw = d.__w / 2, hh = d.__h / 2;
        return Math.hypot(hw, hh) + pad;
    }

    /**
     * 从节点中心指向 (towardX, towardY) 时，与节点外形边界的交点（用于边端点，避免线穿入节点、箭头被盖住）
     */
    function boundaryPointToward(n, towardX, towardY) {
        const dx = towardX - n.x;
        const dy = towardY - n.y;
        const len = Math.hypot(dx, dy);
        if (len < 1e-9) return { x: n.x, y: n.y };
        const ux = dx / len;
        const uy = dy / len;
        const rx = n.__w / 2;
        const ry = n.__h / 2;
        const inv = Math.sqrt((ux * ux) / (rx * rx) + (uy * uy) / (ry * ry));
        const t = 1 / inv;
        return { x: n.x + t * ux, y: n.y + t * uy };
    }

    /** 沿弦方向从两端向中间收，使端点落在椭圆外，避免线/箭头被节点填充盖住（Z 序下层时尤其重要） */
    const LINK_END_INSET_SRC = 13;
    const LINK_END_INSET_DST = 22;

    function nearPt(p, q, eps) {
        return Math.hypot(p.x - q.x, p.y - q.y) < eps;
    }

    /** 邻接边在节点处相接，不算「交叉」 */
    function segmentsShareEndpoint(a, b, c, d, eps) {
        return nearPt(a, c, eps) || nearPt(a, d, eps) || nearPt(b, c, eps) || nearPt(b, d, eps);
    }

    /** 线段内部是否严格相交（比例留边，避免端点数值误差） */
    function segmentsProperCross(a, b, c, d) {
        const ax = a.x, ay = a.y, bx = b.x, by = b.y, cx = c.x, cy = c.y, dx = d.x, dy = d.y;
        const denom = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx);
        if (Math.abs(denom) < 1e-12) return false;
        const t = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / denom;
        const u = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / denom;
        return t > 0.04 && t < 0.96 && u > 0.04 && u < 0.96;
    }

    /** 与 singleEdgePath / 合并边几何一致的弦端点（内缩后），用于画直线或参与相交检测 */
    function insetChordEndpoints(sNode, tNode) {
        const b1 = boundaryPointToward(sNode, tNode.x, tNode.y);
        const b2 = boundaryPointToward(tNode, sNode.x, sNode.y);
        let dx = b2.x - b1.x, dy = b2.y - b1.y;
        const chord = Math.hypot(dx, dy);
        if (chord < 1e-6) return null;
        dx /= chord; dy /= chord;
        const maxIn = chord * 0.42;
        const p1 = {
            x: b1.x + dx * Math.min(LINK_END_INSET_SRC, maxIn),
            y: b1.y + dy * Math.min(LINK_END_INSET_SRC, maxIn),
        };
        const p2 = {
            x: b2.x - dx * Math.min(LINK_END_INSET_DST, maxIn),
            y: b2.y - dy * Math.min(LINK_END_INSET_DST, maxIn),
        };
        return { p1, p2, b1, b2, chord };
    }

    /**
     * 将一条展示边近似为若干直线段（与当前绘制几何一致），供交叉检测。
     */
    function collectDisplayLinkChordSegments(dl, nodeById) {
        const tNode = nodeById[dl.target];
        if (!tNode || tNode.x == null) return [];
        const srcIds = dl._srcIds;
        const segs = [];
        if (srcIds.length === 1) {
            const ends = insetChordEndpoints(nodeById[srcIds[0]], tNode);
            if (ends) segs.push([ends.p1, ends.p2]);
            return segs;
        }
        const srcNodes = srcIds.map(id => nodeById[id]).filter(n => n && n.x != null);
        if (!srcNodes.length) return [];
        let centX = 0, centY = 0;
        srcNodes.forEach(n => { centX += n.x; centY += n.y; });
        centX /= srcNodes.length;
        centY /= srcNodes.length;
        const tdx = tNode.x - centX, tdy = tNode.y - centY;
        const mergeX = centX + 0.58 * tdx;
        const mergeY = centY + 0.58 * tdy;
        const merge = { x: mergeX, y: mergeY };
        srcNodes.forEach(sNode => {
            const p0 = boundaryPointToward(sNode, tNode.x, tNode.y);
            segs.push([p0, merge]);
        });
        const b2 = boundaryPointToward(tNode, mergeX, mergeY);
        let dx = b2.x - mergeX, dy = b2.y - mergeY;
        const chord = Math.hypot(dx, dy);
        if (chord > 1e-6) {
            dx /= chord; dy /= chord;
            const ins2 = Math.min(LINK_END_INSET_DST, chord * 0.42);
            segs.push([merge, { x: b2.x - dx * ins2, y: b2.y - dy * ins2 }]);
        }
        return segs;
    }

    function chordCrossesOtherEdges(p1, p2, selfDl, displayLinks, nodeById, shareEps) {
        if (!displayLinks || displayLinks.length < 2) return false;
        for (let i = 0; i < displayLinks.length; i++) {
            const dl2 = displayLinks[i];
            if (dl2._dkey === selfDl._dkey) continue;
            const parts = collectDisplayLinkChordSegments(dl2, nodeById);
            for (let j = 0; j < parts.length; j++) {
                const [c, d] = parts[j];
                if (segmentsShareEndpoint(p1, p2, c, d, shareEps)) continue;
                if (segmentsProperCross(p1, p2, c, d)) return true;
            }
        }
        return false;
    }

    function chordPassesThroughOtherNodes(p1, p2, sNode, tNode, allNodes, steps) {
        const nSt = steps || 24;
        for (let i = 1; i < nSt; i++) {
            const t = i / nSt;
            const x = p1.x + t * (p2.x - p1.x);
            const y = p1.y + t * (p2.y - p1.y);
            for (let k = 0; k < allNodes.length; k++) {
                const n = allNodes[k];
                if (n.id === sNode.id || n.id === tNode.id) continue;
                const rx = n.__w / 2, ry = n.__h / 2;
                if (rx < 2 || ry < 2) continue;
                const u = (x - n.x) / rx, v = (y - n.y) / ry;
                if (u * u + v * v <= 1.03) return true;
            }
        }
        return false;
    }

    function chordNeedsCurve(p1, p2, selfDl, displayLinks, nodeById, sNode, tNode) {
        const allNodes = Object.values(nodeById);
        if (chordCrossesOtherEdges(p1, p2, selfDl, displayLinks, nodeById, 28)) return true;
        if (chordPassesThroughOtherNodes(p1, p2, sNode, tNode, allNodes, 26)) return true;
        return false;
    }

    /**
     * 单条边：无与其它边交叉且未穿过第三张表 → 直线；否则二次贝塞尔（原逻辑）。
     */
    function singleEdgePath(sNode, tNode, hashSeed, displayLinks, selfDl, nodeById) {
        const ends = insetChordEndpoints(sNode, tNode);
        if (!ends) return "";
        const { p1, p2, b1, b2 } = ends;

        if (displayLinks && selfDl && !chordNeedsCurve(p1, p2, selfDl, displayLinks, nodeById, sNode, tNode)) {
            return `M${p1.x},${p1.y} L${p2.x},${p2.y}`;
        }

        let dx = b2.x - b1.x, dy = b2.y - b1.y;
        const chord = Math.hypot(dx, dy);
        if (chord < 1e-6) return `M${p1.x},${p1.y}`;
        dx /= chord; dy /= chord;
        const mx = (p1.x + p2.x) / 2, my = (p1.y + p2.y) / 2;
        let ux = p2.x - p1.x, uy = p2.y - p1.y;
        const len = Math.hypot(ux, uy);
        if (len < 1e-6) return `M${p1.x},${p1.y}`;
        ux /= len; uy /= len;
        const px = -uy, py = ux;
        const ccx = sNode._clusterCx != null ? sNode._clusterCx : (sNode.x + tNode.x) / 2;
        const ccy = sNode._clusterCy != null ? sNode._clusterCy : (sNode.y + tNode.y) / 2;
        const sameBlock = sNode._cluster != null && sNode._cluster === tNode._cluster;
        const pull = sameBlock ? 0.64 : 0.48;
        let qx = mx + pull * (ccx - mx), qy = my + pull * (ccy - my);
        const spread = 4.2 * (((hashSeed * 7919) % 21) - 10);
        qx += px * spread; qy += py * spread;
        return `M${p1.x},${p1.y} Q${qx},${qy} ${p2.x},${p2.y}`;
    }

    /**
     * 展示边路径。
     * 单源 → 普通贝塞尔。
     * 多源（同层合并）→ 河流汇聚路径：
     *   每条支流用三次贝塞尔从源节点"流出"（切线朝目标方向），
     *   逐渐转弯汇入交汇点（切线与主干对齐），
     *   主干再用一条平滑曲线流入目标。
     *   视觉效果类似多条小溪汇成一条河流。
     */
    function linkBundledPathMerged(dl, nodeById, displayLinks) {
        const tNode = nodeById[dl.target];
        if (!tNode || tNode.x == null) return "";
        const srcIds = dl._srcIds;

        /* ---- 单源：无交叉则直线，否则贝塞尔 ---- */
        if (srcIds.length === 1) {
            const sNode = nodeById[srcIds[0]];
            if (!sNode || sNode.x == null) return "";
            let h = 0;
            for (let i = 0; i < dl._dkey.length; i++) h += dl._dkey.charCodeAt(i);
            return singleEdgePath(sNode, tNode, h, displayLinks, dl, nodeById);
        }

        /* ---- 多源河流汇聚 ---- */
        const srcNodes = srcIds.map(id => nodeById[id]).filter(n => n && n.x != null);
        if (!srcNodes.length) return "";

        let centX = 0, centY = 0;
        srcNodes.forEach(n => { centX += n.x; centY += n.y; });
        centX /= srcNodes.length;
        centY /= srcNodes.length;

        /* 主干方向：源群形心 → 目标 */
        const tdx = tNode.x - centX, tdy = tNode.y - centY;
        const tlen = Math.hypot(tdx, tdy);
        const tux = tlen > 1e-6 ? tdx / tlen : 0;
        const tuy = tlen > 1e-6 ? tdy / tlen : 1;

        /* 交汇点：形心往目标走 58%，给支流留出弯曲空间 */
        const mergeX = centX + 0.58 * tdx;
        const mergeY = centY + 0.58 * tdy;

        /* ---- 支流：三次贝塞尔 C，起点切线朝目标、终点切线与主干对齐 ---- */
        const branches = srcNodes.map(sNode => {
            const p0 = boundaryPointToward(sNode, tNode.x, tNode.y);
            const bLen = Math.hypot(mergeX - p0.x, mergeY - p0.y);
            if (bLen < 1e-6) return "";

            /* 出发切线：从源节点朝目标方向 */
            const depDx = tNode.x - sNode.x, depDy = tNode.y - sNode.y;
            const depLen = Math.hypot(depDx, depDy);
            const dux = depLen > 1e-6 ? depDx / depLen : tux;
            const duy = depLen > 1e-6 ? depDy / depLen : tuy;

            /* C1：沿出发切线延伸 40% 支流长度 */
            const c1x = p0.x + dux * bLen * 0.40;
            const c1y = p0.y + duy * bLen * 0.40;

            /* C2：从交汇点逆主干方向回退 38%，到达时切线与主干平行 */
            const c2x = mergeX - tux * bLen * 0.38;
            const c2y = mergeY - tuy * bLen * 0.38;

            return `M${p0.x},${p0.y} C${c1x},${c1y} ${c2x},${c2y} ${mergeX},${mergeY}`;
        });

        /* ---- 主干：交汇点 → 目标，平滑曲线 ---- */
        const b2 = boundaryPointToward(tNode, mergeX, mergeY);
        let dx = b2.x - mergeX, dy = b2.y - mergeY;
        const chord = Math.hypot(dx, dy);
        if (chord < 1e-6) return branches.filter(Boolean).join(" ");
        dx /= chord; dy /= chord;
        const ins2 = Math.min(LINK_END_INSET_DST, chord * 0.42);
        const p2 = { x: b2.x - dx * ins2, y: b2.y - dy * ins2 };

        /* 主干用三次贝塞尔：起点切线与主干方向对齐，终点切线也对齐，形成自然弧度 */
        const trunkLen = Math.hypot(p2.x - mergeX, p2.y - mergeY);
        const tc1x = mergeX + tux * trunkLen * 0.38;
        const tc1y = mergeY + tuy * trunkLen * 0.38;
        const tc2x = p2.x - tux * trunkLen * 0.28;
        const tc2y = p2.y - tuy * trunkLen * 0.28;
        const trunkPath = `M${mergeX},${mergeY} C${tc1x},${tc1y} ${tc2x},${tc2y} ${p2.x},${p2.y}`;

        return branches.filter(Boolean).join(" ") + " " + trunkPath;
    }

    /**
     * 无向图连通分量（边视为无向），用于把图谱拆成多个互不相连的业务块。
     * 分量按规模从大到小排序，便于大块占据网格靠前位置。
     */
    function computeUndirectedComponents(nodes, links) {
        const adj = new Map();
        nodes.forEach(n => adj.set(n.id, []));
        links.forEach(l => {
            const s = linkSrc(l), t = linkDst(l);
            if (!adj.has(s)) adj.set(s, []);
            if (!adj.has(t)) adj.set(t, []);
            adj.get(s).push(t);
            adj.get(t).push(s);
        });
        const seen = new Set();
        const comps = [];
        for (const n of nodes) {
            if (seen.has(n.id)) continue;
            const ids = [];
            const q = [n.id];
            seen.add(n.id);
            while (q.length) {
                const u = q.pop();
                ids.push(u);
                for (const v of adj.get(u) || []) {
                    if (!seen.has(v)) { seen.add(v); q.push(v); }
                }
            }
            comps.push(ids);
        }
        comps.sort((a, b) => b.length - a.length);
        const idToCluster = new Map();
        comps.forEach((ids, idx) => ids.forEach(id => idToCluster.set(id, idx)));
        return { comps, idToCluster, k: comps.length };
    }

    /**
     * 多连通块分区网格：槽位 + 区块间 gutter + 最小槽宽，避免 4 块在数据坐标里挤在一起；
     * 总宽高超出口窗时整体居中，由 fit 缩放拉开视觉间距（不混布局）。
     */
    function multiClusterGrid(k, W, H, margin) {
        if (k <= 0) {
            return {
                centers: [],
                cellW: 0,
                cellH: 0,
                cols: 1,
                rows: 1,
                gutterX: 0,
                gutterY: 0,
                slotRects: [],
            };
        }
        const cols = Math.ceil(Math.sqrt(k));
        const rows = Math.ceil(k / cols);
        const innerW = Math.max(120, W - 2 * margin);
        const innerH = Math.max(100, H - 2 * margin);
        if (k === 1) {
            return {
                centers: [{ x: margin + innerW / 2, y: margin + innerH / 2 }],
                cellW: innerW,
                cellH: innerH,
                cols: 1,
                rows: 1,
                gutterX: 0,
                gutterY: 0,
                slotRects: [],
            };
        }
        const m = Math.min(W, H);
        /* 槽间 gutter：比例 + 像素下限，避免 4 块在视口里仍挤成一团 */
        const gutterX = Math.max(m * (k >= 4 ? 0.34 : 0.24), k >= 4 ? 220 : 150);
        const gutterY = Math.max(m * (k >= 4 ? 0.31 : 0.22), k >= 4 ? 190 : 132);
        const minCellW = m * (k >= 4 ? 0.54 : 0.43);
        const minCellH = m * (k >= 4 ? 0.50 : 0.39);
        let cellW = (innerW - gutterX * (cols - 1)) / cols;
        let cellH = (innerH - gutterY * (rows - 1)) / rows;
        cellW = Math.max(cellW, minCellW);
        cellH = Math.max(cellH, minCellH);
        const totalW = cols * cellW + gutterX * Math.max(0, cols - 1);
        const totalH = rows * cellH + gutterY * Math.max(0, rows - 1);
        const startX = margin + (innerW - totalW) / 2;
        const startY = margin + (innerH - totalH) / 2;
        const centers = [];
        const slotRects = [];
        for (let i = 0; i < k; i++) {
            const col = i % cols;
            const row = Math.floor(i / cols);
            centers.push({
                x: startX + col * (cellW + gutterX) + cellW / 2,
                y: startY + row * (cellH + gutterY) + cellH / 2,
            });
            slotRects.push({
                x: startX + col * (cellW + gutterX),
                y: startY + row * (cellH + gutterY),
                w: cellW,
                h: cellH,
            });
        }
        /* 以槽位几何中心为原点，把各簇心再径向推开，形成「四个岛」而不是中间一坨 */
        if (k >= 3) {
            let mx = 0, my = 0;
            centers.forEach(c => { mx += c.x; my += c.y; });
            mx /= k;
            my /= k;
            const spread = k >= 4 ? 1.44 : 1.25;
            for (let i = 0; i < k; i++) {
                const c = centers[i];
                c.x = mx + (c.x - mx) * spread;
                c.y = my + (c.y - my) * spread;
                slotRects[i].x = c.x - cellW / 2;
                slotRects[i].y = c.y - cellH / 2;
            }
        }
        return { centers, cellW, cellH, cols, rows, gutterX, gutterY, slotRects };
    }

    /** 数仓分层（自上而下：ODS → DWD → DM → 其它/视图 → ADS），用于纵向力与初始排布 */
    function dataWarehouseTier(n) {
        const name = tableBaseName(n.name || "");
        if (name.startsWith("ods_")) return 0;
        if (name.startsWith("dwd_") || name.startsWith("dws_")) return 1;
        if (name.startsWith("dim_") || name.startsWith("dm_")) return 2;
        if (name.startsWith("ads_")) return 4;
        return 3;
    }
    const NUM_DW_TIERS = 5;
    function layerTargetY(tier, H, topM, botM) {
        const inner = Math.max(100, H - topM - botM);
        return topM + (tier + 0.5) / NUM_DW_TIERS * inner;
    }

    /* ================================================================
       状态
    ================================================================ */
    let allNodes = [], allLinks = [];
    let filteredNodes = [], filteredLinks = [];
    /** 当前筛选下各节点可见边数 / 全图边数（用于标签，避免“有数字却无线”） */
    let degreeVisible = {}, degreeFull = {};
    let sim = null, svgEl = null, svgG = null;
    let linkSel = null, nodeSel = null;
    let selId = null;
    let layoutLocked = false;
    /** 最近一次渲染的展示边，供搜索 / Agent 高亮复用 */
    let lastDisplayLinks = [];
    /** 与画布一致的逻辑边（未合并），用于 1 跳邻域与选中叠加线 */
    let lastLogicalLinks = [];
    let lastNodeById = {};
    /** 选中时画在合并边之上的「单关系」高亮路径 */
    let focusLinkOverlayG = null;
    let agentNodeSet = null;
    let agentLinkPairSet = null;

    const F = { layers: { ods: true, dwd: true, dm: true, ads: true } };

    const SECTOR = (document.body.dataset.sector || "PRD_AL").toUpperCase().replace(/-/g, "_");

    /** 电解铝 / 氧化铝共用同一套图谱配色（节点类型色、边箭头、血缘高亮描边） */
    const GRAPH_THEME = {
        core: "#2d5a9e", dictionary: "#2e8b57", junction: "#c17a3a", temp: "#5a5a6e",
        /* 指标平台 DATASET 节点（与治理表对齐后出现） */
        metricsDataset: "#ab47bc",
        /* 库视图（表名 v_ 前缀）：紫系，与核心蓝表区分 */
        view: "#8e6bb8",
        selected: "#ffd700", nolayer: "#4d4d5c",
        strokeDefault: "#3a3a5a", markerFill: "#4a9eff",
        markerUp: "#26c6da", markerDown: "#ffb74d", markerCross: "#ce93d8",
        nodeStrokeUp: "#4dd0e1", nodeStrokeDown: "#ffb74d", nodeStrokeBoth: "#e1bee7",
    };
    const C = GRAPH_THEME;

    /* ================================================================
       入口
    ================================================================ */
    function init() {
        bindFilters();
        bindAgentUi();
        fetchGraph();
    }

    function setAgentHighlight(highlight) {
        const ids = (highlight && highlight.node_ids) || [];
        agentNodeSet = ids.length ? new Set(ids) : null;
        agentLinkPairSet = new Set();
        const links = (highlight && highlight.links) || [];
        links.forEach(l => {
            if (l && l.source != null && l.target != null)
                agentLinkPairSet.add(String(l.source) + "\x1e" + String(l.target));
        });
    }

    function clearAgentHighlight() {
        agentNodeSet = null;
        agentLinkPairSet = null;
    }

    let agentDrawerOpen = false;

    const AGENT_PRESETS = [
        { label: "ODS 相关表", q: "包含关键词 ods_ 的表有哪些？" },
        { label: "关联最多的表", q: "哪个表的上下游关联最多？" },
        { label: "ODS→ADS 链路", q: "从 ODS 到 ADS 的完整数据链路" },
    ];

    function renderAgentMarkdown(text) {
        const t = text == null ? "" : String(text);
        if (typeof marked !== "undefined" && typeof DOMPurify !== "undefined") {
            try {
                const raw = marked.parse(t, { breaks: true, async: false });
                return DOMPurify.sanitize(raw);
            } catch (e) { /* fallthrough */ }
        }
        return escapeHtml(t);
    }

    function appendChatMessage(role, text, metaLine) {
        const log = document.getElementById("agent-chat-log");
        if (!log) return;
        const wrap = document.createElement("div");
        wrap.className = "agent-msg agent-msg-" + (role === "user" ? "user" : "agent");
        const bubble = document.createElement("div");
        bubble.className = "agent-bubble agent-bubble-" + (role === "user" ? "user" : "agent");
        if (role === "user") {
            bubble.textContent = text;
        } else {
            const md = document.createElement("div");
            md.className = "agent-md";
            md.innerHTML = renderAgentMarkdown(text);
            bubble.appendChild(md);
            if (metaLine) {
                const meta = document.createElement("div");
                meta.className = "agent-bubble-meta";
                meta.textContent = metaLine;
                bubble.appendChild(meta);
            }
        }
        wrap.appendChild(bubble);
        log.appendChild(wrap);
        log.scrollTop = log.scrollHeight;
    }

    function bindAgentUi() {
        const fab = document.getElementById("agent-fab");
        const drawer = document.getElementById("agent-drawer");
        const backdrop = document.getElementById("agent-drawer-backdrop");
        const btnClose = document.getElementById("agent-drawer-close");
        const btnSend = document.getElementById("agent-send");
        const btnClear = document.getElementById("agent-clear-input");
        const input = document.getElementById("agent-input");
        const quickRow = document.getElementById("agent-quick-row");
        if (!fab || !drawer || !backdrop || !btnSend || !input) return;

        if (quickRow) {
            AGENT_PRESETS.forEach(p => {
                const b = document.createElement("button");
                b.type = "button";
                b.className = "agent-quick-btn";
                b.textContent = p.label;
                b.title = p.q;
                b.addEventListener("click", () => {
                    input.value = p.q;
                    input.focus();
                });
                quickRow.appendChild(b);
            });
        }

        function openDrawer() {
            agentDrawerOpen = true;
            document.body.classList.add("agent-drawer-open");
            fab.classList.add("is-open");
            fab.setAttribute("aria-expanded", "true");
            backdrop.classList.add("is-visible");
            backdrop.setAttribute("aria-hidden", "false");
            drawer.setAttribute("aria-hidden", "false");
            drawer.setAttribute("aria-modal", "true");
            requestAnimationFrame(() => drawer.classList.add("is-open"));
            input.focus();
        }

        function closeDrawer() {
            agentDrawerOpen = false;
            document.body.classList.remove("agent-drawer-open");
            fab.classList.remove("is-open");
            fab.setAttribute("aria-expanded", "false");
            backdrop.classList.remove("is-visible");
            backdrop.setAttribute("aria-hidden", "true");
            drawer.classList.remove("is-open");
            drawer.setAttribute("aria-hidden", "true");
            drawer.setAttribute("aria-modal", "false");
        }

        function toggleDrawer() {
            if (agentDrawerOpen) closeDrawer();
            else openDrawer();
        }

        fab.addEventListener("click", e => {
            e.stopPropagation();
            toggleDrawer();
        });
        btnClose.addEventListener("click", () => closeDrawer());
        backdrop.addEventListener("click", () => closeDrawer());

        document.addEventListener("keydown", e => {
            if (e.key === "Escape" && agentDrawerOpen) closeDrawer();
        });

        async function runAgentQuestion(q) {
            const question = (q || "").trim();
            if (!question) return;
            const log = document.getElementById("agent-chat-log");
            appendChatMessage("user", question, null);
            input.value = "";
            btnSend.disabled = true;

            const thinking = document.createElement("div");
            thinking.id = "agent-stream-answer";
            thinking.className = "agent-msg agent-msg-agent";
            thinking.innerHTML = "<div class=\"agent-bubble agent-bubble-agent\"><div class=\"agent-md\">思考中…</div></div>";
            if (log) {
                log.appendChild(thinking);
                log.scrollTop = log.scrollHeight;
            }
            let streamedText = "";
            let donePayload = null;

            try {
                const resp = await fetch("/api/agent/ask/stream", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ question, sector: SECTOR }),
                });
                if (!resp.ok || !resp.body) throw new Error(String(resp.status || 500));

                const reader = resp.body.getReader();
                const decoder = new TextDecoder("utf-8");
                let buf = "";
                while (true) {
                    const { value, done } = await reader.read();
                    if (done) break;
                    buf += decoder.decode(value, { stream: true });
                    let splitIdx = buf.indexOf("\n\n");
                    while (splitIdx >= 0) {
                        const block = buf.slice(0, splitIdx).trim();
                        buf = buf.slice(splitIdx + 2);
                        if (block.startsWith("data:")) {
                            const dataStr = block.slice(5).trim();
                            if (dataStr) {
                                try {
                                    const evt = JSON.parse(dataStr);
                                    if (evt.type === "delta") {
                                        streamedText += evt.text || "";
                                        const md = thinking.querySelector(".agent-md");
                                        if (md) md.innerHTML = renderAgentMarkdown(streamedText);
                                        if (log) log.scrollTop = log.scrollHeight;
                                    } else if (evt.type === "done") {
                                        donePayload = evt;
                                    } else if (evt.type === "error") {
                                        throw new Error(evt.message || "stream_error");
                                    }
                                } catch (e) {
                                    /* ignore malformed event */
                                }
                            }
                        }
                        splitIdx = buf.indexOf("\n\n");
                    }
                }

                const th = document.getElementById("agent-stream-answer");
                if (th) th.remove();

                if (!donePayload) {
                    appendChatMessage("agent", streamedText || "模型未返回有效内容。", null);
                    clearAgentHighlight();
                    paintVisualState();
                    return;
                }

                const conf = donePayload.confidence != null ? donePayload.confidence : 0;
                const meta = `意图：${donePayload.intent_label || donePayload.intent || ""} · 置信度 ${(conf * 100).toFixed(0)}%`;
                appendChatMessage("agent", donePayload.answer || streamedText || "", meta);
                setAgentHighlight(donePayload.highlight || {});
                document.getElementById("search-input").value = "";
                selId = null;
                const panel = document.getElementById("detail-panel");
                if (panel) panel.style.display = "none";
                paintVisualState();
            } catch (_e) {
                const th = document.getElementById("agent-stream-answer");
                if (th) th.remove();
                appendChatMessage("agent", "请求失败，请确认后端已启动（接口 `/api/agent/ask/stream`）。", null);
                clearAgentHighlight();
                paintVisualState();
            } finally {
                btnSend.disabled = false;
            }
        }

        btnSend.addEventListener("click", () => runAgentQuestion(input.value));
        input.addEventListener("keydown", e => {
            if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                runAgentQuestion(input.value);
            }
        });
        if (btnClear) btnClear.addEventListener("click", () => { input.value = ""; input.focus(); });
    }

    function escapeHtml(s) {
        const d = document.createElement("div");
        d.textContent = s;
        return d.innerHTML;
    }

    /**
     * 搜索框 > Agent 高亮 > 单击表血缘高亮
     */
    function paintVisualState() {
        const dLinks = lastDisplayLinks || [];
        if (!nodeSel || !linkSel) return;
        const q = (document.getElementById("search-input").value || "").trim().toLowerCase();
        if (q) {
            applySearchVisual(q, dLinks);
            return;
        }
        if (agentNodeSet && agentNodeSet.size > 0) {
            applyAgentVisual(dLinks);
            return;
        }
        if (selId) {
            applyHL();
            return;
        }
        resetHL();
    }

    function applySearchVisual(q, dLinks) {
        clearLineageFocusOverlay();
        refreshLinkPaths();
        const matched = new Set(filteredNodes
            .filter(n => (n.name || "").toLowerCase().includes(q) || (n.comment || "").toLowerCase().includes(q))
            .map(n => n.id));
        nodeSel.select(".node-shape")
            .attr("stroke", d => matched.has(d.id) ? C.selected : C.strokeDefault)
            .attr("stroke-width", d => matched.has(d.id) ? 3 : 2)
            .attr("opacity", d => matched.has(d.id) ? 1 : 0.2);
        nodeSel.selectAll("text")
            .attr("fill", (d, i) => matched.has(d.id) ? (i === 0 ? "#fff" : "rgba(255,255,255,0.75)") : "#6a6a7a");
        linkSel
            .style("stroke-opacity", dl => {
                const hit = matched.has(dl.target) || dl._srcIds.some(s => matched.has(s));
                return hit ? 0.9 : 0.06;
            })
            .attr("marker-end", dl => {
                const hit = matched.has(dl.target) || dl._srcIds.some(s => matched.has(s));
                return hit ? "url(#arr)" : "none";
            });
    }

    function applyAgentVisual(dLinks) {
        clearLineageFocusOverlay();
        refreshLinkPaths();
        const ns = agentNodeSet;
        const pairs = agentLinkPairSet;
        const usePairs = pairs && pairs.size > 0;
        nodeSel.select(".node-shape")
            .attr("stroke", d => ns.has(d.id) ? C.selected : C.strokeDefault)
            .attr("stroke-width", d => ns.has(d.id) ? 3 : 2)
            .attr("opacity", d => ns.has(d.id) ? 1 : 0.22);
        nodeSel.selectAll("text")
            .attr("fill", (d, i) => ns.has(d.id) ? (i === 0 ? "#fff" : "rgba(255,255,255,0.75)") : "#6a6a7a");
        linkSel
            .style("stroke-opacity", dl => {
                let hit = false;
                if (usePairs) {
                    hit = dl._srcIds.some(s => pairs.has(s + "\x1e" + dl.target));
                } else {
                    hit = ns.has(dl.target) && dl._srcIds.some(s => ns.has(s));
                }
                return hit ? 0.95 : 0.07;
            })
            .attr("marker-end", dl => {
                let hit = false;
                if (usePairs) {
                    hit = dl._srcIds.some(s => pairs.has(s + "\x1e" + dl.target));
                } else {
                    hit = ns.has(dl.target) && dl._srcIds.some(s => ns.has(s));
                }
                return hit ? "url(#arr)" : "none";
            });
    }

    function fetchGraph() {
        const url = "/api/graph?sector=" + encodeURIComponent(SECTOR);
        fetch(url)
            .then(r => r.json())
            .then(data => {
                allNodes = data.nodes || [];
                allLinks = (data.links || []).map(l => ({ ...l }));
                doFilter();
            })
            .catch(() => {
                document.getElementById("graph-container").innerHTML =
                    "<div style='padding:40px;text-align:center;color:#aaa'>无法加载图谱，请确保后端已启动。</div>";
            });
    }

    /* ================================================================
       过滤控件
    ================================================================ */
    function bindFilters() {
        document.querySelectorAll(".layer-check").forEach(cb => {
            cb.addEventListener("change", () => {
                F.layers[cb.value] = cb.checked;
                doFilter();
            });
        });
        document.getElementById("btn-refresh").addEventListener("click", fetchGraph);
    }

    /* ================================================================
       过滤
    ================================================================ */
    function layerVisible(n) {
        // 指标数据集节点不参与 ODS/DWD 前缀分层，默认随图层展示（与任一层可见表相连时由边筛选体现）
        if ((n.tableType || "") === "metrics_dataset") return true;
        // 按表名前缀分层，避免 tableType(core/dictionary/junction) 与筛选层不一致导致控件失效
        const name = tableBaseName(n.name || "");
        if (name.startsWith("ods_")) return F.layers.ods;
        if (name.startsWith("dwd_") || name.startsWith("dws_")) return F.layers.dwd;
        if (name.startsWith("dim_") || name.startsWith("dm_")) return F.layers.dm;
        if (name.startsWith("ads_")) return F.layers.ads;
        return true;
    }

    function doFilter() {
        const nIds = new Set();
        filteredNodes = allNodes.filter(n => { if (layerVisible(n)) { nIds.add(n.id); return true; } });

        filteredLinks = allLinks.filter(l => {
            if (!nIds.has(linkSrc(l))) return false;
            if (!nIds.has(linkDst(l))) return false;
            return true;
        });

        // 当前筛选下可见边对应的度数；与后端 relationCount 可能不一致（例如目标表所在层被关掉）
        const visDeg = {};
        filteredLinks.forEach(l => {
            const s = linkSrc(l), t = linkDst(l);
            visDeg[s] = (visDeg[s] || 0) + 1;
            visDeg[t] = (visDeg[t] || 0) + 1;
        });
        // 全图度数（不受层筛选影响，仅用于提示）
        const fullDeg = {};
        allLinks.forEach(l => {
            const s = linkSrc(l), t = linkDst(l);
            fullDeg[s] = (fullDeg[s] || 0) + 1;
            fullDeg[t] = (fullDeg[t] || 0) + 1;
        });
        // 保留所有通过层级筛选的已识别表节点（含无边孤立点，保证完整展示）
        degreeVisible = visDeg;
        degreeFull = fullDeg;

        // 切换筛选时清除历史选中高亮，避免误以为“控件失效”
        selId = null;
        const panel = document.getElementById("detail-panel");
        if (panel) panel.style.display = "none";

        render();
    }

    /* ================================================================
       D3 渲染
    ================================================================ */
    function render() {
        const gc = document.getElementById("graph-container");
        const W = gc && gc.clientWidth ? gc.clientWidth : window.innerWidth;
        const H = Math.max(220, (gc && gc.clientHeight ? gc.clientHeight : window.innerHeight - 56));
        const statsEl = document.getElementById("graph-stats");

        if (sim) sim.stop();
        layoutLocked = false;
        focusLinkOverlayG = null;

        d3.select("#graph-container").node().innerHTML = "";
        if (!filteredNodes.length) {
            d3.select("#graph-container").append("div")
                .style("padding", "40px").style("text-align", "center").style("color", "#aaa")
                .text("当前过滤条件下无数据，请调整筛选条件。");
            return;
        }

        const compInfo = computeUndirectedComponents(filteredNodes, filteredLinks);
        if (statsEl) {
            const blk = compInfo.k > 1 ? ` · ${compInfo.k} 个独立区块` : "";
            statsEl.textContent = `${filteredNodes.length} 节点 / ${filteredLinks.length} 条关系${blk}`;
        }

        // 克隆节点（避免污染原始数据），预先写入布局尺寸
        const nodes = filteredNodes.map(n => {
            const o = { ...n };
            setNodeLayoutSize(o);
            return o;
        });
        const nodeById = {};
        nodes.forEach(n => { nodeById[n.id] = n; });
        lastNodeById = nodeById;

        const links = filteredLinks.map((l, i) => ({ ...l, _ekey: "e" + i }));
        const displayLinks = buildDisplayLinks(links);

        /* 同层合并组的内聚弹簧：不渲染，仅参与力仿真，把同组源节点拉拢成簇 */
        const cohesionLinks = [];
        displayLinks.forEach(dl => {
            if (dl._mergedCount <= 1) return;
            const ids = dl._srcIds;
            for (let i = 0; i < ids.length; i++) {
                for (let j = i + 1; j < ids.length; j++) {
                    cohesionLinks.push({ source: ids[i], target: ids[j], _cohesion: true });
                }
            }
        });
        const allSimLinks = links.concat(cohesionLinks);

        const cx = W / 2, cy = (H - 28) / 2 + 14;
        const { idToCluster, k: clusterCount } = compInfo;
        const margin = clusterCount > 1
            ? Math.min(W, H) * 0.072 + 28
            : Math.min(W, H) * 0.06 + 40;
        const grid = multiClusterGrid(clusterCount, W, H, margin);
        const clusterCenters = grid.centers;
        const layerTopM = 52;
        const layerBotM = 40;
        const tierPitch = clusterCount > 1
            ? Math.min(Math.max(Math.min(grid.cellW, grid.cellH) * 0.25, 62), 124)
            : 0;
        nodes.forEach(d => {
            const ci = idToCluster.get(d.id) || 0;
            const c = clusterCenters[ci] || { x: cx, y: cy };
            d._cluster = ci;
            d._clusterCx = c.x;
            d._clusterCy = c.y;
            const tier = dataWarehouseTier(d);
            d._layerY = layerTargetY(tier, H, layerTopM, layerBotM);
            const jitterX = Math.min(grid.cellW, grid.cellH || 200) * (clusterCount > 1 ? 0.11 : 0.22);
            const innerH = Math.max(100, H - 2 * margin);
            const jitterY = clusterCount > 1
                ? Math.min(tierPitch * 0.5, 48)
                : Math.min(innerH / NUM_DW_TIERS, 90) * 0.35;
            d.x = d._clusterCx + (Math.random() - 0.5) * jitterX;
            if (clusterCount > 1) {
                /* 块内局部分层：以本块簇心为原点，ODS 在上、ADS 在下，避免多块共用全局 Y 带而视觉上缠在一起 */
                d._anchorY = d._clusterCy + (tier - 2) * tierPitch;
                d.y = d._anchorY + (Math.random() - 0.5) * jitterY;
            } else {
                d._anchorY = d._layerY;
                d.y = d._layerY + (Math.random() - 0.5) * jitterY;
            }
        });

        const COHESION_DIST = 58;
        const COHESION_STRENGTH = 0.35;

        function linkDistance(l) {
            if (l._cohesion) return COHESION_DIST;
            const s = typeof l.source === "object" ? l.source : nodeById[linkSrc(l)];
            const t = typeof l.target === "object" ? l.target : nodeById[linkDst(l)];
            const wa = (s && s.__w) || 160, wb = (t && t.__w) || 160;
            const cap = clusterCount > 1 ? 430 : 520;
            const base = Math.min(cap, clusterCount > 1 ? 118 + (wa + wb) * 0.155 : 118 + (wa + wb) * 0.16);
            const st = s && t ? Math.abs(dataWarehouseTier(s) - dataWarehouseTier(t)) : 0;
            return base + st * (clusterCount > 1 ? 26 : 28);
        }

        function linkStrength(l) {
            if (l._cohesion) return COHESION_STRENGTH;
            return clusterCount > 1 ? 0.46 : 0.32;
        }

        const nCount = nodes.length;
        let chargeMag = -Math.min(1100, 260 + Math.sqrt(Math.max(nCount, 1)) * 82);
        if (clusterCount > 1) chargeMag *= 0.92;
        const clusterXStrength = clusterCount > 1 ? 0.50 : 0.048;
        const layerYStrength = clusterCount > 1 ? 0 : 0.125;
        const anchorYStrength = clusterCount > 1 ? 0.36 : 0;

        svgEl = d3.select("#graph-container").append("svg").attr("width", "100%").attr("height", H);
        svgG   = svgEl.append("g");
        // 平移仅能从底层 zoom-bg 开始，避免在边/空白冒泡到 svg 后误触缩放层导致「拖住一直动」
        const zoomBeh = d3.zoom()
            .scaleExtent([0.02, 8])
            .filter((event) => {
                if (event.type === "wheel") return true;
                const t = event.target;
                if (!t || !t.closest) return false;
                if (event.type === "mousedown" || event.type === "touchstart")
                    return t.closest(".zoom-bg");
                if (event.type === "dblclick") return t.closest(".zoom-bg");
                return true;
            })
            .on("zoom", e => svgG.attr("transform", e.transform));
        svgEl.call(zoomBeh);

        function fitGraphToViewOnce() {
            let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
            nodes.forEach(d => {
                minX = Math.min(minX, d.x - d.__w / 2);
                maxX = Math.max(maxX, d.x + d.__w / 2);
                minY = Math.min(minY, d.y - d.__h / 2);
                maxY = Math.max(maxY, d.y + d.__h / 2);
            });
            if (grid.slotRects && grid.slotRects.length) {
                grid.slotRects.forEach(r => {
                    minX = Math.min(minX, r.x);
                    maxX = Math.max(maxX, r.x + r.w);
                    minY = Math.min(minY, r.y);
                    maxY = Math.max(maxY, r.y + r.h);
                });
            }
            const bw = Math.max(maxX - minX, 120);
            const bh = Math.max(maxY - minY, 100);
            const pad = clusterCount > 1 ? 72 : 52;
            const sc = Math.min(Math.max(Math.min((W - pad) / bw, (H - pad) / bh), 0.04), 2.4);
            const midx = (minX + maxX) / 2, midy = (minY + maxY) / 2;
            svgEl.call(zoomBeh.transform, d3.zoomIdentity.translate(W / 2, H / 2).scale(sc).translate(-midx, -midy));
        }

        // 透明背景：点击取消选中；带 .zoom-bg 供 d3.zoom 识别，仅从此层开始平移
        svgG.insert("rect", ":first-child")
            .attr("class", "zoom-bg")
            .attr("x", -W * 2).attr("y", -H * 2).attr("width", W * 5).attr("height", H * 5)
            .attr("fill", "transparent").style("cursor", "default")
            .on("click", () => {
                selId = null;
                clearAgentHighlight();
                resetHL();
                document.getElementById("detail-panel").style.display = "none";
            });

        if (grid.slotRects && grid.slotRects.length) {
            svgG.append("g")
                .attr("class", "cluster-slots")
                .selectAll("rect")
                .data(grid.slotRects)
                .join("rect")
                .attr("x", d => d.x)
                .attr("y", d => d.y)
                .attr("width", d => d.w)
                .attr("height", d => d.h)
                .attr("rx", 10)
                .attr("ry", 10)
                .attr("fill", "rgba(18, 24, 42, 0.45)")
                .attr("stroke", "rgba(100, 130, 200, 0.28)")
                .attr("stroke-width", 1)
                .attr("stroke-dasharray", "10,7")
                .style("pointer-events", "none");
        }

        // 多连通块：分区槽位 + 强锚定，避免无连通的块混成一团
        sim = d3.forceSimulation(nodes)
            .alpha(0.55)
            .alphaDecay(0.045)
            .alphaMin(0.001)
            .velocityDecay(0.74)
            .force("link", d3.forceLink(allSimLinks).id(d => d.id).distance(linkDistance).strength(linkStrength))
            .force("charge", d3.forceManyBody().strength(chargeMag).theta(0.85))
            .force("clusterX", d3.forceX(d => d._clusterCx).strength(clusterXStrength))
            .force("collide", d3.forceCollide().radius(d => nodeBubbleRadius(d)).strength(0.68).iterations(2));
        if (anchorYStrength > 0) {
            sim.force("anchorY", d3.forceY(d => d._anchorY).strength(anchorYStrength));
        } else {
            sim.force("layerY", d3.forceY(d => d._layerY).strength(layerYStrength));
        }

        const defs = svgEl.append("defs");
        function appendArrowMarker(id, fill) {
            defs.append("marker")
                .attr("id", id)
                .attr("viewBox", "0 -5 10 10")
                .attr("refX", 7)
                .attr("refY", 0)
                .attr("orient", "auto")
                .attr("markerWidth", 10)
                .attr("markerHeight", 10)
                .attr("markerUnits", "userSpaceOnUse")
                .append("path")
                .attr("d", "M 0,-4 L 10,0 L 0,4")
                .attr("fill", fill);
        }
        appendArrowMarker("arr", C.markerFill);
        appendArrowMarker("arr-up", C.markerUp);
        appendArrowMarker("arr-down", C.markerDown);
        appendArrowMarker("arr-cross", C.markerCross);

        function linkStrokeWidth(dl) {
            const mc = dl._mergedCount || 1;
            if (mc > 1) return Math.min(3.8, 1.6 + 0.45 * Math.log2(mc));
            const w = dl.weight || 1;
            return Math.min(2.4, 1 + 0.35 * Math.log2(w + 1));
        }

        function updateGraphGeometry() {
            if (linkSel) {
                linkSel.attr("d", l => linkBundledPathMerged(l, nodeById, displayLinks));
            }
            if (nodeSel) {
                nodeSel.attr("transform", d => `translate(${d.x},${d.y})`);
            }
        }

        function lockLayout() {
            nodes.forEach(d => {
                d.vx = 0;
                d.vy = 0;
                d.fx = d.x;
                d.fy = d.y;
            });
            layoutLocked = true;
            if (sim) sim.stop();
        }

        const dragBeh = d3.drag()
            .on("start", (e, d) => {
                /* 仅 mousedown 不算拖拽：避免「单击选节点」误触发力仿真，带动邻点漂移 */
                d.__dragRestarted = false;
                d.fx = d.x;
                d.fy = d.y;
            })
            .on("drag",  (e, d) => {
                if (!layoutLocked && !d.__dragRestarted) {
                    d.__dragRestarted = true;
                    if (!e.active) sim.alpha(0.32).restart();
                }
                d.fx = e.x;
                d.fy = e.y;
                if (layoutLocked) {
                    d.x = e.x;
                    d.y = e.y;
                    updateGraphGeometry();
                }
            })
            .on("end",   (e, d) => {
                d.x = d.fx != null ? d.fx : d.x;
                d.y = d.fy != null ? d.fy : d.y;
                d.fx = d.x;
                d.fy = d.y;
                if (!layoutLocked && !e.active) sim.alphaTarget(0);
                updateGraphGeometry();
            });

        nodeSel = svgG.append("g").attr("class", "nodes")
            .selectAll("g.node")
            .data(nodes, d => d.id)
            .join("g").attr("class", "node")
            .call(dragBeh)
            .on("click", (e, d) => {
                e.stopPropagation();
                clearAgentHighlight();
                selId = d.id;
                paintVisualState();
                showPanel(d, displayLinks);
            })
            .on("mouseover", (e, d) => showTip(e, d))
            .on("mouseout",  hideTip);

        nodeSel.append("ellipse")
            .attr("class", "node-shape")
            .attr("rx", d => d.__w / 2).attr("ry", 28)
            .attr("fill", d => nodeColor(d))
            .attr("stroke", C.strokeDefault).attr("stroke-width", 2);

        nodeSel.append("text").attr("text-anchor", "middle").attr("dy", -8)
            .attr("fill", "#fff").attr("font-size", "12px")
            .text(d => d.name || "");

        nodeSel.append("text").attr("text-anchor", "middle").attr("dy", 12)
            .attr("fill", "rgba(255,255,255,0.75)").attr("font-size", "10px")
            .text(d => assocLabel(d));

        /* 指标平台：表名与 DATASET vertexId 一致时仅标注、不连冗余边 */
        nodeSel.append("circle")
            .attr("class", "metric-dataset-same-badge")
            .attr("r", d => d.metricsSameAsDataset ? 8 : 0)
            .attr("cx", d => d.__w / 2 - 10)
            .attr("cy", -20)
            .attr("fill", d => d.metricsSameAsDataset ? C.metricsDataset : "none")
            .style("display", d => d.metricsSameAsDataset ? null : "none");

        /* 边与箭头画在节点之上，避免箭头被椭圆填充盖住；端点已内缩，线体尽量少压节点 */
        linkSel = svgG.append("g").attr("class", "links")
            .style("pointer-events", "none")
            .selectAll("path")
            .data(displayLinks, d => d._dkey)
            .join("path")
            .attr("class", l => `link ${l.relationType || "DATA_FLOW"}`)
            .attr("fill", "none")
            .attr("stroke-linecap", "round")
            .attr("stroke-linejoin", "round")
            .attr("stroke-width", linkStrokeWidth)
            .attr("marker-end", "url(#arr)");

        focusLinkOverlayG = svgG.append("g")
            .attr("class", "lineage-focus-overlay")
            .style("pointer-events", "none");

        // 勿将节点坐标夹死在视口内：宽表名节点多时会物理上无法同时塞进一屏，必重叠成「线团」。
        // 允许图在逻辑坐标系中铺开，用缩放/平移查看；首次稳定后自动缩放到全景。
        let autoFitDone = false;
        /* 不在 end 里改节点坐标：原先的密度重定位会在「看似已稳定」后再瞬移节点，破坏槽位边界与观感 */
        sim.on("end", () => {
            lockLayout();
            if (!autoFitDone) {
                autoFitDone = true;
                fitGraphToViewOnce();
            }
            updateGraphGeometry();
        });

        sim.on("tick", () => {
            updateGraphGeometry();
        });

        lastDisplayLinks = displayLinks;
        lastLogicalLinks = links;
        if (selId) {
            const s = nodes.find(n => n.id === selId);
            if (!s) selId = null;
        }
        paintVisualState();
    }

    /** 非血缘节点：统一灰化用色 */
    const DIM_NODE_FILL = "#4a4d55";
    const DIM_NODE_STROKE = "#35383f";
    const DIM_TEXT_MAIN = "#8a8d98";
    const DIM_TEXT_SUB = "#6a6d78";

    /* ================================================================
       选中高亮：仅「直接上一层 / 直接下一层」（1 跳入边 + 1 跳出边），不展开全量上下游
    ================================================================ */
    /** @returns {{ directParents: Set, directChildren: Set, focusSet: Set }} */
    /** 用逻辑边（未合并）算 1 跳，避免合并展示边漏算或 id 与 _srcIds 不一致 */
    function computeDirectNeighborhood(centerId, rawLinks) {
        const directParents = new Set();
        const directChildren = new Set();
        const cid = String(centerId);
        (rawLinks || []).forEach(l => {
            if (l._cohesion) return;
            const s = linkSrc(l);
            const t = linkDst(l);
            if (String(t) === cid) directParents.add(s);
            if (String(s) === cid) directChildren.add(t);
        });
        const focusSet = new Set([centerId, ...directParents, ...directChildren]);
        return { directParents, directChildren, focusSet };
    }

    function linkHashSeed(key) {
        let h = 0;
        const s = String(key || "");
        for (let i = 0; i < s.length; i++) h += s.charCodeAt(i);
        return h;
    }

    function displayLinkKeyForRaw(sourceId, targetId) {
        return `dl:${targetId}:${tableDataLayer(sourceId)}`;
    }

    function clearLineageFocusOverlay() {
        if (focusLinkOverlayG) focusLinkOverlayG.selectAll("path").remove();
    }

    /** 在合并边之上仅绘制“当前源节点自己那一条支线”，避免整组同层来源全部亮起 */
    function updateLineageFocusOverlay(centerId) {
        if (!focusLinkOverlayG || !centerId) {
            clearLineageFocusOverlay();
            return;
        }
        const raw = lastLogicalLinks || [];
        const nodeById = lastNodeById;
        const displayLinks = lastDisplayLinks || [];
        const displayLinkByKey = new Map(displayLinks.map(dl => [dl._dkey, dl]));
        const cid = String(centerId);
        const pairs = [];
        const seen = new Set();
        raw.forEach(l => {
            if (l._cohesion) return;
            const s = linkSrc(l);
            const t = linkDst(l);
            const ss = String(s);
            const tt = String(t);
            if (ss === cid) {
                const mergedDl = displayLinkByKey.get(displayLinkKeyForRaw(s, t));
                if (!mergedDl || (mergedDl._mergedCount || 1) <= 1) return;
                const k = ss + "\x1e" + tt;
                if (!seen.has(k)) {
                    seen.add(k);
                    pairs.push({
                        s,
                        t,
                        dir: "from-center",
                        relationType: l.relationType || "DATA_FLOW",
                    });
                }
            }
        });

        focusLinkOverlayG.selectAll("path")
            .data(pairs, d => String(d.s) + "\x1e" + String(d.t))
            .join(
                enter => enter.append("path")
                    .attr("class", d => `lineage-focus-path lineage-focus-${d.dir} link ${d.relationType || "DATA_FLOW"}`)
                    .attr("fill", "none")
                    .attr("stroke-linecap", "round"),
                update => update
                    .attr("class", d => `lineage-focus-path lineage-focus-${d.dir} link ${d.relationType || "DATA_FLOW"}`),
                exit => exit.remove()
            )
            .attr("d", d => {
                const sNode = nodeById[d.s];
                const tNode = nodeById[d.t];
                if (!sNode || !tNode || sNode.x == null || tNode.x == null) return "";
                const selfDl = {
                    _mergedCount: 1,
                    _srcIds: [d.s],
                    _dkey: `fo:${d.s}:${d.t}`,
                    relationType: d.relationType || "DATA_FLOW",
                };
                return singleEdgePath(
                    sNode,
                    tNode,
                    linkHashSeed(selfDl._dkey),
                    displayLinks,
                    selfDl,
                    nodeById
                );
            })
            .attr("marker-end", d => (d.dir === "to-center" ? "url(#arr-up)" : "url(#arr-down)"));
    }

    /** 节点：当前 / 直接来源 / 直接去向 / 双向直连（少见）/ 无关 */
    function nodeFocusRole(id, centerId, directParents, directChildren) {
        if (id === centerId) return "center";
        const p = directParents.has(id), c = directChildren.has(id);
        if (p && c) return "both";
        if (p) return "upstream";
        if (c) return "downstream";
        return "dim";
    }

    /** displayLink 版：若当前节点是合并边目标则亮整条聚合边；若只是合并组中的某个源，则不亮整束 */
    function displayLinkEdgeKind(dl, centerId) {
        const cid = String(centerId);
        if ((dl._mergedCount || 1) > 1) {
            if (String(dl.target) === cid) return "to-center";
            return "dim";
        }
        if (String(dl.target) === cid) return "to-center";
        if (dl._srcIds.some(id => String(id) === cid)) return "from-center";
        return "dim";
    }

    function refreshLinkPaths() {
        if (!linkSel) return;
        linkSel.attr("d", dl => linkBundledPathMerged(dl, lastNodeById, lastDisplayLinks));
    }

    /** 暗淡边若仍挂 marker，箭头不会继承 stroke-opacity — dim 必须去掉箭头 */
    function lineageMarkerForKind(kind) {
        if (kind === "dim") return "none";
        if (kind === "to-center") return "url(#arr-up)";
        if (kind === "from-center") return "url(#arr-down)";
        return "url(#arr-cross)";
    }

    function nodeFillLineage(d, role) {
        if (role === "dim") return DIM_NODE_FILL;
        const base = nodeColor(d);
        try {
            const c = d3.rgb(base);
            if (role === "center") return base;
            if (role === "upstream") return c.brighter(0.45).formatHex();
            if (role === "downstream") return c.brighter(0.3).formatHex();
            if (role === "both") return c.brighter(0.38).formatHex();
        } catch (e) { /* ignore */ }
        return base;
    }

    function nodeStrokeLineage(d, role) {
        if (role === "dim") return DIM_NODE_STROKE;
        if (role === "center") return C.selected;
        if (role === "upstream") return C.nodeStrokeUp;
        if (role === "downstream") return C.nodeStrokeDown;
        return C.nodeStrokeBoth;
    }

    function nodeStrokeWidthLineage(role) {
        if (role === "dim") return 2;
        if (role === "center") return 3.5;
        if (role === "both") return 3;
        return 2.75;
    }

    /* ================================================================
       选中高亮：只强调「直接连到当前表」的边；邻接节点上色，其余变淡
    ================================================================ */
    function applyHL() {
        if (!nodeSel || !linkSel) return;
        if (!selId) { resetHL(); return; }
        const raw = lastLogicalLinks || [];
        const { directParents, directChildren, focusSet } = computeDirectNeighborhood(selId, raw);
        refreshLinkPaths();

        nodeSel.each(function (d) {
            const role = nodeFocusRole(d.id, selId, directParents, directChildren);
            const g = d3.select(this);
            g.select(".node-shape")
                .attr("fill", nodeFillLineage(d, role))
                .attr("stroke", nodeStrokeLineage(d, role))
                .attr("stroke-width", nodeStrokeWidthLineage(role))
                .attr("opacity", focusSet.has(d.id) ? 1 : 0.72);
            g.selectAll("text")
                .attr("fill", (_t, i) => {
                    if (!focusSet.has(d.id)) return i === 0 ? DIM_TEXT_MAIN : DIM_TEXT_SUB;
                    return i === 0 ? "#fff" : "rgba(255,255,255,0.85)";
                });
        });

        linkSel
            .attr("class", dl => {
                const kind = displayLinkEdgeKind(dl, selId);
                const active = kind !== "dim";
                const base = `link ${dl.relationType || "DATA_FLOW"}`;
                if (!active) return `${base} lineage-edge-dim`;
                return `${base} lineage-edge-active lineage-${kind}`;
            })
            .attr("marker-end", dl => lineageMarkerForKind(displayLinkEdgeKind(dl, selId)))
            .style("stroke-opacity", null);
        updateLineageFocusOverlay(selId);
    }

    function resetHL() {
        clearLineageFocusOverlay();
        if (!nodeSel || !linkSel) return;
        refreshLinkPaths();
        nodeSel.select(".node-shape")
            .attr("fill", d => nodeColor(d))
            .attr("stroke", C.strokeDefault)
            .attr("stroke-width", 2)
            .attr("opacity", 1);
        nodeSel.selectAll("text")
            .attr("fill", (d, i) => i === 0 ? "#fff" : "rgba(255,255,255,0.75)");
        linkSel
            .attr("class", dl => `link ${dl.relationType || "DATA_FLOW"}`)
            .attr("marker-end", "url(#arr)")
            .style("stroke-opacity", null);
    }

    /* ================================================================
       详情面板
    ================================================================ */
    function showPanel(d, links) {
        const panel = document.getElementById("detail-panel");
        const content = document.getElementById("panel-content");
        const { directParents, directChildren } = computeDirectNeighborhood(d.id, lastLogicalLinks || []);
        const nIn = directParents.size;
        const nOut = directChildren.size;
        let nBoth = 0;
        directParents.forEach(id => {
            if (directChildren.has(id)) nBoth++;
        });

        const rels = links.filter(dl => dl.target === d.id || dl._srcIds.includes(d.id));
        const fullC = degreeFull[d.id] != null ? degreeFull[d.id] : (d.relationCount || 0);
        const hiddenNote = fullC > rels.length
            ? `（全图 ${fullC} 条，其余因层级筛选未显示）`
            : "";
        const cycleNote = nBoth
            ? ` 其中 <strong>${nBoth}</strong> 张表与当前表同时存在入边与出边。`
            : "";
        const metricsSameNote = d.metricsSameAsDataset
            ? `<p><strong>指标平台</strong> 数据源表与目标数据集名称一致（<code>${escapeHtml(
                d.metricsDatasetVertexId || d.name || "")}</code>），已在本节点标注，未增加冗余数据集边。</p>`
            : "";
        const items = rels.map(dl => {
            const tags = [];
            if (dl._mergedCount > 1) tags.push(`${dl._layer} ${dl._mergedCount}表合并`);
            if (dl.weight > 1) tags.push(`出现${dl.weight}次`);
            const tagStr = tags.length ? " (" + tags.join(", ") + ")" : "";
            if (dl.target === d.id) {
                return `← ${dl._srcIds.join(", ")}${tagStr}`;
            }
            return `→ ${dl.target}${tagStr}`;
        });
        const dn = (d.displayName != null && String(d.displayName).trim()) || "";
        const chineseTableName =
            dn && dn !== d.name
                ? dn
                : ((d.comment != null && String(d.comment).trim()) || "暂无");
        content.innerHTML = `
            <p><strong>表名</strong> ${d.name}</p>
            <p><strong>中文表名</strong> ${chineseTableName}</p>
            <p><strong>层级</strong> ${d.tableType || "core"}</p>
            <p><strong>注释</strong> ${d.comment || "无"}</p>
            ${metricsSameNote}
            <p><strong>选中高亮</strong> 仅 <strong>直接来源</strong> <strong>${nIn}</strong> 张 · <strong>直接去向</strong> <strong>${nOut}</strong> 张；画布中高亮与此表<strong>直接相连</strong>的 <strong>${rels.length}</strong> 条可见边（不含多跳间接）${cycleNote}</p>
            <p><strong>当前可见关联</strong> ${rels.length} 条${hiddenNote}</p>
            ${d.filePath ? `<p><strong>文件</strong> ${d.filePath}</p>` : ""}
            <p><strong>关联表</strong></p>
            <ul>${items.length ? items.map(x => `<li>${x}</li>`).join("") : "<li>无</li>"}</ul>
        `;
        panel.style.display = "flex";
    }

    /* ================================================================
       Tooltip
    ================================================================ */
    function showTip(e, d) {
        const tip = document.getElementById("tooltip");
        const same = d.metricsSameAsDataset
            ? "<br><span style='color:#e1bee7'>指标：表名与数据集一致</span>"
            : "";
        tip.innerHTML = `<strong>${d.name}</strong><br>${assocLabel(d)}${same}`;
        tip.style.display = "block";
        tip.style.left = (e.pageX + 12) + "px";
        tip.style.top  = (e.pageY + 12) + "px";
    }
    function hideTip() {
        document.getElementById("tooltip").style.display = "none";
    }

    /* ================================================================
       搜索（叠加血缘）
    ================================================================ */
    document.getElementById("search-input").addEventListener("input", function () {
        if ((this.value || "").trim()) clearAgentHighlight();
        paintVisualState();
    });

    document.getElementById("panel-close").addEventListener("click", () => {
        document.getElementById("detail-panel").style.display = "none";
        selId = null;
        paintVisualState();
    });

    function nodeColor(n) {
        const nm = (n.name || "").toLowerCase();
        if (nm.startsWith("v_") || (n.tableType || "") === "view") return C.view;
        const t = n.tableType || "core";
        if (t === "metrics_dataset") return C.metricsDataset;
        if (t === "dictionary") return C.dictionary;
        if (t === "junction")   return C.junction;
        if (t === "temp")       return C.temp;
        return C.core;
    }

    init();
})();
