#!/usr/bin/env python3
"""Architect Engine fixed-name JSON to SVG/PNG renderer.

Run from repository root:
  python architect_engine_renderer.py architect_engine_first_plan.json

Install:
  pip install svgwrite cairosvg

Draft renderer only; not building-code or construction certification.
"""
import json, sys
from pathlib import Path
import svgwrite

def load_plan(path):
    p=json.loads(path.read_text(encoding="utf-8"))
    W,D=p["plot"]["width"],p["plot"]["depth"]
    if W<=0 or D<=0: raise ValueError("Plot dimensions must be positive.")
    ids=set()
    for wall in p["walls"]:
        if wall["id"] in ids: raise ValueError("Duplicate wall id: "+wall["id"])
        ids.add(wall["id"])
        x1,y1,x2,y2=wall["rect"]
        if not (0<=x1<x2<=W and 0<=y1<y2<=D): raise ValueError("Invalid wall bounds: "+wall["id"])
    for room in p["rooms"]:
        x1,y1,x2,y2=room["clear_bounds"]
        if not (0<=x1<x2<=W and 0<=y1<y2<=D): raise ValueError("Invalid room bounds: "+room["id"])
        dims=room.get("expected_dimensions",{})
        if dims and (dims.get("width")!=x2-x1 or dims.get("depth")!=y2-y1):
            raise ValueError("Room dimension mismatch: "+room["id"])
    return p

def render(p):
    W,D=p["plot"]["width"],p["plot"]["depth"]
    cfg=p.get("render",{}); project=p.get("project",{})
    pad=int(cfg.get("padding_mm",1000)); header=650; footer=450; side=700
    vw=W+2*pad+side; vh=D+2*pad+header+footer
    scale=float(cfg.get("pixels_per_meter",130))/1000
    ox=pad+250; oy=pad+header
    bg=cfg.get("background_color","#fffdf7"); wallc=cfg.get("wall_color","#111827")
    furnc=cfg.get("furniture_color","#dce9f5"); accent=cfg.get("accent_color","#c99b2e")
    sx=lambda x:ox+x
    sy=lambda y:oy+D-y
    dwg=svgwrite.Drawing("architect_engine_first_plan.svg",
        size=(f"{vw*scale}px",f"{vh*scale}px"),viewBox=f"0 0 {vw} {vh}",profile="full")
    dwg.add(dwg.rect(insert=(0,0),size=(vw,vh),fill=bg))
    dwg.add(dwg.text(f'{project.get("plot_label","FLOOR PLAN")} — {project.get("bhk",1)}BHK FLOOR PLAN',
        insert=(vw/2,190),text_anchor="middle",font_family="Arial",font_size=180,font_weight="bold",fill="#111827"))
    dwg.add(dwg.text(f'{project.get("facing","")} FACING • {W} × {D} mm • CONCEPT DRAFT',
        insert=(vw/2,395),text_anchor="middle",font_family="Arial",font_size=90,fill="#374151"))
    dwg.add(dwg.rect(insert=(sx(0),sy(D)),size=(W,D),fill="none",stroke="#6b7280",stroke_width=18))
    walls={w["id"]:w for w in p["walls"]}
    for w in p["walls"]:
        x1,y1,x2,y2=w["rect"]
        dwg.add(dwg.rect(insert=(sx(x1),sy(y2)),size=(x2-x1,y2-y1),fill=wallc,stroke=wallc,stroke_width=2))
    # Door openings: mask the wall segment so doors are shown as actual visual gaps.
    # This is a 2D visual opening, not a production CAD solid model.
    for door in p.get("openings",{}).get("doors",[]):
        wall=walls.get(door.get("wall_id"))
        if not wall: raise ValueError("Door references unknown wall: "+str(door.get("id")))
        x1,y1,x2,y2=wall["rect"]
        a,b=door.get("opening_interval",[0,0])
        if not (a < b): raise ValueError("Invalid door opening interval: "+str(door.get("id")))
        if x2-x1 <= y2-y1:
            cx=(x1+x2)/2
            dwg.add(dwg.line(start=(sx(cx),sy(a)),end=(sx(cx),sy(b)),stroke=bg,stroke_width=(x2-x1)+55))
        else:
            cy=(y1+y2)/2
            dwg.add(dwg.line(start=(sx(a),sy(cy)),end=(sx(b),sy(cy)),stroke=bg,stroke_width=(y2-y1)+55))
    # Window symbols are visual masks; production geometry must split wall solids.
    for win in p.get("openings",{}).get("windows",[]):
        wall=walls[win["wall_id"]]; x1,y1,x2,y2=wall["rect"]; a,b=win["absolute_interval"]
        if x2-x1 <= y2-y1:
            cx=(x1+x2)/2
            dwg.add(dwg.line(start=(sx(cx),sy(a)),end=(sx(cx),sy(b)),stroke=bg,stroke_width=(x2-x1)+45))
            for off in (-45,45): dwg.add(dwg.line(start=(sx(cx+off),sy(a)),end=(sx(cx+off),sy(b)),stroke="#64748b",stroke_width=14))
        else:
            cy=(y1+y2)/2
            dwg.add(dwg.line(start=(sx(a),sy(cy)),end=(sx(b),sy(cy)),stroke=bg,stroke_width=(y2-y1)+45))
            for off in (-45,45): dwg.add(dwg.line(start=(sx(a),sy(cy+off)),end=(sx(b),sy(cy+off)),stroke="#64748b",stroke_width=14))
    for room in p["rooms"]:
        x1,y1,x2,y2=room["clear_bounds"]; cx,cy=room.get("text_xy",[(x1+x2)/2,(y1+y2)/2])
        dwg.add(dwg.rect(insert=(sx(x1),sy(y2)),size=(x2-x1,y2-y1),fill="none",stroke="#c4c7cc",stroke_width=8,stroke_dasharray="55,45"))
        label=room.get("label",room["id"]); dims=room.get("expected_dimensions",{})
        dwg.add(dwg.text(label,insert=(sx(cx),sy(cy)-20),text_anchor="middle",font_family="Arial",font_size=92,font_weight="bold",fill="#111827"))
        dwg.add(dwg.text(f'{dims.get("width",x2-x1)} × {dims.get("depth",y2-y1)} mm',
            insert=(sx(cx),sy(cy)+105),text_anchor="middle",font_family="Arial",font_size=68,fill="#374151"))
    for item in p.get("furniture",[]):
        typ=item.get("type","").upper()
        if "bounds" in item:
            x1,y1,x2,y2=item["bounds"]
            dwg.add(dwg.rect(insert=(sx(x1),sy(y2)),size=(x2-x1,y2-y1),rx=30,ry=30,fill=furnc,stroke="#334155",stroke_width=15))
            if typ=="BED":
                dwg.add(dwg.line(start=(sx(x1+60),sy(y2-220)),end=(sx(x2-60),sy(y2-220)),stroke="#64748b",stroke_width=12))
                dwg.add(dwg.rect(insert=(sx(x1+55),sy(y2-205)),size=(min(260,x2-x1-110),140),fill="#fff",stroke="#64748b",stroke_width=8))
            elif typ=="SOFA":
                dwg.add(dwg.line(start=(sx(x1+60),sy(y2-80)),end=(sx(x2-60),sy(y2-80)),stroke="#64748b",stroke_width=12))
            elif typ=="WC":
                r=min(x2-x1,y2-y1)*0.28
                dwg.add(dwg.ellipse(center=(sx((x1+x2)/2),sy((y1+y2)/2)),r=(r,r),fill="#fff",stroke="#334155",stroke_width=12))
            elif typ=="BASIN":
                dwg.add(dwg.ellipse(center=(sx((x1+x2)/2),sy((y1+y2)/2)),r=((x2-x1)*0.35,(y2-y1)*0.35),fill="#fff",stroke="#334155",stroke_width=10))
            elif typ=="WARDROBE":
                dwg.add(dwg.line(start=(sx((x1+x2)/2),sy(y1)),end=(sx((x1+x2)/2),sy(y2)),stroke="#64748b",stroke_width=10))
            elif typ=="DINING_TABLE":
                dwg.add(dwg.text("TABLE",insert=(sx((x1+x2)/2),sy((y1+y2)/2)),text_anchor="middle",font_size=70,fill="#334155"))
        elif "polygon" in item:
            pts=[(sx(x),sy(y)) for x,y in item["polygon"]]
            dwg.add(dwg.polygon(points=pts,fill=furnc,stroke="#334155",stroke_width=15))
    # Door leaf and swing arcs over the masked wall openings.
    for door in p.get("openings",{}).get("doors",[]):
        hx,hy=door["hinge_xy"]; width=door["width"]; orient=door.get("orientation","horizontal")
        if orient=="horizontal": end=(sx(hx+width),sy(hy)); arcend=(sx(hx),sy(hy-width))
        else: end=(sx(hx),sy(hy+width)); arcend=(sx(hx+width),sy(hy))
        dwg.add(dwg.line(start=(sx(hx),sy(hy)),end=end,stroke="#111827",stroke_width=18))
        dwg.add(dwg.path(d=f'M {end[0]} {end[1]} A {width} {width} 0 0 1 {arcend[0]} {arcend[1]}',fill="none",stroke="#64748b",stroke_width=10))
    # overall dimensions
    dy=oy+D+250
    dwg.add(dwg.line(start=(sx(0),dy),end=(sx(W),dy),stroke="#374151",stroke_width=12))
    for x in (0,W): dwg.add(dwg.line(start=(sx(x),dy-70),end=(sx(x),dy+70),stroke="#374151",stroke_width=12))
    dwg.add(dwg.text(f'{W} mm ({W/304.8:.1f} ft)',insert=(sx(W/2),dy-30),text_anchor="middle",font_size=90,fill="#111827"))
    dx=ox-250; my=oy+D/2
    dwg.add(dwg.line(start=(dx,oy),end=(dx,oy+D),stroke="#374151",stroke_width=12))
    for y in (0,D): dwg.add(dwg.line(start=(dx-70,sy(y)),end=(dx+70,sy(y)),stroke="#374151",stroke_width=12))
    dwg.add(dwg.text(f'{D} mm ({D/304.8:.1f} ft)',insert=(dx-35,my),text_anchor="middle",font_size=90,fill="#111827",transform=f'rotate(-90 {dx-35} {my})'))
    nx,ny=ox+W+300,oy+650
    dwg.add(dwg.text("N",insert=(nx,ny-100),text_anchor="middle",font_size=130,font_weight="bold",fill="#111827"))
    dwg.add(dwg.polygon(points=[(nx,ny-70),(nx-60,ny+60),(nx,ny+30),(nx+60,ny+60)],fill=accent,stroke="#111827",stroke_width=8))
    dwg.add(dwg.text("CONCEPT ONLY • Verify room access, openings, setbacks and local rules.",
        insert=(vw/2,vh-190),text_anchor="middle",font_size=70,fill="#7f1d1d"))
    dwg.add(dwg.text(project.get("branding","Architect Engine"),insert=(vw/2,vh-60),text_anchor="middle",font_size=80,fill="#374151"))
    dwg.save()
    return Path("architect_engine_first_plan.svg"),Path("architect_engine_first_plan.png")

def main():
    src=Path(sys.argv[1] if len(sys.argv)>1 else "architect_engine_first_plan.json")
    if not src.is_file():
        print(f"JSON not found: {src.resolve()}"); return 2
    try: plan=load_plan(src)
    except Exception as exc:
        print(f"Plan validation error: {exc}"); return 1
    svg,png=render(plan)
    print(f"SVG created: {svg.resolve()}")
    try:
        import cairosvg
        cairosvg.svg2png(url=str(svg),write_to=str(png),output_width=1800)
        print(f"PNG created: {png.resolve()}")
    except ImportError:
        print("PNG skipped. Install CairoSVG: pip install cairosvg")
    print("Rendered as a concept draft; verify access, clearances and local code before use.")
    return 0
if __name__=="__main__": raise SystemExit(main())
