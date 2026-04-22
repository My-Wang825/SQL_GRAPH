"""Windows-friendly startup script for this project.

Usage:
    python run_server.py
    python run_server.py --reload
    python run_server.py --port 8080
"""
# 先解析 --host / --port / --reload，用 pick_port 检测端口是否可用并可能自动换端口，打印访问提示，
# 然后在脚本末尾调用 uvicorn.run(...) 真正启动 Web 服务。

from __future__ import annotations

import argparse
import socket
from typing import Optional

import uvicorn


def is_port_available(host: str, port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind((host, port))
            return True
        except OSError:
            return False


def pick_port(host: str, preferred: int) -> int:
    candidates = [preferred, 8080, 18000, 28000]
    for p in candidates:
        if is_port_available(host, p):
            return p
    # last fallback: ask OS for random free port
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((host, 0))
        return int(s.getsockname()[1])


def preferred_lan_ipv4() -> Optional[str]:
    """本机访问外网时选用的 IPv4，通常即以太网/Wi‑Fi 的局域网地址（不建立真实流量）。"""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        return str(ip) if ip and not ip.startswith("127.") else None
    except OSError:
        return None
    finally:
        s.close()


def print_access_hints(host: str, port: int) -> None:
    print(f"[本机浏览器] http://127.0.0.1:{port}/  （勿在地址栏使用 0.0.0.0）")
    print(
        f"[自检] http://127.0.0.1:{port}/health  应显示 "
        '{"status":"ok"} ；端口必须与上方一致，且勿关闭本终端（关窗即停服）'
    )
    if host == "0.0.0.0":
        lan = preferred_lan_ipv4()
        if lan:
            print(f"[同网段其他电脑] http://{lan}:{port}/")
        print(
            f"[防火墙] 若局域网仍打不开：管理员 PowerShell 放行 TCP {port}（三档配置文件都开）：\n"
            f'  New-NetFirewallRule -DisplayName "SQL-graph {port}" '
            f"-Direction Inbound -LocalPort {port} -Protocol TCP -Action Allow "
            f"-Profile Domain,Private,Public"
        )
    else:
        print(
            "[重要] 当前仅绑定 127.0.0.1：用 http://192.168.x.x 访问一定失败（与防火墙无关）。\n"
            f"       需要局域网访问时请停掉本进程后执行："
            f" python run_server.py --host 0.0.0.0 --port {port}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Run SQL graph service")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", default=8000, type=int, help="Preferred port (default: 8000)")
    parser.add_argument("--reload", action="store_true", help="Enable auto-reload")
    args = parser.parse_args()

    port = pick_port(args.host, args.port)
    if port != args.port:
        print(f"[提示] 端口 {args.port} 不可用，自动切换到 {port}")
    print(f"[监听] {args.host}:{port}")
    print_access_hints(args.host, port)
    uvicorn.run("backend.main:app", host=args.host, port=port, reload=args.reload)


if __name__ == "__main__":
    main()
