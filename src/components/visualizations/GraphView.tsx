import { useEffect, useMemo, useRef } from "react";
import { Box, Typography } from "@mui/material";
import { extractGraph, type GraphData, type GraphNodeData } from "../../lib/memgraph";

interface SimNode extends GraphNodeData {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
}

export default function GraphView({ records }: { records: Record<string, unknown>[] }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<{ id: string; dx: number; dy: number } | null>(null);

  const graph: GraphData = useMemo(() => extractGraph(records.slice(0, 400)), [records]);

  useEffect(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const width = container.clientWidth;
    const height = container.clientHeight;
    const dpr = window.devicePixelRatio || 1;
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    ctx.scale(dpr, dpr);

    const nodes: SimNode[] = graph.nodes.map((n, i) => {
      const angle = (i / Math.max(graph.nodes.length, 1)) * Math.PI * 2;
      return {
        ...n,
        x: width / 2 + Math.cos(angle) * Math.min(width, height) * 0.3,
        y: height / 2 + Math.sin(angle) * Math.min(width, height) * 0.3,
        vx: 0,
        vy: 0,
        radius: 14 + Math.min(10, Object.keys(n.properties).length * 2),
      };
    });
    const rels = graph.relationships;
    const nodeById = new Map(nodes.map((n) => [n.id, n]));

    let raf = 0;
    const tick = () => {
      const alpha = 0.08;
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const a = nodes[i];
          const b = nodes[j];
          let dx = b.x - a.x;
          let dy = b.y - a.y;
          let dist = Math.hypot(dx, dy) || 1;
          const force = (90 * 90) / (dist * dist);
          const fx = (dx / dist) * force * alpha;
          const fy = (dy / dist) * force * alpha;
          a.vx -= fx;
          a.vy -= fy;
          b.vx += fx;
          b.vy += fy;
        }
      }
      for (const r of rels) {
        const a = nodeById.get(r.source);
        const b = nodeById.get(r.target);
        if (!a || !b) continue;
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const dist = Math.hypot(dx, dy) || 1;
        const force = (dist - 120) * 0.02 * alpha;
        const fx = (dx / dist) * force;
        const fy = (dy / dist) * force;
        a.vx += fx;
        a.vy += fy;
        b.vx -= fx;
        b.vy -= fy;
      }
      for (const n of nodes) {
        if (dragRef.current?.id === n.id) {
          n.vx = 0;
          n.vy = 0;
          continue;
        }
        n.vx *= 0.85;
        n.vy *= 0.85;
        n.x = Math.max(n.radius, Math.min(width - n.radius, n.x + n.vx));
        n.y = Math.max(n.radius, Math.min(height - n.radius, n.y + n.vy));
      }

      ctx.clearRect(0, 0, width, height);
      ctx.lineWidth = 1.5;
      for (const r of rels) {
        const a = nodeById.get(r.source);
        const b = nodeById.get(r.target);
        if (!a || !b) continue;
        ctx.strokeStyle = "rgba(255,255,255,0.35)";
        ctx.beginPath();
        ctx.moveTo(a.x, a.y);
        ctx.lineTo(b.x, b.y);
        ctx.stroke();
        const mx = (a.x + b.x) / 2;
        const my = (a.y + b.y) / 2;
        ctx.fillStyle = "rgba(255,255,255,0.55)";
        ctx.font = "10px sans-serif";
        ctx.textAlign = "center";
        ctx.fillText(r.type, mx, my - 2);
      }
      for (const n of nodes) {
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.radius, 0, Math.PI * 2);
        ctx.fillStyle = n.color;
        ctx.fill();
        ctx.strokeStyle = "rgba(255,255,255,0.5)";
        ctx.lineWidth = 1;
        ctx.stroke();
        ctx.fillStyle = "#e8eaf0";
        ctx.font = "11px sans-serif";
        ctx.textAlign = "center";
        ctx.fillText(n.caption, n.x, n.y + n.radius + 12);
      }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);

    const toLocal = (e: MouseEvent) => {
      const rect = canvas.getBoundingClientRect();
      return { x: e.clientX - rect.left, y: e.clientY - rect.top };
    };
    const onDown = (e: MouseEvent) => {
      const p = toLocal(e);
      const hit = nodes.find((n) => Math.hypot(n.x - p.x, n.y - p.y) <= n.radius + 4);
      if (hit) dragRef.current = { id: hit.id, dx: hit.x - p.x, dy: hit.y - p.y };
    };
    const onMove = (e: MouseEvent) => {
      if (!dragRef.current) return;
      const p = toLocal(e);
      const n = nodeById.get(dragRef.current.id);
      if (n) {
        n.x = p.x + dragRef.current.dx;
        n.y = p.y + dragRef.current.dy;
      }
    };
    const onUp = () => {
      dragRef.current = null;
    };
    canvas.addEventListener("mousedown", onDown);
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);

    return () => {
      cancelAnimationFrame(raf);
      canvas.removeEventListener("mousedown", onDown);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [graph]);

  if (graph.nodes.length === 0) {
    return (
      <Box sx={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Typography color="text.secondary">
          {"No graph data — return nodes/relationships, e.g. MATCH (n)-[r]->(m) RETURN n, r, m"}
        </Typography>
      </Box>
    );
  }

  return (
    <Box ref={containerRef} sx={{ width: "100%", height: "100%" }}>
      <canvas ref={canvasRef} style={{ cursor: "grab" }} />
    </Box>
  );
}
